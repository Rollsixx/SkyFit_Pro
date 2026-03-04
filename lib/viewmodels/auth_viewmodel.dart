import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/export.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/key_storage_service.dart';
import '../services/session_service.dart';

class AuthViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final KeyStorageService _keys;
  final SessionService _session;
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _currentUser;
  bool _busy = false;
  String? _error;
  String? _otpForSimulation; // only for simulated registration OTP

  AuthViewModel(this._db, this._keys, this._session);

  UserModel? get currentUser => _currentUser;
  bool get isBusy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && !_session.isLocked;
  String? get otpForSimulation => _otpForSimulation;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // -------------------- Password Hashing (PBKDF2) --------------------

  List<int> _pbkdf2Hash({
    required String password,
    required List<int> salt,
    int iterations = 100000,
    int dkLen = 32,
  }) {
    final params = Pbkdf2Parameters(Uint8List.fromList(salt), iterations, dkLen);
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))..init(params);
    return derivator.process(Uint8List.fromList(password.codeUnits)).toList();
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  // -------------------- Register (with OTP simulation) --------------------

  String _generateOtp6() {
    final rnd = Random.secure();
    return (100000 + rnd.nextInt(900000)).toString();
  }

  Future<bool> beginRegistration({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final normalized = email.toLowerCase().trim();
      if (normalized.isEmpty || !normalized.contains('@')) {
        _error = 'Please enter a valid email.';
        return false;
      }
      if (password.length < 8) {
        _error = 'Password must be at least 8 characters.';
        return false;
      }
      final exists = await _db.userExists(normalized);
      if (exists) {
        _error = 'User already exists.';
        return false;
      }

      // OTP Simulation: show code in UI; user must type it to confirm.
      _otpForSimulation = _generateOtp6();
      _error = null;
      return true;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> confirmRegistrationOtpAndCreateUser({
    required String email,
    required String password,
    required String otpInput,
  }) async {
    _setBusy(true);
    try {
      if (_otpForSimulation == null) {
        _error = 'OTP simulation expired. Please try again.';
        return false;
      }
      if (otpInput.trim() != _otpForSimulation) {
        _error = 'Incorrect OTP (simulation).';
        return false;
      }

      final normalized = email.toLowerCase().trim();
      final rnd = Random.secure();
      final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
      final hash = _pbkdf2Hash(password: password, salt: salt);

      final user = UserModel(
        email: normalized,
        passwordHash: hash,
        salt: salt,
        biometricsEnabled: false,
        hasLoggedInOnce: false,
      );

      await _db.createUser(user);
      _otpForSimulation = null;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Registration failed.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // -------------------- Login --------------------

  Future<bool> loginWithPassword({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final normalized = email.toLowerCase().trim();
      final user = await _db.getUser(normalized);
      if (user == null) {
        _error = 'User not found.';
        return false;
      }

      final candidate = _pbkdf2Hash(password: password, salt: user.salt);
      if (!_constantTimeEquals(candidate, user.passwordHash)) {
        _error = 'Incorrect password.';
        return false;
      }

      // Mark first successful password login requirement for biometrics.
      if (!user.hasLoggedInOnce) {
        user.hasLoggedInOnce = true;
        await _db.updateUser(user);
      }

      _currentUser = user;
      await _keys.saveLastEmail(normalized);

      _session.unlockSession();
      _error = null;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Login failed.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> unlockWithBiometrics() async {
    _setBusy(true);
    try {
      final lastEmail = await _keys.readLastEmail();
      if (lastEmail == null) {
        _error = 'No previous login found. Please login with password first.';
        return false;
      }

      final user = await _db.getUser(lastEmail);
      if (user == null) {
        _error = 'User record missing.';
        return false;
      }

      if (!user.hasLoggedInOnce) {
        _error = 'Biometrics require at least one successful password login.';
        return false;
      }
      if (!user.biometricsEnabled) {
        _error = 'Biometric unlock is not enabled in your profile.';
        return false;
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        _error = 'Biometrics not available on this device.';
        return false;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock CipherTask',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!ok) {
        _error = 'Biometric authentication cancelled/failed.';
        return false;
      }

      _currentUser = user;
      _session.unlockSession();
      _error = null;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Biometric unlock failed.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;

    // Enforce rule: only after password login at least once
    if (!user.hasLoggedInOnce && enabled) {
      _error = 'Login with password at least once before enabling biometrics.';
      notifyListeners();
      return;
    }

    user.biometricsEnabled = enabled;
    await _db.updateUser(user);
    _currentUser = user;
    _error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _session.lockSession();
    _error = null;
    notifyListeners();
  }

  void onSessionTimedOut() {
    // Called by SessionService when timer hits.
    logout();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }
}
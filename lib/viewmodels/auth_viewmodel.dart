import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/export.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/email_otp_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/key_storage_service.dart';
import '../services/session_manager.dart';

class AuthViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final KeyStorageService _keys;
  final SessionManager _session;
  final EmailOtpService _otpSvc;
  final FirebaseAuthService _firebase;
  final FirestoreService _firestore = FirestoreService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _currentUser;
  bool _busy = false;
  String? _error;
  GoogleSignInResult? _pendingGoogle;

  bool _biometricsChecked = false;
  bool _biometricsAvailable = false;
  String? _biometricInfo;

  int _bioFailCount = 0;
  static const int _maxBioFails = 3;

  bool get biometricLocked => _bioFailCount >= _maxBioFails;

  AuthViewModel(
    this._db,
    this._keys,
    this._session,
    this._otpSvc,
    this._firebase,
  );

  UserModel? get currentUser => _currentUser;
  bool get isBusy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && !_session.isLocked;
  bool get biometricsChecked => _biometricsChecked;
  bool get biometricsAvailable => _biometricsAvailable;
  String? get biometricInfo => _biometricInfo;
  bool get pendingGoogleOtp => _pendingGoogle != null;
  String? get pendingGoogleEmail => _pendingGoogle?.email;
  int get bioFailCount => _bioFailCount;
  int get maxBioFails => _maxBioFails;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Biometrics availability check ──────────────────────────────────────────
  Future<void> checkBiometricsAvailability() async {
    if (kIsWeb) {
      _biometricsAvailable = false;
      _biometricsChecked = true;
      notifyListeners();
      return;
    }
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      _biometricsAvailable = supported && canCheck && available.isNotEmpty;
      _biometricInfo =
          'supported=$supported canCheck=$canCheck available=$available';
    } catch (e) {
      _biometricsAvailable = false;
      _biometricInfo = 'error=$e';
    } finally {
      _biometricsChecked = true;
      notifyListeners();
    }
  }

  Future<bool> lastUserHasBiometricsEnabled() async {
    if (kIsWeb) return false;
    try {
      final lastEmail = await _keys.readLastEmail();
      if (lastEmail == null) return false;
      final user = await _db.getUser(lastEmail);
      return user?.biometricsEnabled == true && user?.hasLoggedInOnce == true;
    } catch (_) {
      return false;
    }
  }

  // ── PBKDF2 ─────────────────────────────────────────────────────────────────
  List<int> _pbkdf2Hash({
    required String password,
    required List<int> salt,
    int iterations = 100000,
    int dkLen = 32,
  }) {
    final params =
        Pbkdf2Parameters(Uint8List.fromList(salt), iterations, dkLen);
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(params);
    return derivator.process(Uint8List.fromList(password.codeUnits)).toList();
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
    return diff == 0;
  }

  // ── Registration ───────────────────────────────────────────────────────────
  Future<bool> beginRegistration({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setBusy(true);
    try {
      final n = email.toLowerCase().trim();
      if (n.isEmpty || !n.contains('@')) {
        _error = 'Please enter a valid email.';
        return false;
      }
      if (password.length < 8) {
        _error = 'Password must be at least 8 characters.';
        return false;
      }
      if (password != confirmPassword) {
        _error = 'Passwords do not match.';
        return false;
      }

      final localExists = await _db.userExists(n);
      final firestoreExists = await _firestore.userExists(n);
      if (localExists || firestoreExists) {
        _error = 'User already exists.';
        return false;
      }

      await _otpSvc.generateAndSend(n);
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
    int? age,
    double? weight,
  }) async {
    _setBusy(true);
    try {
      final n = email.toLowerCase().trim();
      if (!_otpSvc.verify(n, otpInput)) {
        _error = 'Incorrect or expired OTP.';
        return false;
      }
      final rnd = Random.secure();
      final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
      final hash = _pbkdf2Hash(password: password, salt: salt);

      final user = UserModel(
        email: n,
        passwordHash: hash,
        salt: salt,
        hasLoggedInOnce: false,
        memberSince: DateTime.now(),
        age: age,
        weight: weight,
      );

      if (!kIsWeb) {
        await _db.createUser(user);
      }

      await _firestore.saveUser(user);

      try {
        await _firebase.registerWithEmail(
          email: n,
          password: password,
        );
      } catch (e) {
        // ignore: avoid_print
        print('[AuthViewModel] Firebase registration note: $e');
      }

      _error = null;
      return true;
    } catch (_) {
      _error = 'Registration failed.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Password Login ─────────────────────────────────────────────────────────
  Future<bool> loginWithPassword({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final n = email.toLowerCase().trim();

      // ── Web login — use Firebase Auth directly ─────────────────────────
      if (kIsWeb) {
        try {
          await _firebase.loginWithEmail(email: n, password: password);
        } catch (e) {
          _error = 'Incorrect email or password.';
          return false;
        }

        final firestoreData = await _firestore.getUser(n);
        UserModel user;
        if (firestoreData != null) {
          user = UserModel(
            email: n,
            passwordHash: [],
            salt: [],
            hasLoggedInOnce: true,
            displayName: firestoreData['displayName'] as String?,
            photoUrl: firestoreData['photoUrl'] as String?,
            isGoogleUser: firestoreData['isGoogleUser'] as bool? ?? false,
            memberSince: firestoreData['memberSince'] != null
                ? DateTime.tryParse(firestoreData['memberSince'])
                : null,
            age: firestoreData['age'] as int?,
            weight: (firestoreData['weight'] as num?)?.toDouble(),
            biometricsEnabled:
                firestoreData['biometricsEnabled'] as bool? ?? false,
          );
        } else {
          user = UserModel(
            email: n,
            passwordHash: [],
            salt: [],
            hasLoggedInOnce: true,
            memberSince: DateTime.now(),
          );
          await _firestore.saveUser(user);
        }

        _currentUser = user;
        _bioFailCount = 0;
        _session.unlockSession();
        _error = null;
        notifyListeners();
        return true;
      }

      // ── Mobile login — use local Hive + PBKDF2 ─────────────────────────
      UserModel? user = await _db.getUser(n);

      if (user == null) {
        final firestoreData = await _firestore.getUser(n);
        if (firestoreData == null) {
          _error = 'User not found.';
          return false;
        }
        try {
          await _firebase.loginWithEmail(email: n, password: password);
        } catch (e) {
          _error = 'Incorrect password.';
          return false;
        }
        user = UserModel(
          email: n,
          passwordHash: [],
          salt: [],
          hasLoggedInOnce: true,
          displayName: firestoreData['displayName'] as String?,
          photoUrl: firestoreData['photoUrl'] as String?,
          isGoogleUser: firestoreData['isGoogleUser'] as bool? ?? false,
          memberSince: firestoreData['memberSince'] != null
              ? DateTime.tryParse(firestoreData['memberSince'])
              : null,
          age: firestoreData['age'] as int?,
          weight: (firestoreData['weight'] as num?)?.toDouble(),
          biometricsEnabled:
              firestoreData['biometricsEnabled'] as bool? ?? false,
        );
        await _db.createUser(user);
      } else {
        if (!_constantTimeEquals(
            _pbkdf2Hash(password: password, salt: user.salt),
            user.passwordHash)) {
          _error = 'Incorrect password.';
          return false;
        }
      }

      try {
        await _firebase.loginWithEmail(email: n, password: password);
      } catch (e) {
        // ignore: avoid_print
        print('[AuthViewModel] Firebase login note: $e');
      }

      if (!user.hasLoggedInOnce) {
        user.hasLoggedInOnce = true;
        user.memberSince ??= DateTime.now();
        await _db.updateUser(user);
        await _firestore.saveUser(user);
      }

      _currentUser = user;
      _bioFailCount = 0;
      await _keys.saveLastEmail(n);
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

  // ── Google Login Step 1 ────────────────────────────────────────────────────
  Future<bool> beginGoogleLogin() async {
    _setBusy(true);
    try {
      final result = await _firebase.signInWithGoogle();
      if (result.cancelled) {
        _error = null;
        return false;
      }
      if (!result.success) {
        _error = result.errorMessage;
        return false;
      }
      _pendingGoogle = result;
      await _otpSvc.generateAndSend(result.email!.toLowerCase().trim());
      _error = null;
      notifyListeners();
      // ignore: avoid_print
      print('[AuthViewModel] Google auth OK for '
          '${result.email} — OTP sent');
      return true;
    } catch (e) {
      _error = 'Google login error: $e';
      _pendingGoogle = null;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Google OTP Step 2 ──────────────────────────────────────────────────────
  Future<bool> confirmGoogleOtp(String otpInput) async {
    _setBusy(true);
    try {
      final pending = _pendingGoogle;
      if (pending == null) {
        _error = 'Session expired. Try again.';
        return false;
      }
      final email = pending.email!.toLowerCase().trim();
      if (!_otpSvc.verify(email, otpInput)) {
        _error = 'Incorrect or expired OTP.';
        return false;
      }

      UserModel? user = kIsWeb ? null : await _db.getUser(email);
      if (user == null) {
        user = UserModel(
          email: email,
          passwordHash: [],
          salt: [],
          hasLoggedInOnce: true,
          displayName: pending.displayName,
          photoUrl: pending.photoUrl,
          isGoogleUser: true,
          memberSince: DateTime.now(),
        );
        if (!kIsWeb) await _db.createUser(user);
        await _firestore.saveUser(user);
      } else {
        user.displayName = pending.displayName ?? user.displayName;
        user.photoUrl = pending.photoUrl ?? user.photoUrl;
        user.isGoogleUser = true;
        user.memberSince ??= DateTime.now();
        if (!kIsWeb) await _db.updateUser(user);
        await _firestore.saveUser(user);
      }

      _pendingGoogle = null;
      _currentUser = user;
      _bioFailCount = 0;
      if (!kIsWeb) await _keys.saveLastEmail(email);
      _session.unlockSession();
      _error = null;
      notifyListeners();
      // ignore: avoid_print
      print('[AuthViewModel] Google login COMPLETE for $email');
      return true;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void cancelGoogleOtp() {
    _otpSvc.discard(_pendingGoogle?.email ?? '');
    _pendingGoogle = null;
    _error = null;
    notifyListeners();
  }

  // ── Biometric Unlock ───────────────────────────────────────────────────────
  Future<bool> unlockWithBiometrics() async {
    if (kIsWeb) {
      _error = 'Biometrics not available on web.';
      return false;
    }
    _setBusy(true);
    try {
      if (biometricLocked) {
        _error = 'Too many failed attempts. Please use your password.';
        return false;
      }
      if (!_biometricsAvailable) {
        _error = 'Biometrics not available on this device.';
        return false;
      }
      final lastEmail = await _keys.readLastEmail();
      if (lastEmail == null) {
        _error = 'No previous login found.';
        return false;
      }
      final user = await _db.getUser(lastEmail);
      if (user == null) {
        _error = 'User not found.';
        return false;
      }
      if (!user.hasLoggedInOnce) {
        _error = 'Complete one password login first.';
        return false;
      }
      if (!user.biometricsEnabled) {
        _error = 'Enable biometric unlock from your profile first.';
        return false;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock SkyFit Pro',
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (!ok) {
        _bioFailCount++;
        final remaining = _maxBioFails - _bioFailCount;
        if (biometricLocked) {
          _error =
              'Biometric locked after $_maxBioFails failed attempts. Please use your password.';
        } else {
          _error =
              'Biometric failed. $remaining attempt${remaining == 1 ? '' : 's'} remaining.';
        }
        notifyListeners();
        return false;
      }

      _bioFailCount = 0;
      _currentUser = user;
      _session.unlockSession();
      _error = null;
      notifyListeners();
      return true;
    } catch (_) {
      _bioFailCount++;
      _error = 'Biometric unlock failed.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void resetBioFailCount() {
    _bioFailCount = 0;
    _error = null;
    notifyListeners();
  }

  // ── Profile ────────────────────────────────────────────────────────────────
  Future<void> setBiometricsEnabled(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;
    if (!user.hasLoggedInOnce && enabled) {
      _error = 'Login with password at least once before enabling biometrics.';
      notifyListeners();
      return;
    }
    user.biometricsEnabled = enabled;
    if (!kIsWeb) await _db.updateUser(user);
    await _firestore.saveUser(user);
    _currentUser = user;
    _error = null;
    notifyListeners();
  }

  Future<void> updatePersonalInfo({
    String? displayName,
    String? phone,
    String? bio,
    String? location,
    String? jobTitle,
    String? birthday,
    int? age,
    double? weight,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    if (displayName != null && displayName.trim().isNotEmpty) {
      user.displayName = displayName.trim();
    }
    if (phone != null) user.phone = phone.trim().isEmpty ? null : phone.trim();
    if (bio != null) user.bio = bio.trim().isEmpty ? null : bio.trim();
    if (location != null) {
      user.location = location.trim().isEmpty ? null : location.trim();
    }
    if (jobTitle != null) {
      user.jobTitle = jobTitle.trim().isEmpty ? null : jobTitle.trim();
    }
    if (birthday != null) user.birthday = birthday.isEmpty ? null : birthday;
    if (age != null) user.age = age;
    if (weight != null) user.weight = weight;
    if (!kIsWeb) await _db.updateUser(user);
    await _firestore.saveUser(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateLocalPhoto(String path) async {
    final user = _currentUser;
    if (user == null) return;
    user.localPhotoPath = path;
    if (!kIsWeb) await _db.updateUser(user);
    await _firestore.saveUser(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> removeLocalPhoto() async {
    final user = _currentUser;
    if (user == null) return;
    user.localPhotoPath = null;
    if (!kIsWeb) await _db.updateUser(user);
    await _firestore.saveUser(user);
    _currentUser = user;
    notifyListeners();
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    if (_currentUser?.isGoogleUser == true) await _firebase.signOut();
    _currentUser = null;
    _pendingGoogle = null;
    _bioFailCount = 0;
    _session.lockSession();
    _error = null;
    notifyListeners();
  }

  void onSessionTimedOut() => logout();

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }
}

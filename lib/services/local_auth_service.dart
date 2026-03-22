import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ── Check if biometrics are available ──────────────────────────────────────
  Future<bool> isBiometricsAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      return supported && canCheck && available.isNotEmpty;
    } catch (e) {
      // ignore: avoid_print
      print('[LocalAuthService] Error checking biometrics: $e');
      return false;
    }
  }

  // ── Get available biometrics ───────────────────────────────────────────────
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      // ignore: avoid_print
      print('[LocalAuthService] Error getting biometrics: $e');
      return [];
    }
  }

  // ── Authenticate with biometrics ───────────────────────────────────────────
  Future<bool> authenticate({
    String reason = 'Unlock SkyFit Pro',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[LocalAuthService] Authentication error: $e');
      return false;
    }
  }

  // ── Check if device is supported ───────────────────────────────────────────
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      // ignore: avoid_print
      print('[LocalAuthService] Device support check error: $e');
      return false;
    }
  }
}

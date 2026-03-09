import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Handles 6-digit OTP generation and delivery via EmailJS.
///
/// Setup:
///   1. Create a free account at https://www.emailjs.com
///   2. Add an Email Service (e.g. Gmail) → note the Service ID
///   3. Create a Template with variables {{to_email}}, {{otp_code}},
///      {{app_name}} → note the Template ID
///   4. Copy your Public Key from Account → API Keys
///   5. Paste all three into constants.dart
class EmailOtpService {
  // Pending OTPs keyed by normalised email
  final Map<String, _PendingOtp> _pending = {};

  // ── Generate ──────────────────────────────────────────────────────────────

  /// Generates a 6-digit OTP, stores it internally, and attempts delivery.
  /// Returns the OTP string so callers can display it in debug / dev builds.
  Future<String> generateAndSend(String email) async {
    final otp = _generate6();
    _pending[email.toLowerCase().trim()] = _PendingOtp(
      code:      otp,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );

    // Always log to debug console for development
    // ignore: avoid_print
    print('╔══════════════════════════════╗');
    // ignore: avoid_print
    print('║  DEBUG OTP GENERATED: $otp  ║');
    // ignore: avoid_print
    print('╚══════════════════════════════╝');

    await _sendViaEmailJs(email: email, otp: otp);
    return otp;
  }

  // ── Verify ────────────────────────────────────────────────────────────────

  /// Returns true and clears OTP if [input] matches and has not expired.
  bool verify(String email, String input) {
    final key    = email.toLowerCase().trim();
    final record = _pending[key];

    if (record == null) return false;
    if (DateTime.now().isAfter(record.expiresAt)) {
      _pending.remove(key);
      return false;
    }
    if (input.trim() != record.code) return false;

    _pending.remove(key);
    return true;
  }

  /// Call this if you want to invalidate a pending OTP early.
  void discard(String email) {
    _pending.remove(email.toLowerCase().trim());
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _generate6() {
    final rnd = Random.secure();
    return (100000 + rnd.nextInt(900000)).toString();
  }

  Future<void> _sendViaEmailJs({
    required String email,
    required String otp,
  }) async {
    // Skip actual network call if credentials are still placeholders
    if (Constants.emailJsServiceId.startsWith('YOUR_')) {
      // ignore: avoid_print
      print('[EmailOtpService] EmailJS not configured – skipping real send.');
      // ignore: avoid_print
      print('OTP SENT TO EMAIL (simulated): $email  →  $otp');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'https://ciphertask.app',
        },
        body: jsonEncode({
          'service_id':  Constants.emailJsServiceId,
          'template_id': Constants.emailJsTemplateId,
          'user_id':     Constants.emailJsPublicKey,
          'template_params': {
            'to_email': email,
            'otp_code': otp,
            'app_name': 'CipherTask',
          },
        }),
      );

      if (response.statusCode == 200) {
        // ignore: avoid_print
        print('[EmailOtpService] OTP email sent successfully to $email');
      } else {
        // ignore: avoid_print
        print('[EmailOtpService] EmailJS error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[EmailOtpService] Network error: $e');
    }
  }
}

class _PendingOtp {
  final String   code;
  final DateTime expiresAt;
  _PendingOtp({required this.code, required this.expiresAt});
}

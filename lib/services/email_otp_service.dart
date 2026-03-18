import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class EmailOtpService {
  final Map<String, _PendingOtp> _pending = {};

  // ── Generate & Send ────────────────────────────────────────────────────────
  Future<String> generateAndSend(String email) async {
    final otp = _generate6();
    _pending[email.toLowerCase().trim()] = _PendingOtp(
      code: otp,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );

    // ignore: avoid_print
    print('╔══════════════════════════════╗');
    // ignore: avoid_print
    print('║  DEBUG OTP GENERATED: $otp  ║');
    // ignore: avoid_print
    print('╚══════════════════════════════╝');

    await _sendViaEmailJs(email: email, otp: otp);
    return otp;
  }

  // ── Verify ─────────────────────────────────────────────────────────────────
  bool verify(String email, String input) {
    final key = email.toLowerCase().trim();
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

  void discard(String email) => _pending.remove(email.toLowerCase().trim());

  // ── Private ────────────────────────────────────────────────────────────────
  String _generate6() {
    final rnd = Random.secure();
    return (100000 + rnd.nextInt(900000)).toString();
  }

  Future<void> _sendViaEmailJs({
    required String email,
    required String otp,
  }) async {
    if (Constants.emailJsServiceId.startsWith('YOUR_')) {
      // ignore: avoid_print
      print('[EmailOtpService] EmailJS not configured – skipping.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost', // ← FIXED
        },
        body: jsonEncode({
          'service_id': Constants.emailJsServiceId,
          'template_id': Constants.emailJsTemplateId,
          'user_id': Constants.emailJsPublicKey,
          'template_params': {
            'to_email': email, // ← recipient
            'otp_code': otp, // ← the OTP
            'app_name': 'SkyFit Pro', // ← FIXED
          },
        }),
      );

      if (response.statusCode == 200) {
        // ignore: avoid_print
        print('[EmailOtpService] OTP sent to $email');
      } else {
        // ignore: avoid_print
        print('[EmailOtpService] EmailJS error '
            '${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[EmailOtpService] Network error: $e');
    }
  }
}

class _PendingOtp {
  final String code;
  final DateTime expiresAt;
  _PendingOtp({required this.code, required this.expiresAt});
}

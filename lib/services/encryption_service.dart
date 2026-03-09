import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../utils/constants.dart';

/// AES-256-GCM encryption service with debug console logging.
///
/// Storage format: v1:<iv_b64>:<cipher_b64>
///   - v1  : version tag
///   - iv  : 12-byte random nonce (base64)
///   - cipher: ciphertext + 16-byte GCM auth tag (base64)
class EncryptionService {
  final List<int> _dbKey32;

  EncryptionService(this._dbKey32);

  // ── Key derivation ─────────────────────────────────────────────────────────

  List<int> _deriveFieldKey32() {
    final data = <int>[
      ..._dbKey32,
      ...utf8.encode(Constants.fieldKeyLabel),
    ];
    return sha256.convert(data).bytes; // 32 bytes
  }

  // ── Encrypt ────────────────────────────────────────────────────────────────

  /// Encrypts [plaintext] and returns a versioned payload string.
  /// Logs original + encrypted result to the debug console.
  String encryptSensitiveNote(String plaintext) {
    final keyBytes = _deriveFieldKey32();
    final key      = enc.Key(Uint8List.fromList(keyBytes));

    final rnd     = Random.secure();
    final ivBytes = List<int>.generate(12, (_) => rnd.nextInt(256));
    final iv      = enc.IV(Uint8List.fromList(ivBytes));

    final aes       = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = aes.encrypt(plaintext, iv: iv);

    final ivB64     = base64Encode(ivBytes);
    final cipherB64 = base64Encode(encrypted.bytes);
    final payload   = '${Constants.aesGcmPayloadVersion}:$ivB64:$cipherB64';

    // ── Debug log ────────────────────────────────────────────────
    // ignore: avoid_print
    print('[EncryptionService] ORIGINAL TODO  : $plaintext');
    // ignore: avoid_print
    print('[EncryptionService] ENCRYPTED DATA : ${encrypted.base64}');
    // ignore: avoid_print
    print('[EncryptionService] FULL PAYLOAD   : $payload');

    return payload;
  }

  // ── Decrypt ────────────────────────────────────────────────────────────────

  /// Decrypts a versioned payload string.
  /// Logs decrypted output to the debug console.
  String decryptSensitiveNote(String payload) {
    try {
      final parts = payload.split(':');
      if (parts.length != 3) return '[Invalid encrypted note]';

      final version = parts[0];
      if (version != Constants.aesGcmPayloadVersion) return '[Unsupported version]';

      final ivBytes     = base64Decode(parts[1]);
      final cipherBytes = base64Decode(parts[2]);

      final keyBytes = _deriveFieldKey32();
      final key      = enc.Key(Uint8List.fromList(keyBytes));
      final iv       = enc.IV(Uint8List.fromList(ivBytes));

      final aes  = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final plain = aes.decrypt(enc.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);

      // ── Debug log ────────────────────────────────────────────────
      // ignore: avoid_print
      print('[EncryptionService] DECRYPTED TODO  : $plain');

      return plain;
    } catch (e) {
      // ignore: avoid_print
      print('[EncryptionService] Decryption failed: $e');
      return '[Decryption failed]';
    }
  }
}

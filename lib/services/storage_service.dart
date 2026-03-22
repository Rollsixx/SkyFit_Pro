import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;

  StorageService(this._secureStorage);

  // ── DB Key ─────────────────────────────────────────────────────────────────
  Future<List<int>> getOrCreateDbKey32() async {
    final existing = await _secureStorage.read(key: Constants.secureDbKey);
    if (existing != null && existing.isNotEmpty) {
      return base64Decode(existing);
    }

    final rnd = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _secureStorage.write(
      key: Constants.secureDbKey,
      value: base64Encode(keyBytes),
    );
    // ignore: avoid_print
    print('[StorageService] New DB key generated and stored.');
    return keyBytes;
  }

  // ── Last Email ─────────────────────────────────────────────────────────────
  Future<void> saveLastEmail(String email) async {
    await _secureStorage.write(
      key: Constants.secureLastEmail,
      value: email,
    );
    // ignore: avoid_print
    print('[StorageService] Last email saved: $email');
  }

  Future<String?> readLastEmail() async {
    return await _secureStorage.read(key: Constants.secureLastEmail);
  }

  // ── Clear all secure storage ───────────────────────────────────────────────
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    // ignore: avoid_print
    print('[StorageService] All secure storage cleared.');
  }

  // ── Generic read/write ─────────────────────────────────────────────────────
  Future<void> write({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _secureStorage.delete(key: key);
  }
}

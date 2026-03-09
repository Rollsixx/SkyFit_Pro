import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class KeyStorageService {
  final FlutterSecureStorage _secureStorage;

  KeyStorageService(this._secureStorage);

  Future<List<int>> getOrCreateDbKey32() async {
    final existing = await _secureStorage.read(key: Constants.secureDbKey);
    if (existing != null && existing.isNotEmpty) {
      return base64Decode(existing);
    }

    final rnd      = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _secureStorage.write(
      key:   Constants.secureDbKey,
      value: base64Encode(keyBytes),
    );
    return keyBytes;
  }

  Future<void> saveLastEmail(String email) async =>
      _secureStorage.write(key: Constants.secureLastEmail, value: email);

  Future<String?> readLastEmail() async =>
      _secureStorage.read(key: Constants.secureLastEmail);
}

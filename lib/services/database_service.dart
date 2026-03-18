import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  final List<int> _dbKey32;
  late Box<UserModel> _users;

  DatabaseService(this._dbKey32);

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final cipher = HiveAesCipher(_dbKey32);
    _users = await Hive.openBox<UserModel>(
      Constants.usersBox,
      encryptionCipher: cipher,
    );
  }

  // ── USER ──────────────────────────────────────────────────────────────────
  Future<bool> userExists(String email) async =>
      _users.containsKey(email.toLowerCase().trim());

  Future<void> createUser(UserModel user) async =>
      _users.put(user.email.toLowerCase().trim(), user);

  Future<UserModel?> getUser(String email) async =>
      _users.get(email.toLowerCase().trim());

  Future<void> updateUser(UserModel user) async =>
      _users.put(user.email.toLowerCase().trim(), user);
}

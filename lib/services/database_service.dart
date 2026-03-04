import 'dart:math';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/todo_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  final List<int> _dbKey32;

  late Box<UserModel> _users;
  late Box<TodoModel> _todos;

  DatabaseService(this._dbKey32);

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TodoModelAdapter());
    }

    final cipher = HiveAesCipher(_dbKey32);

    _users = await Hive.openBox<UserModel>(
      Constants.usersBox,
      encryptionCipher: cipher,
    );

    _todos = await Hive.openBox<TodoModel>(
      Constants.todosBox,
      encryptionCipher: cipher,
    );
  }

  // -------------------- USER --------------------

  Future<bool> userExists(String email) async {
    return _users.containsKey(email.toLowerCase().trim());
  }

  Future<void> createUser(UserModel user) async {
    await _users.put(user.email.toLowerCase().trim(), user);
  }

  Future<UserModel?> getUser(String email) async {
    return _users.get(email.toLowerCase().trim());
  }

  Future<void> updateUser(UserModel user) async {
    await _users.put(user.email.toLowerCase().trim(), user);
  }

  // -------------------- TODOS --------------------

  List<TodoModel> getTodosForOwner(String email) {
    final owner = email.toLowerCase().trim();
    final all = _todos.values.where((t) => t.ownerEmail == owner).toList();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  Future<void> upsertTodo(TodoModel todo) async {
    await _todos.put(todo.id, todo);
  }

  Future<void> deleteTodo(String todoId) async {
    await _todos.delete(todoId);
  }

  String newId() {
    final rnd = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final rand = List.generate(12, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$now-$rand';
  }
}
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class UserViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final FirestoreService _firestore;

  UserModel? _currentUser;
  bool _busy = false;
  String? _error;

  UserViewModel({
    required DatabaseService db,
    required FirestoreService firestore,
  })  : _db = db,
        _firestore = firestore;

  // ── Getters ────────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isBusy => _busy;
  String? get error => _error;

  // ── Set current user ───────────────────────────────────────────────────────
  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  // ── Update personal info ───────────────────────────────────────────────────
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
    _setBusy(true);
    try {
      if (displayName != null && displayName.trim().isNotEmpty) {
        user.displayName = displayName.trim();
      }
      if (phone != null) {
        user.phone = phone.trim().isEmpty ? null : phone.trim();
      }
      if (bio != null) {
        user.bio = bio.trim().isEmpty ? null : bio.trim();
      }
      if (location != null) {
        user.location = location.trim().isEmpty ? null : location.trim();
      }
      if (jobTitle != null) {
        user.jobTitle = jobTitle.trim().isEmpty ? null : jobTitle.trim();
      }
      if (birthday != null) {
        user.birthday = birthday.isEmpty ? null : birthday;
      }
      if (age != null) user.age = age;
      if (weight != null) user.weight = weight;

      await _db.updateUser(user);
      await _firestore.saveUser(user);
      _currentUser = user;
      _error = null;
      // ignore: avoid_print
      print('[UserViewModel] Personal info updated for ${user.email}');
    } catch (e) {
      _error = 'Failed to update profile: $e';
      // ignore: avoid_print
      print('[UserViewModel] Error: $e');
    } finally {
      _setBusy(false);
    }
  }

  // ── Update local photo ─────────────────────────────────────────────────────
  Future<void> updateLocalPhoto(String path) async {
    final user = _currentUser;
    if (user == null) return;
    _setBusy(true);
    try {
      user.localPhotoPath = path;
      await _db.updateUser(user);
      await _firestore.saveUser(user);
      _currentUser = user;
      _error = null;
      // ignore: avoid_print
      print('[UserViewModel] Local photo updated: $path');
    } catch (e) {
      _error = 'Failed to update photo: $e';
    } finally {
      _setBusy(false);
    }
  }

  // ── Remove local photo ─────────────────────────────────────────────────────
  Future<void> removeLocalPhoto() async {
    final user = _currentUser;
    if (user == null) return;
    _setBusy(true);
    try {
      user.localPhotoPath = null;
      await _db.updateUser(user);
      await _firestore.saveUser(user);
      _currentUser = user;
      _error = null;
      // ignore: avoid_print
      print('[UserViewModel] Local photo removed.');
    } catch (e) {
      _error = 'Failed to remove photo: $e';
    } finally {
      _setBusy(false);
    }
  }

  // ── Pick image from gallery or camera ─────────────────────────────────────
  Future<String?> pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return null;
      return picked.path;
    } catch (e) {
      _error = 'Could not pick image: $e';
      // ignore: avoid_print
      print('[UserViewModel] Image pick error: $e');
      return null;
    }
  }

  // ── Enable/disable biometrics ──────────────────────────────────────────────
  Future<void> setBiometricsEnabled(bool enabled) async {
    final user = _currentUser;
    if (user == null) return;
    _setBusy(true);
    try {
      user.biometricsEnabled = enabled;
      await _db.updateUser(user);
      await _firestore.saveUser(user);
      _currentUser = user;
      _error = null;
      // ignore: avoid_print
      print('[UserViewModel] Biometrics enabled: $enabled');
    } catch (e) {
      _error = 'Failed to update biometrics: $e';
    } finally {
      _setBusy(false);
    }
  }

  // ── Clear error ────────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }
}

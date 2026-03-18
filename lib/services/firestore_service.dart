import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'users';

  // ── Save / Update User ─────────────────────────────────────────────────────
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection(_collection).doc(user.email).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'isGoogleUser': user.isGoogleUser,
        'phone': user.phone,
        'bio': user.bio,
        'location': user.location,
        'jobTitle': user.jobTitle,
        'birthday': user.birthday,
        'memberSince': user.memberSince?.toIso8601String(),
        'biometricsEnabled': user.biometricsEnabled,
        'age': user.age,
        'weight': user.weight,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // ignore: avoid_print
      print('[FirestoreService] User saved: ${user.email}');
    } catch (e) {
      // ignore: avoid_print
      print('[FirestoreService] Error saving user: $e');
    }
  }

  // ── Get User ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUser(String email) async {
    try {
      final doc = await _db
          .collection(_collection)
          .doc(email.toLowerCase().trim())
          .get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      // ignore: avoid_print
      print('[FirestoreService] Error getting user: $e');
      return null;
    }
  }

  // ── Check User Exists ──────────────────────────────────────────────────────
  Future<bool> userExists(String email) async {
    try {
      final doc = await _db
          .collection(_collection)
          .doc(email.toLowerCase().trim())
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ── Delete User ────────────────────────────────────────────────────────────
  Future<void> deleteUser(String email) async {
    try {
      await _db
          .collection(_collection)
          .doc(email.toLowerCase().trim())
          .delete();
    } catch (e) {
      // ignore: avoid_print
      print('[FirestoreService] Error deleting user: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'users';

  // ── Save/Update User ────────────────────────────────────────────────────────
  Future<void> saveUser(UserModel user) async {
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
    }, SetOptions(merge: true));
  }

  // ── Get User ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUser(String email) async {
    final doc = await _db.collection(_collection).doc(email).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // ── Check User Exists ───────────────────────────────────────────────────────
  Future<bool> userExists(String email) async {
    final doc = await _db.collection(_collection).doc(email).get();
    return doc.exists;
  }
}

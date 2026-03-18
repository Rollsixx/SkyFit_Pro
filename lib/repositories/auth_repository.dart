import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

/// Repository Pattern — Auth Data Decision Layer
/// Decides whether to use Firebase Auth, Firestore, or local Hive
class AuthRepository {
  final DatabaseService _db;
  final FirebaseAuthService _firebaseAuth;
  final FirestoreService _firestore;

  AuthRepository({
    required DatabaseService db,
    required FirebaseAuthService firebaseAuth,
    required FirestoreService firestore,
  })  : _db = db,
        _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  // ── Check if user exists ───────────────────────────────────────────────────
  Future<bool> userExists(String email) async {
    // Check local Hive first (faster)
    final localExists = await _db.userExists(email);
    if (localExists) return true;
    // Fallback to Firestore
    return await _firestore.userExists(email);
  }

  // ── Get user ───────────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String email) async {
    // Always try local first
    final localUser = await _db.getUser(email);
    if (localUser != null) return localUser;
    // ignore: avoid_print
    print('[AuthRepository] User not found locally, checking Firestore...');
    return null;
  }

  // ── Create user ────────────────────────────────────────────────────────────
  Future<void> createUser(UserModel user) async {
    // Save to both local and Firestore
    await _db.createUser(user);
    await _firestore.saveUser(user);
  }

  // ── Update user ────────────────────────────────────────────────────────────
  Future<void> updateUser(UserModel user) async {
    // Update both local and Firestore
    await _db.updateUser(user);
    await _firestore.saveUser(user);
  }

  // ── Register with Firebase Auth ────────────────────────────────────────────
  Future<void> registerWithFirebase({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.registerWithEmail(
        email: email,
        password: password,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[AuthRepository] Firebase register note: $e');
    }
  }

  // ── Login with Firebase Auth ───────────────────────────────────────────────
  Future<void> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.loginWithEmail(
        email: email,
        password: password,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[AuthRepository] Firebase login note: $e');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<GoogleSignInResult> signInWithGoogle() async {
    return await _firebaseAuth.signInWithGoogle();
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

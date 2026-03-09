import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // forceCodeForRefreshToken forces the account chooser to appear every time
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentFirebaseUser => _auth.currentUser;

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      // ✅ Always sign out first to force the account chooser dialog
      await _googleSignIn.signOut();
      await _auth.signOut();

      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return GoogleSignInResult.cancelled();
      }

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // ignore: avoid_print
      print('[FirebaseAuthService] Google sign-in success: ${user.email}');

      return GoogleSignInResult.success(
        firebaseUser: user,
        displayName:  user.displayName,
        email:        user.email ?? googleAccount.email,
        photoUrl:     user.photoURL,
        isNewUser:    userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('[FirebaseAuthService] FirebaseAuthException: ${e.code}');
      return GoogleSignInResult.error(e.message ?? 'Google sign-in failed.');
    } catch (e) {
      // ignore: avoid_print
      print('[FirebaseAuthService] Error: $e');
      return GoogleSignInResult.error('Google sign-in failed: $e');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    // ignore: avoid_print
    print('[FirebaseAuthService] Signed out.');
  }
}

// ── Result type ──────────────────────────────────────────────────────────────

class GoogleSignInResult {
  final bool    success;
  final bool    cancelled;
  final User?   firebaseUser;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool    isNewUser;
  final String? errorMessage;

  GoogleSignInResult._({
    required this.success,
    required this.cancelled,
    this.firebaseUser,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isNewUser = false,
    this.errorMessage,
  });

  factory GoogleSignInResult.success({
    required User   firebaseUser,
    String?         displayName,
    required String email,
    String?         photoUrl,
    bool            isNewUser = false,
  }) =>
      GoogleSignInResult._(
        success:      true,
        cancelled:    false,
        firebaseUser: firebaseUser,
        displayName:  displayName,
        email:        email,
        photoUrl:     photoUrl,
        isNewUser:    isNewUser,
      );

  factory GoogleSignInResult.cancelled() =>
      GoogleSignInResult._(success: false, cancelled: true);

  factory GoogleSignInResult.error(String message) =>
      GoogleSignInResult._(
        success:      false,
        cancelled:    false,
        errorMessage: message,
      );
}
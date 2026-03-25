import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  // ── Web Client ID (for Google Sign-In on web) ──────────────────────────────
  // FIXED: Must match the OAuth 2.0 Client ID in Google Cloud Console
  // and the project that owns this Firebase project (messagingSenderId prefix)
  static const String webClientId =
      '705462588257-f34qgqhujhr69qusrm6fa7iea9fo1e21.apps.googleusercontent.com';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDWrZWT6ytEO6ycGpvl-3njsjoeG-812cg',
    authDomain: 'skyfit-pro-635ab.firebaseapp.com',
    projectId: 'skyfit-pro-635ab',
    storageBucket: 'skyfit-pro-635ab.firebasestorage.app',
    messagingSenderId: '705462588257',
    appId: '1:705462588257:web:fbadc072abc153ebe0777e',
    measurementId: 'G-W6L5NXRHWK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWJ1arSqHNin68qtWsk5FO8P0_ufNPGk0',
    appId: '1:705462588257:android:542b6d2643fe6e99e0777e',
    messagingSenderId: '705462588257',
    projectId: 'skyfit-pro-635ab',
    storageBucket: 'skyfit-pro-635ab.appspot.com',
  );
}

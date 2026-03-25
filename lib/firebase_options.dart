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
  static const String webClientId =
      '725416192091-kssndjmn18gg5bm9chumh373iu1mb1r6.apps.googleusercontent.com';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDWrZWT6ytEO6ycGpvl-3njsjoeG-812cg',
    authDomain: 'skyfit-pro-635ab.firebaseapp.com',
    projectId: 'skyfit-pro-635ab',
    storageBucket: 'skyfit-pro-635ab.firebasestorage.app',
    messagingSenderId: '725416192091',
    appId: '1:725416192091:web:fbadc072abc153ebe0777e',
    measurementId: 'G-W6L5NXRHWK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWJ1arSqHNin68qtWsk5FO8P0_ufNPGk0',
    appId: '1:725416192091:android:542b6d2643fe6e99e0777e',
    messagingSenderId: '725416192091',
    projectId: 'skyfit-pro-635ab',
    storageBucket: 'skyfit-pro-635ab.appspot.com',
  );
}

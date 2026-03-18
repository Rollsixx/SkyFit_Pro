import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWJ1arSqHNin68qtWsk5FO8P0_ufNPGk0',
    appId: '1:725416192091:android:542b6d2643fe6e99e0777e',
    messagingSenderId: '725416192091',
    projectId: 'skyfit-pro-635ab',
    storageBucket: 'skyfit-pro-635ab.appspot.com',
  );
}

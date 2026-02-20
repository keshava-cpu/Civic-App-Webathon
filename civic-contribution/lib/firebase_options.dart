// THIS FILE IS GENERATED — Run `flutterfire configure` to regenerate.
// After running FlutterFire CLI, replace this file with the generated one.
//
// Steps:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//
// The command above will replace this file automatically.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported in this build.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured.');
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZRtZ9ezNRulMN7fMgBxIiLTrbKD9wr9Y',
    appId: '1:888278690124:android:49323496f2a6d717db47e9',
    messagingSenderId: '888278690124',
    projectId: 'civic-contribution',
    storageBucket: 'civic-contribution.firebasestorage.app',
  );

  // ── REPLACE THESE VALUES with the ones from google-services.json ──────────
  // ──────────────────────────────────────────────────────────────────────────
}
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the Android app registered in this project.
///
/// These values correspond to android/app/google-services.json. If you add
/// another platform later, run `flutterfire configure` and use the generated
/// options for that platform as well.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }

    throw UnsupportedError(
      'Firebase is configured for Android in this project. '
      'Run `flutterfire configure` to add the current platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEEeYc0FB9uoRNYq63s9LkXiW8UajaJrA',
    appId: '1:380091468888:android:3756c5672e32e4e9ac8e2d',
    messagingSenderId: '380091468888',
    projectId: 'fir-assignment-6bb31',
    storageBucket: 'fir-assignment-6bb31.firebasestorage.app',
  );
}

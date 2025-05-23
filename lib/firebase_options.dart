// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC7ACPshlHaMpGfpVG1ldSWLLVlwrFHvgg',
    appId: '1:141856292:web:294154a3ddd7c8be97d2b1',
    messagingSenderId: '141856292',
    projectId: 'tone-tribe',
    authDomain: 'tone-tribe.firebaseapp.com',
    storageBucket: 'tone-tribe.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXMEAubCOaCZ_bnahabSHDbsL8sZgXuaw',
    appId: '1:141856292:android:47f468b47bab490897d2b1',
    messagingSenderId: '141856292',
    projectId: 'tone-tribe',
    storageBucket: 'tone-tribe.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxYfiW5bVJyqr-jSAgHLaVVnhBPv8iQeU',
    appId: '1:141856292:ios:bba8c7c116b4ce2697d2b1',
    messagingSenderId: '141856292',
    projectId: 'tone-tribe',
    storageBucket: 'tone-tribe.firebasestorage.app',
    iosBundleId: 'com.example.tonetribe',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDxYfiW5bVJyqr-jSAgHLaVVnhBPv8iQeU',
    appId: '1:141856292:ios:bba8c7c116b4ce2697d2b1',
    messagingSenderId: '141856292',
    projectId: 'tone-tribe',
    storageBucket: 'tone-tribe.firebasestorage.app',
    iosBundleId: 'com.example.tonetribe',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC7ACPshlHaMpGfpVG1ldSWLLVlwrFHvgg',
    appId: '1:141856292:web:f6b32a73b4d1556a97d2b1',
    messagingSenderId: '141856292',
    projectId: 'tone-tribe',
    authDomain: 'tone-tribe.firebaseapp.com',
    storageBucket: 'tone-tribe.firebasestorage.app',
  );
}

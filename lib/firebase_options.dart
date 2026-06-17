// Generated from existing Android/iOS Firebase config.
// Run: flutterfire configure --project=barbershop-ee9c0 --platforms=web
// to fill in the real web values and overwrite this file.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.linux:
        return web; // Desktop uses the web config
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace with real values from Firebase Console → Project Settings → Web apps
  // Run: flutterfire configure --project=barbershop-ee9c0 --platforms=web

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQYUXVwF_zOUyONW1IY_k-TSVcNcJ9oz8',
    appId: '1:956317826330:web:0cdc6171ab9bfaef2b00a3',
    messagingSenderId: '956317826330',
    projectId: 'barbershop-ee9c0',
    authDomain: 'barbershop-ee9c0.firebaseapp.com',
    storageBucket: 'barbershop-ee9c0.firebasestorage.app',
    measurementId: 'G-YNBDXNGWTS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBT5NWNWwgP4aLnzVslWEQT0fOZn2OBWS0',
    appId: '1:956317826330:android:0c46c91f7d607f812b00a3',
    messagingSenderId: '956317826330',
    projectId: 'barbershop-ee9c0',
    storageBucket: 'barbershop-ee9c0.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAYAS2Tk4UNre6Bh9abIHSI-9qahsSYH4U',
    appId: '1:956317826330:ios:4d001a57c0ba16da2b00a3',
    messagingSenderId: '956317826330',
    projectId: 'barbershop-ee9c0',
    storageBucket: 'barbershop-ee9c0.firebasestorage.app',
    iosBundleId: 'com.grullondev.barberia',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAYAS2Tk4UNre6Bh9abIHSI-9qahsSYH4U',
    appId: '1:956317826330:ios:4d001a57c0ba16da2b00a3',
    messagingSenderId: '956317826330',
    projectId: 'barbershop-ee9c0',
    storageBucket: 'barbershop-ee9c0.firebasestorage.app',
    iosBundleId: 'com.grullondev.barberia',
  );
}

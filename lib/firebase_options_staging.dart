// Firebase client configuration for the STAGING project (barberia-staging,
// project number 169151296960). Values come from
//   firebase apps:sdkconfig WEB 1:169151296960:web:cb9ed6ec4580f0756e8425 \
//     --project barberia-staging
// They are public client identifiers, not secrets.
//
// Only Web is registered in staging. Native staging builds need their own
// Android/iOS app registrations first (see docs/STAGING.md).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class StagingFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'FIREBASE_ENV=staging is only configured for Web. Register the '
      'Android/iOS apps in barberia-staging first (docs/STAGING.md).',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZYbaCIpD44-mIDefyuQ4_8nDzehmVh3o',
    appId: '1:169151296960:web:cb9ed6ec4580f0756e8425',
    messagingSenderId: '169151296960',
    projectId: 'barberia-staging',
    authDomain: 'barberia-staging.firebaseapp.com',
    storageBucket: 'barberia-staging.firebasestorage.app',
    measurementId: 'G-XQT7MJZTZP',
  );
}

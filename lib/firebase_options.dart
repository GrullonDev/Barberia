// ARCHIVO GENERADO AUTOMÁTICAMENTE — REFACTORIZADO PARA USAR .ENV
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_ANDROID_API_KEY', fallback: 'PLACEHOLDER'),
    appId: dotenv.get('FIREBASE_ANDROID_APP_ID', fallback: 'PLACEHOLDER'),
    messagingSenderId: dotenv.get(
      'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
      fallback: 'PLACEHOLDER',
    ),
    projectId: dotenv.get('FIREBASE_PROJECT_ID', fallback: 'barbershop-ee9c0'),
    storageBucket: dotenv.get(
      'FIREBASE_STORAGE_BUCKET',
      fallback: 'barbershop-ee9c0.firebasestorage.app',
    ),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_ANDROID_API_KEY'),
    appId: dotenv.get('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_ANDROID_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_IOS_API_KEY'),
    appId: dotenv.get('FIREBASE_IOS_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_IOS_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID'),
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_IOS_API_KEY'),
    appId: dotenv.get('FIREBASE_IOS_APP_ID'),
    messagingSenderId: dotenv.get('FIREBASE_IOS_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID'),
  );
}

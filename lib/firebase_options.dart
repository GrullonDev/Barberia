// ARCHIVO GENERADO AUTOMÁTICAMENTE — NO EDITAR MANUALMENTE
// Este archivo será sobreescrito al ejecutar:
//   flutterfire configure --project=barbershop-ee9c0
//
// Si ves errores, ejecuta ese comando primero.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma. '
          'Ejecuta: flutterfire configure --project=barbershop-ee9c0',
        );
    }
  }

  // PLACEHOLDER — será reemplazado por flutterfire configure
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'barbershop-ee9c0',
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
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'barbershop-ee9c0',
    iosBundleId: 'com.grullondev.barberia',
  );
}
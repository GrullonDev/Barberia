import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/app.dart';
import 'package:barberia/core/firebase/firebase_seed_service.dart';
import 'package:barberia/core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed initial Firestore data if collections are empty
  await FirebaseSeedService().seedIfNeeded();

  // Initialize Notifications
  await NotificationService().init();
  await NotificationService().requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

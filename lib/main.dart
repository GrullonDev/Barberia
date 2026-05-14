import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:barberia/app.dart';
import 'package:barberia/core/firebase/firebase_seed_service.dart';
import 'package:barberia/core/services/local_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed initial Firestore data if collections are empty
  await FirebaseSeedService().seedIfNeeded();

  // Initialize Notifications
  await LocalNotificationService().init();
  await LocalNotificationService().requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

import 'package:barberia/app_first.dart';
import 'package:barberia/core/observability/crash_reporting.dart';
import 'package:barberia/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CrashReporting.init();
  runApp(const ProviderScope(child: App()));
}

import 'package:barberia/app_first.dart';
import 'package:barberia/core/firebase/dev_environment.dart';
import 'package:barberia/core/firebase/firebase_environment.dart';
import 'package:barberia/core/observability/crash_reporting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await Firebase.initializeApp(options: firebaseOptionsForBuild());
  verifyFirebaseProject(app.options);
  if (kDebugMode || firebaseEnvName != 'production') {
    debugPrint(
      '[firebase] FIREBASE_ENV=$firebaseEnvName '
      'project=${app.options.projectId}',
    );
  }
  await configureDevEnvironment();
  await CrashReporting.init();
  runApp(const ProviderScope(child: App()));
}

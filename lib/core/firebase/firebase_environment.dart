import 'package:barberia/core/firebase/dev_environment.dart';
import 'package:barberia/firebase_options.dart';
import 'package:barberia/firebase_options_staging.dart';
import 'package:firebase_core/firebase_core.dart';

/// Which Firebase project this build talks to, chosen at build time:
///
///   flutter build web --dart-define=FIREBASE_ENV=staging
///
/// `production` (the default, so existing builds are unchanged), `staging`,
/// or `demo` (local emulators only). Any other value stops the app at
/// startup instead of falling back to another project.
///
/// Every branch below is a compile-time constant, so a build only contains
/// the options of its own environment: a staging bundle has no production
/// config in it at all (tool/staging.sh checks this before deploying).
const String firebaseEnvName = String.fromEnvironment(
  'FIREBASE_ENV',
  defaultValue: 'production',
);

const bool _production = firebaseEnvName == 'production';
const bool _staging = firebaseEnvName == 'staging';
const bool _demo = firebaseEnvName == 'demo';

/// Project id this build must be initialized with; empty if unknown env.
const String expectedFirebaseProjectId = _production
    ? 'barbershop-ee9c0'
    : _staging
    ? 'barberia-staging'
    : _demo
    ? 'demo-barberia'
    : '';

/// `demo-*` project ids never reach real services; it must match the
/// `--project` the emulators were started with so the app sees seeded data.
const FirebaseOptions _demoOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:web:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-barberia',
  authDomain: 'demo-barberia.firebaseapp.com',
);

FirebaseOptions firebaseOptionsForBuild() {
  if (_production) return DefaultFirebaseOptions.currentPlatform;
  if (_staging) return StagingFirebaseOptions.currentPlatform;
  if (_demo) {
    if (!useFirebaseEmulators) {
      throw StateError(
        'FIREBASE_ENV=demo requires --dart-define=USE_FIREBASE_EMULATORS=true.',
      );
    }
    return _demoOptions;
  }
  throw StateError(
    'Unknown FIREBASE_ENV "$firebaseEnvName". '
    'Use production, staging or demo.',
  );
}

/// Fails closed if the initialized app is not this build's project
/// (e.g. a mis-edited options file).
void verifyFirebaseProject(FirebaseOptions actual) {
  if (expectedFirebaseProjectId.isEmpty ||
      actual.projectId != expectedFirebaseProjectId) {
    throw StateError(
      'FIREBASE_ENV=$firebaseEnvName expects project '
      '$expectedFirebaseProjectId but the app was initialized for '
      '${actual.projectId}.',
    );
  }
}

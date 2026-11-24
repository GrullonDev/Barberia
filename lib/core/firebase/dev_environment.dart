import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/semantics.dart';

/// Opt-in build flags for local end-to-end testing. Both default to false,
/// so release and staging builds are unaffected unless passed explicitly:
///
///   flutter build web --dart-define=USE_FIREBASE_EMULATORS=true \
///     --dart-define=E2E_SEMANTICS=true
const bool useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
);

/// Builds the accessibility tree eagerly so browser tests (Playwright) can
/// locate Flutter widgets by their labels.
const bool e2eSemantics = bool.fromEnvironment('E2E_SEMANTICS');

const String _emulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: 'localhost',
);

SemanticsHandle? _semanticsHandle;

/// Call right after `Firebase.initializeApp`. Ports match firebase.json.
Future<void> configureDevEnvironment() async {
  if (useFirebaseEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(_emulatorHost, 5001);
  }
  if (e2eSemantics) {
    _semanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
  }
}

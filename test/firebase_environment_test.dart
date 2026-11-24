// Runs under whichever FIREBASE_ENV it is compiled with; CI covers:
//   flutter test test/firebase_environment_test.dart
//   flutter test test/firebase_environment_test.dart --dart-define=FIREBASE_ENV=staging
//   flutter test test/firebase_environment_test.dart --dart-define=FIREBASE_ENV=bogus
import 'package:barberia/core/firebase/firebase_environment.dart';
import 'package:barberia/firebase_options.dart';
import 'package:barberia/firebase_options_staging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

const _projects = {
  'production': 'barbershop-ee9c0',
  'staging': 'barberia-staging',
};

void main() {
  test('production and staging are separate projects', () {
    expect(DefaultFirebaseOptions.web.projectId, 'barbershop-ee9c0');
    expect(StagingFirebaseOptions.web.projectId, 'barberia-staging');
    expect(StagingFirebaseOptions.web.messagingSenderId, '169151296960');
    expect(
      StagingFirebaseOptions.web.apiKey,
      isNot(DefaultFirebaseOptions.web.apiKey),
    );
  });

  final expected = _projects[firebaseEnvName];
  if (expected != null) {
    test('FIREBASE_ENV=$firebaseEnvName selects $expected', () {
      expect(expectedFirebaseProjectId, expected);
      // VM tests run as a native platform; staging is web-only.
      if (firebaseEnvName == 'production') {
        expect(firebaseOptionsForBuild().projectId, expected);
      }
      const web = firebaseEnvName == 'production'
          ? DefaultFirebaseOptions.web
          : StagingFirebaseOptions.web;
      verifyFirebaseProject(web);
    });

    test('verify rejects the other environment\'s options', () {
      const other = firebaseEnvName == 'production'
          ? StagingFirebaseOptions.web
          : DefaultFirebaseOptions.web;
      expect(() => verifyFirebaseProject(other), throwsStateError);
    });
  } else if (firebaseEnvName != 'demo') {
    test('unknown FIREBASE_ENV=$firebaseEnvName fails closed', () {
      expect(expectedFirebaseProjectId, isEmpty);
      expect(firebaseOptionsForBuild, throwsStateError);
      expect(
        () => verifyFirebaseProject(
          const FirebaseOptions(
            apiKey: 'k',
            appId: 'a',
            messagingSenderId: 'm',
            projectId: '',
          ),
        ),
        throwsStateError,
      );
    });
  }
}

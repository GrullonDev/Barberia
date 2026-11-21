import 'dart:async';

import 'package:barberia/core/platform/platform_capabilities.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin facade over Firebase Crashlytics.
///
/// - Only active where [PlatformCapabilities.crashReportingSupported] is true
///   (Android/iOS). Everywhere else every call is a no-op, so web, desktop and
///   tests never touch the Crashlytics plugin.
/// - Collection is off in debug builds to keep the dashboard clean; enable it
///   locally with `--dart-define=CRASHLYTICS_IN_DEBUG=true` to test the setup.
/// - Never send PII (email, phone, names). The Firebase uid, role and shopId
///   are enough to find a user's crashes.
abstract final class CrashReporting {
  static const bool _collectInDebug = bool.fromEnvironment(
    'CRASHLYTICS_IN_DEBUG',
  );

  static bool _enabled = false;

  /// True once [init] has wired Crashlytics on a supported platform.
  static bool get isEnabled => _enabled;

  /// Call once, right after `Firebase.initializeApp`.
  static Future<void> init({PlatformCapabilities? capabilities}) async {
    final caps = capabilities ?? PlatformCapabilities.current;
    if (!caps.crashReportingSupported) return;

    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(
      !kDebugMode || _collectInDebug,
    );

    // Errors thrown inside the Flutter framework (build, layout, paint...).
    FlutterError.onError = crashlytics.recordFlutterFatalError;

    // Uncaught async errors outside the framework (futures, streams, isolates
    // started by plugins).
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    _enabled = true;
  }

  /// Records a handled error that still indicates something went wrong
  /// (e.g. a failed Firestore read that we recovered from).
  static Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    required String reason,
  }) async {
    if (!_enabled) {
      debugPrint('[non-fatal] $reason: $error');
      return;
    }
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  /// Attaches the signed-in staff member to subsequent reports.
  /// Pass `null` for [uid] on sign-out.
  static Future<void> setUser({
    required String? uid,
    String? role,
    String? shopId,
  }) async {
    if (!_enabled) return;
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setUserIdentifier(uid ?? '');
    await crashlytics.setCustomKey('role', role ?? 'none');
    await crashlytics.setCustomKey('shopId', shopId ?? 'none');
  }

  /// Breadcrumb shown alongside the next crash report.
  static void log(String message) {
    if (!_enabled) return;
    unawaited(FirebaseCrashlytics.instance.log(message));
  }
}

import 'package:barberia/core/observability/crash_reporting.dart';
import 'package:barberia/core/platform/platform_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CrashReporting is a no-op where Crashlytics is unsupported', () async {
    final previousHandler = FlutterError.onError;
    final webCaps = PlatformCapabilities.forPlatform(
      isWeb: true,
      platform: TargetPlatform.android,
      webStaffPortals: false,
    );

    // Must not touch the Crashlytics plugin (it would throw: no Firebase app).
    await CrashReporting.init(capabilities: webCaps);
    await CrashReporting.setUser(uid: 'abc', role: 'admin', shopId: 's1');
    await CrashReporting.recordNonFatal(
      StateError('boom'),
      StackTrace.current,
      reason: 'test',
    );
    CrashReporting.log('breadcrumb');

    expect(CrashReporting.isEnabled, isFalse);
    expect(FlutterError.onError, same(previousHandler));
  });
}

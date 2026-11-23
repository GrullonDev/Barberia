import 'package:barberia/core/platform/platform_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformCapabilities', () {
    test('web hides staff portals by default and opens on home', () {
      final caps = PlatformCapabilities.forPlatform(
        isWeb: true,
        platform: TargetPlatform.android,
        webStaffPortals: false,
      );
      expect(caps.staffPortalsEnabled, isFalse);
      expect(caps.initialLocation, '/');
      expect(caps.crashReportingSupported, isFalse);
    });

    test('web staff portals can be enabled for a pilot build', () {
      final caps = PlatformCapabilities.forPlatform(
        isWeb: true,
        platform: TargetPlatform.android,
        webStaffPortals: true,
      );
      expect(caps.staffPortalsEnabled, isTrue);
      expect(caps.initialLocation, '/');
    });

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      test('$platform enables staff portals and opens on /login', () {
        final caps = PlatformCapabilities.forPlatform(
          isWeb: false,
          platform: platform,
        );
        expect(caps.staffPortalsEnabled, isTrue);
        expect(caps.initialLocation, '/login');
        expect(caps.crashReportingSupported, isTrue);
      });
    }

    test('desktop enables staff portals and opens on home', () {
      final caps = PlatformCapabilities.forPlatform(
        isWeb: false,
        platform: TargetPlatform.macOS,
      );
      expect(caps.staffPortalsEnabled, isTrue);
      expect(caps.initialLocation, '/');
      expect(caps.crashReportingSupported, isFalse);
    });
  });
}

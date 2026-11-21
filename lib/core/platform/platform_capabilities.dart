import 'package:flutter/foundation.dart';

/// Single source of truth for what each platform is allowed to do.
///
/// The product is moving towards web as the primary system while keeping the
/// mobile app (see docs/ESTRATEGIA_PLATAFORMAS.md). Screens and the router must
/// ask this class instead of checking `kIsWeb` / `defaultTargetPlatform`
/// directly, so enabling staff portals on web later is a one-line change.
@immutable
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.staffPortalsEnabled,
    required this.initialLocation,
    required this.crashReportingSupported,
  });

  /// Resolves capabilities for the running platform.
  ///
  /// Staff portals on web stay off until Phase 3 of the roadmap; they can be
  /// enabled for a pilot build with `--dart-define=WEB_STAFF_PORTALS=true`.
  factory PlatformCapabilities.forPlatform({
    required bool isWeb,
    required TargetPlatform platform,
    bool webStaffPortals = const bool.fromEnvironment('WEB_STAFF_PORTALS'),
  }) {
    if (isWeb) {
      return PlatformCapabilities(
        staffPortalsEnabled: webStaffPortals,
        initialLocation: '/',
        // Crashlytics has no web SDK.
        crashReportingSupported: false,
      );
    }
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    return PlatformCapabilities(
      staffPortalsEnabled: true,
      // On phones the app is the staff tool, so it opens on staff login.
      initialLocation: isMobile ? '/login' : '/',
      // Crashlytics only ships for Android/iOS (no Windows/Linux, and macOS
      // is not a target we release).
      crashReportingSupported: isMobile,
    );
  }

  static final PlatformCapabilities current = PlatformCapabilities.forPlatform(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );

  /// Whether `/login`, `/admin/*` and `/barber/*` exist on this platform.
  final bool staffPortalsEnabled;

  /// First route shown when the app starts.
  final String initialLocation;

  /// Whether Firebase Crashlytics is available and should be initialised.
  final bool crashReportingSupported;
}

import 'package:barberia/core/l10n/app_localizations.dart';
import 'package:barberia/core/platform/platform_capabilities.dart';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:barberia/core/router/app_router.dart';
import 'package:barberia/features/home/presentation/widgets/home_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> pumpFooter(WidgetTester tester, {required bool staffPortals}) {
  tester.view.physicalSize = const Size(1280, 2000);
  addTearDown(tester.view.resetPhysicalSize);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        l10nProvider.overrideWithValue(AppLocalizations('es')),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(
            isWeb: true,
            platform: TargetPlatform.android,
            webStaffPortals: staffPortals,
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: HomeFooter())),
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final staffAccess = AppLocalizations('es').get('staff_access');

  testWidgets('public web build hides the staff link (no /login route)', (
    tester,
  ) async {
    await pumpFooter(tester, staffPortals: false);
    expect(find.text(staffAccess), findsNothing);
    expect(find.text(AppLocalizations('es').get('contact')), findsOneWidget);
  });

  testWidgets('builds with staff portals show the staff link', (tester) async {
    await pumpFooter(tester, staffPortals: true);
    expect(find.text(staffAccess), findsOneWidget);
  });
}

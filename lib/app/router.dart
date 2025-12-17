import 'package:barberia/common/widgets/scaffold_with_nav_bar.dart';
import 'package:barberia/features/booking/pages/calendar_page.dart';
import 'package:barberia/features/booking/pages/confirmation_page.dart';
import 'package:barberia/features/booking/pages/details_page.dart';
import 'package:barberia/features/booking/pages/home_page.dart';
import 'package:barberia/features/booking/pages/my_bookings_page.dart';
import 'package:barberia/features/booking/pages/service_select_page.dart';
import 'package:barberia/features/booking/pages/settings_page.dart';
import 'package:barberia/features/static/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Nombres centralizados de rutas para evitar strings mágicos.
abstract final class RouteNames {
  static const String home = 'home';
  static const String services = 'services';
  static const String calendar = 'calendar';
  static const String details = 'details';
  static const String confirmation = 'confirmation';
  static const String myBookings = 'my-bookings';
  static const String privacy = 'privacy';
}

/// Configuración central de rutas para el flujo de reservas del cliente.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder:
          (
            final BuildContext context,
            final GoRouterState state,
            final StatefulNavigationShell navigationShell,
          ) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
      branches: <StatefulShellBranch>[
        // Branch Home
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              name: RouteNames.home,
              builder: (_, __) => const HomePage(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'services',
                  name: RouteNames.services,
                  builder: (_, __) => const ServiceSelectPage(),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'calendar',
                      name: RouteNames.calendar,
                      builder: (_, __) => const CalendarPage(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'details',
                  name: RouteNames.details,
                  builder: (_, __) => const DetailsPage(),
                ),
                GoRoute(
                  path: 'confirmation',
                  name: RouteNames.confirmation,
                  builder: (_, __) => const ConfirmationPage(),
                ),
                GoRoute(
                  path: 'privacy',
                  name: RouteNames.privacy,
                  builder: (_, __) => const PrivacyPage(),
                ),
              ],
            ),
          ],
        ),

        // Branch My Bookings
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/my-bookings',
              name: RouteNames.myBookings,
              builder: (_, __) => const MyBookingsPage(),
            ),
          ],
        ),

        // Branch Settings (Placeholder)
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/settings',
              name: 'settings', // Add to RouteNames later if needed
              builder: (_, __) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

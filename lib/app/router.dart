import 'package:barberia/features/auth/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/common/widgets/scaffold_with_nav_bar.dart';
import 'package:barberia/features/booking/pages/calendar_page.dart';
import 'package:barberia/features/booking/pages/confirmation_page.dart';
import 'package:barberia/features/booking/pages/details_page.dart';
import 'package:barberia/features/booking/pages/home_page.dart';
import 'package:barberia/features/booking/pages/my_bookings_page.dart';
import 'package:barberia/features/booking/pages/profile_page.dart';
import 'package:barberia/features/booking/pages/service_select_page.dart';
import 'package:barberia/features/booking/pages/settings_page.dart';
import 'package:barberia/features/auth/pages/login_page.dart';
import 'package:barberia/features/auth/pages/register_page.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/admin/pages/admin_dashboard_page.dart';
import 'package:barberia/features/static/privacy_page.dart';

abstract final class RouteNames {
  static const String home = 'home';
  static const String services = 'services';
  static const String calendar = 'calendar';
  static const String details = 'details';
  static const String confirmation = 'confirmation';
  static const String myBookings = 'my-bookings';
  static const String privacy = 'privacy';
  static const String profile = 'profile';
  static const String login = 'login';
  static const String register = 'register';
  static const String admin = 'admin';
}

final Provider<GoRouter> goRouterProvider = Provider<GoRouter>((Ref ref) {
  final User? authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: ValueNotifier(authState), // Simple refresh trigger
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authState != null;
      final bool loggingIn =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (!loggedIn) {
        if (!loggingIn) {
          return '/login';
        }
      } else {
        if (loggingIn) {
          if (authState.role == UserRole.admin) {
            return '/admin';
          }
          return '/';
        }
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (_, __) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
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

          // Branch Settings
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),

          // Branch Profile
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      // Admin Routes
      GoRoute(
        path: '/admin',
        name: RouteNames.admin,
        builder: (_, __) => const AdminDashboardPage(),
      ),
    ],
  );
});

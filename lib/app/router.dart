import 'package:barberia/features/auth/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/common/widgets/scaffold_with_nav_bar.dart';
import 'package:barberia/features/booking/pages/barber_select_page.dart';
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
import 'package:barberia/features/gallery/models/hair_style.dart';
import 'package:barberia/features/gallery/pages/custom_cut_personalizer_page.dart';
import 'package:barberia/features/gallery/pages/gallery_page.dart';
import 'package:barberia/features/static/privacy_page.dart';

abstract final class RouteNames {
  static const String home = 'home';
  static const String services = 'services';
  static const String barberSelect = 'barber-select';
  static const String calendar = 'calendar';
  static const String details = 'details';
  static const String confirmation = 'confirmation';
  static const String myBookings = 'my-bookings';
  static const String privacy = 'privacy';
  static const String profile = 'profile';
  static const String login = 'login';
  static const String register = 'register';
  static const String admin = 'admin';
  static const String gallery = 'gallery';
  static const String personalize = 'personalize';
}

final Provider<GoRouter> goRouterProvider = Provider<GoRouter>((Ref ref) {
  final User? authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: ValueNotifier(authState), // Simple refresh trigger
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authState != null;
      final String path = state.uri.path;
      final bool isLoginPage = path == '/login';
      final bool isRegisterPage = path == '/register';
      final bool isAuthRoute = isLoginPage || isRegisterPage;
      final bool isAdminPath = path.startsWith('/admin');
      // Creating a custom haircut requires an account.
      final bool isPersonalizePath = path.endsWith('/personalize');

      // Handle unauthenticated users
      if (!loggedIn) {
        if (isAuthRoute) {
          return null;
        }
        if (isAdminPath || isPersonalizePath) {
          final String from = Uri.encodeComponent(state.uri.toString());
          return '/login?from=$from';
        }
        // Everyone can browse and book without an account.
        return null;
      }

      // Handle authenticated users
      final bool isAdmin = authState.role == UserRole.admin;

      if (isAuthRoute) {
        if (isAdmin) {
          return '/admin';
        }
        final String? from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty && !from.startsWith('/admin')) {
          return from;
        }
        return '/';
      }

      if (isAdmin && !isAdminPath) {
        return '/admin'; // Force admin to admin section
      }

      if (!isAdmin && isAdminPath) {
        return '/'; // Block client from admin section
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
                        path: 'barber',
                        name: RouteNames.barberSelect,
                        builder: (_, __) => const BarberSelectPage(),
                      ),
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
                  GoRoute(
                    path: 'gallery',
                    name: RouteNames.gallery,
                    builder: (_, __) => const GalleryPage(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'personalize',
                        name: RouteNames.personalize,
                        builder: (_, final GoRouterState state) =>
                            CustomCutPersonalizerPage(
                              initialStyle: state.extra as HairStyle?,
                            ),
                      ),
                    ],
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

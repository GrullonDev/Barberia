import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/common/widgets/scaffold_with_nav_bar.dart';
import 'package:barberia/features/admin/pages/add_edit_service_page.dart';
import 'package:barberia/features/admin/pages/admin_config_page.dart';
import 'package:barberia/features/admin/pages/admin_dashboard_page.dart';
import 'package:barberia/features/admin/pages/all_bookings_page.dart';
import 'package:barberia/features/admin/pages/manage_barbers_page.dart';
import 'package:barberia/features/admin/pages/manage_services_page.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/pages/login_page.dart';
import 'package:barberia/features/auth/pages/password_reset_page.dart';
import 'package:barberia/features/auth/pages/phone_login_page.dart';
import 'package:barberia/features/auth/pages/profile_page.dart';
import 'package:barberia/features/auth/pages/register_page.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/pages/calendar_page.dart';
import 'package:barberia/features/booking/pages/confirmation_page.dart';
import 'package:barberia/features/booking/pages/details_page.dart';
import 'package:barberia/features/booking/pages/home_page.dart';
import 'package:barberia/features/booking/pages/my_bookings_page.dart';
import 'package:barberia/features/booking/pages/service_select_page.dart';
import 'package:barberia/features/booking/pages/settings_page.dart';
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
  static const String passwordReset = 'password-reset';
  static const String phoneLogin = 'phone-login';
  static const String splash = 'splash';
  static const String admin = 'admin';
  static const String manageServices = 'manage-services';
  static const String manageBarbers = 'manage-barbers';
  static const String allBookings = 'all-bookings';
  static const String addService = 'add-service';
  static const String adminConfig = 'admin-config';
}

/// Rutas públicas que un usuario anónimo o un cliente sin cuenta pueden
/// navegar en web para reservar. En mobile el cliente siempre necesita
/// alguna forma de sesión (email/pass o phone OTP).
const Set<String> _publicWebPaths = <String>{
  '/',
  '/services',
  '/services/calendar',
  '/details',
  '/confirmation',
  '/privacy',
  '/login',
  '/register',
  '/password-reset',
  '/phone-login',
};

final Provider<GoRouter> goRouterProvider = Provider<GoRouter>((Ref ref) {
  final User? authState = ref.watch(authStateProvider);
  final AuthBootstrap bootstrap = ref.watch(authBootstrapProvider);

  return GoRouter(
    initialLocation: '/',
    // Dispara un rebuild cuando cambia auth o bootstrap.
    refreshListenable: ValueNotifier<Object?>(Object.hash(authState, bootstrap)),
    redirect: (BuildContext context, GoRouterState state) {
      // Mientras Firebase rehidrata la sesión, no redirigimos — la UI
      // debe mostrar splash. Evita el flash hacia /login en cold start.
      if (bootstrap == AuthBootstrap.loading) {
        return state.uri.path == '/splash' ? null : '/splash';
      }

      final bool loggedIn = authState != null;
      final bool isAnon = authState?.isAnonymous ?? false;
      final String path = state.uri.path;
      final bool isAuthRoute = path == '/login' ||
          path == '/register' ||
          path == '/password-reset' ||
          path == '/phone-login';
      final bool isSplash = path == '/splash';

      // Si ya salimos del bootstrap, nadie se queda en splash.
      if (isSplash) {
        return loggedIn ? '/' : '/login';
      }

      // Sin sesión → solo páginas públicas (en mobile: solo auth routes).
      if (!loggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Usuario anónimo (solo web): puede navegar flow de reserva público,
      // pero no accede a /admin ni /my-bookings ni /profile (sin identidad).
      if (isAnon) {
        final bool isPublic = _publicWebPaths.contains(path);
        if (!isPublic) return '/';
        return null;
      }

      // Usuario con cuenta → flujo normal.
      final bool hasAdminAccess =
          authState.role == UserRole.admin || authState.role == UserRole.barber;
      final bool isAdminPath = path.startsWith('/admin');

      if (isAuthRoute) {
        return hasAdminAccess ? '/admin' : '/';
      }
      if (hasAdminAccess && !isAdminPath && path == '/') {
        return '/admin';
      }
      if (!hasAdminAccess && isAdminPath) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, __) => const _SplashScreen(),
      ),
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
      GoRoute(
        path: '/password-reset',
        name: RouteNames.passwordReset,
        builder: (_, __) => const PasswordResetPage(),
      ),
      GoRoute(
        path: '/phone-login',
        name: RouteNames.phoneLogin,
        builder: (_, __) => const PhoneLoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
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
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/my-bookings',
                name: RouteNames.myBookings,
                builder: (_, __) => const MyBookingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
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
      GoRoute(
        path: '/admin',
        name: RouteNames.admin,
        builder: (_, __) => const AdminDashboardPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'services',
            name: RouteNames.manageServices,
            builder: (_, __) => const ManageServicesPage(),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                name: RouteNames.addService,
                builder: (BuildContext context, GoRouterState state) =>
                    AddEditServicePage(service: state.extra as Service?),
              ),
            ],
          ),
          GoRoute(
            path: 'barbers',
            name: RouteNames.manageBarbers,
            builder: (_, __) => const ManageBarbersPage(),
          ),
          GoRoute(
            path: 'bookings',
            name: RouteNames.allBookings,
            builder: (_, __) => const AllBookingsPage(),
          ),
          GoRoute(
            path: 'config',
            name: RouteNames.adminConfig,
            builder: (_, __) => const AdminConfigPage(),
          ),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.content_cut, size: 64),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

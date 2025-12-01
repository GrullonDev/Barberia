import 'package:barberia/features/booking/pages/add_service_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/booking/pages/pages.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/providers/auth_providers.dart';

/// Nombres centralizados de rutas para evitar strings mágicos.
abstract final class RouteNames {
  static const String home = 'home';
  static const String services = 'services';
  static const String calendar = 'calendar';
  static const String details = 'details';
  static const String confirmation = 'confirmation';
  static const String myBookings = 'my-bookings';
  static const String privacy = 'privacy';
  static const String addService = 'add-service';
  static const String login = 'login';
  static const String register = 'register';
}

/// Configuración central de rutas para el flujo de reservas del cliente.
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final ref = ProviderScope.containerOf(context);
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isSignedIn;

    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';

    if (!isAuthenticated && !isLoggingIn && !isRegistering) {
      return '/login';
    }

    if (isAuthenticated && (isLoggingIn || isRegistering)) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: RouteNames.home,
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: '/services',
      name: RouteNames.services,
      builder: (_, __) => const ServiceSelectPage(),
    ),
    GoRoute(
      path: '/calendar',
      name: RouteNames.calendar,
      builder: (_, __) => const CalendarPage(),
    ),
    GoRoute(
      path: '/details',
      name: RouteNames.details,
      builder: (_, __) => const DetailsPage(),
    ),
    GoRoute(
      path: '/confirmation',
      name: RouteNames.confirmation,
      builder: (_, __) => const ConfirmationPage(),
    ),
    GoRoute(
      path: '/my-bookings',
      name: RouteNames.myBookings,
      builder: (_, __) => const MyBookingsPage(),
    ),
    GoRoute(
      path: '/privacy',
      name: RouteNames.privacy,
      builder: (_, __) => const PrivacyPage(),
    ),
    GoRoute(
      path: '/add-service',
      name: RouteNames.addService,
      builder: (_, __) => const AddServicePage(),
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
  ],
);


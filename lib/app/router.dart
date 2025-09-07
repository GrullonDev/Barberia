import 'package:go_router/go_router.dart';

import '../features/booking/pages/pages.dart';

/// Nombres centralizados de rutas para evitar strings mágicos.
abstract final class RouteNames {
  static const String home = 'home';
  static const String services = 'services';
  static const String calendar = 'calendar';
  static const String details = 'details';
  static const String confirmation = 'confirmation';
  static const String myBookings = 'my-bookings';
}

/// Configuración central de rutas para el flujo de reservas del cliente.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
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
  ],
);

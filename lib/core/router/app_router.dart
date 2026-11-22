import 'package:flutter/foundation.dart';
import 'package:barberia/features/admin/presentation/pages/admin_portal_page.dart';
import 'package:barberia/features/auth/presentation/pages/barber_password_change_page.dart';
import 'package:barberia/features/auth/presentation/pages/staff_login_page.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:barberia/features/barbers/presentation/pages/barber_portal_page.dart';
import 'package:barberia/features/booking/presentation/pages/booking_page.dart';
import 'package:barberia/features/gallery/presentation/pages/gallery_page.dart';
import 'package:barberia/features/home/presentation/pages/home_page.dart';
import 'package:barberia/features/membership/presentation/pages/membership_page.dart';
import 'package:barberia/features/personalizer/presentation/pages/custom_cut_personalizer_page.dart';
import 'package:barberia/features/services/presentation/pages/services_page.dart';
import 'package:barberia/core/platform/platform_capabilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Rutas del flujo público de reservas (cliente). Mientras los portales de
// staff no estén habilitados en web (ver PlatformCapabilities y
// docs/ESTRATEGIA_PLATAFORMAS.md), es lo único que existe en el bundle Web.
// `currentShopIdProvider` resuelve el shop activo a partir del SHOP_ID
// compilado cuando no hay staff autenticado.
final _clientRoutes = <RouteBase>[
  GoRoute(path: '/', builder: (_, __) => const HomePage()),
  GoRoute(path: '/gallery', builder: (_, __) => const GalleryPage()),
  GoRoute(
    path: '/personalizer',
    builder: (_, __) => const CustomCutPersonalizerPage(),
  ),
  GoRoute(path: '/booking', builder: (_, __) => const BookingPage()),
  GoRoute(path: '/barbers', redirect: (_, __) => '/booking'),
  GoRoute(path: '/membership', builder: (_, __) => const MembershipPage()),
  GoRoute(path: '/services', builder: (_, __) => const ServicesPage()),
];

final platformCapabilitiesProvider = Provider<PlatformCapabilities>(
  (_) => PlatformCapabilities.current,
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final capabilities = ref.watch(platformCapabilitiesProvider);
  if (!capabilities.staffPortalsEnabled) {
    return GoRouter(
      initialLocation: capabilities.initialLocation,
      routes: _clientRoutes,
    );
  }

  // One router for the app's lifetime. Rebuilding it whenever auth changes
  // (ref.watch) restarted navigation at initialLocation, which on web is '/',
  // so signing in dropped staff on the public home page instead of their
  // portal. Auth changes now only re-run the redirect.
  final authChanges = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => authChanges.value++);
  final router = GoRouter(
    initialLocation: capabilities.initialLocation,
    refreshListenable: authChanges,
    redirect: (context, state) =>
        staffRedirect(ref.read(authProvider), state.matchedLocation),
    routes: [
      ..._clientRoutes,
      GoRoute(path: '/login', builder: (_, __) => const StaffLoginPage()),
      GoRoute(
        path: '/barber/change-password',
        builder: (_, __) => const BarberPasswordChangePage(),
      ),
      GoRoute(
        path: '/barber/portal',
        builder: (_, __) => const BarberPortalPage(),
      ),
      GoRoute(
        path: '/admin/portal',
        builder: (_, __) => const AdminPortalPage(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
});

/// Where staff navigation must go for [auth] at [location]; null to stay.
@visibleForTesting
String? staffRedirect(AuthState auth, String location) {
  final isAuthenticated = auth.isAuthenticated;
  final isLoginRoute = location == '/login';
  final isBarberRoute = location.startsWith('/barber');
  final isAdminRoute = location.startsWith('/admin');
  final isPasswordChangeRoute = location == '/barber/change-password';
  final isPortalRoute = isBarberRoute || isAdminRoute;

  // Unauthenticated user trying to reach a protected route
  if (!isAuthenticated && isPortalRoute) return '/login';

  // Authenticated staff landing on /login -> send to their required next step
  if (isAuthenticated && isLoginRoute) {
    if (auth.role == UserRole.barber && auth.mustChangePassword) {
      return '/barber/change-password';
    }
    return auth.role == UserRole.admin ? '/admin/portal' : '/barber/portal';
  }

  if (isAuthenticated &&
      auth.role == UserRole.barber &&
      auth.mustChangePassword &&
      !isPasswordChangeRoute) {
    return '/barber/change-password';
  }

  if (isAuthenticated &&
      auth.role == UserRole.barber &&
      !auth.mustChangePassword &&
      isPasswordChangeRoute) {
    return '/barber/portal';
  }

  // Role mismatch redirection
  if (isAuthenticated) {
    if (auth.role == UserRole.admin && isBarberRoute) {
      return '/admin/portal';
    }
    if (auth.role == UserRole.barber && isAdminRoute) {
      return '/barber/portal';
    }
  }

  return null;
}

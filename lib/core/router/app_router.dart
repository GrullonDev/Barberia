import 'package:barberia/features/admin/presentation/pages/admin_portal_page.dart';
import 'package:barberia/features/auth/presentation/pages/staff_login_page.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:barberia/features/barbers/presentation/pages/barber_portal_page.dart';
import 'package:barberia/features/barbers/presentation/pages/barbers_page.dart';
import 'package:barberia/features/booking/presentation/pages/booking_page.dart';
import 'package:barberia/features/gallery/presentation/pages/gallery_page.dart';
import 'package:barberia/features/home/presentation/pages/home_page.dart';
import 'package:barberia/features/membership/presentation/pages/membership_page.dart';
import 'package:barberia/features/personalizer/presentation/pages/custom_cut_personalizer_page.dart';
import 'package:barberia/features/services/presentation/pages/services_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation:
        (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.android))
        ? '/login'
        : '/',
    redirect: (context, state) {
      final isAuthenticated = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isBarberRoute = state.matchedLocation.startsWith('/barber');
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      final isPortalRoute = isBarberRoute || isAdminRoute;

      // Unauthenticated user trying to reach a protected route
      if (!isAuthenticated && isPortalRoute) return '/login';

      // Authenticated staff landing on /login → send to their portal
      if (isAuthenticated && isLoginRoute) {
        return auth.role == UserRole.admin ? '/admin/portal' : '/barber/portal';
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
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/gallery', builder: (_, __) => const GalleryPage()),
      GoRoute(
        path: '/personalizer',
        builder: (_, __) => const CustomCutPersonalizerPage(),
      ),
      GoRoute(path: '/booking', builder: (_, __) => const BookingPage()),
      GoRoute(path: '/barbers', builder: (_, __) => const BarbersPage()),
      GoRoute(path: '/membership', builder: (_, __) => const MembershipPage()),
      GoRoute(path: '/services', builder: (_, __) => const ServicesPage()),
      GoRoute(path: '/login', builder: (_, __) => const StaffLoginPage()),
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
});


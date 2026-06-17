import 'package:barberia/features/booking/presentation/pages/booking_page.dart';
import 'package:barberia/features/gallery/presentation/pages/gallery_page.dart';
import 'package:barberia/features/home/presentation/pages/home_page.dart';
import 'package:barberia/features/personalizer/presentation/pages/custom_cut_personalizer_page.dart';
import 'package:barberia/features/barbers/presentation/pages/barbers_page.dart';
import 'package:barberia/features/membership/presentation/pages/membership_page.dart';
import 'package:barberia/features/services/presentation/pages/services_page.dart';
import 'package:barberia/features/auth/presentation/pages/staff_login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
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
    ],
  ),
);

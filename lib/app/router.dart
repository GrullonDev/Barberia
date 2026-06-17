import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/personalizer/presentation/pages/custom_cut_personalizer_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/personalizer',
      builder: (context, state) => const CustomCutPersonalizerPage(),
    ),
  ],
);

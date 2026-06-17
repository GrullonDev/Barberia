import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/features/home/presentation/widgets/cta_banner_section.dart';
import 'package:barberia/features/home/presentation/widgets/gallery_section.dart';
import 'package:barberia/features/home/presentation/widgets/hero_section.dart';
import 'package:barberia/features/home/presentation/widgets/home_footer.dart';
import 'package:barberia/features/home/presentation/widgets/home_nav_bar.dart';
import 'package:barberia/features/home/presentation/widgets/services_section.dart';
import 'package:barberia/features/home/presentation/widgets/why_us_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const _MobileDrawer(),
      body: Column(
        children: [
          HomeNavBar(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroSection(),
                  ServicesSection(),
                  GallerySection(),
                  WhyUsSection(),
                  CtaBannerSection(),
                  HomeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LUXE & BLADE', style: AppTextStyles.headlineSm),
              const SizedBox(height: 40),
              ...HomeNavBar.navItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final route = HomeNavBar.navRoutes[item];
                      if (route != null) {
                        context.go(route);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(item, style: AppTextStyles.bodyLg),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                ),
                child: Text('RESERVAR CITA', style: AppTextStyles.labelMd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

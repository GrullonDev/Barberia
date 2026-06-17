import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';

class HomeNavBar extends StatelessWidget {
  const HomeNavBar({required this.onMenuTap, this.activePage, super.key});

  final VoidCallback onMenuTap;
  final String? activePage;

  static const navItems = ['Services', 'Gallery', 'Barbers', 'Membership'];
  static const navRoutes = <String, String>{
    'Services': '/services',
    'Gallery': '/gallery',
    'Barbers': '/barbers',
    'Membership': '/membership',
  };
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          height: height,
          color: AppColors.surfaceContainerLowest,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
          ),
          child: isMobile ? _buildMobile() : _buildDesktop(),
        );
      },
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        const _Logo(),
        const Spacer(),
        ...navItems.map(
          (item) => _NavLink(
            label: item,
            route: navRoutes[item],
            isActive: item == activePage,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        const _CtaButton(),
      ],
    );
  }

  Widget _buildMobile() {
    return Row(
      children: [
        const _Logo(),
        const Spacer(),
        IconButton(
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu, color: AppColors.onSurface, size: 28),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: Text(
        'LUXE & BLADE',
        style: AppTextStyles.headlineSm.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12 * 18,
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, this.route, this.isActive = false});

  final String label;
  final String? route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TextButton(
        onPressed: route != null ? () => context.go(route!) : () {},
        style: TextButton.styleFrom(
          foregroundColor: isActive
              ? AppColors.secondary
              : AppColors.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: isActive
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              height: 2,
              width: 20,
              color: isActive ? AppColors.secondary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.go('/personalizer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 4,
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(
        'BOOK APPOINTMENT',
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.onSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08 * 14,
        ),
      ),
    );
  }
}

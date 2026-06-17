import 'package:flutter/material.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/features/home/presentation/widgets/home_nav_bar.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    // sizeOf only rebuilds on size change, not on every MediaQuery mutation
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < Breakpoints.tablet;

    return SizedBox(
      height: size.height - HomeNavBar.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroBackground(isMobile: isMobile),
          _HeroOverlay(isMobile: isMobile),
          _HeroContent(isMobile: isMobile),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/hero_bg.jpg',
      fit: BoxFit.cover,
      alignment: isMobile ? Alignment.center : Alignment.centerRight,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceContainerLow,
        child: const Center(
          child: Icon(
            Icons.content_cut,
            size: 120,
            color: AppColors.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _HeroOverlay extends StatelessWidget {
  const _HeroOverlay({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isMobile
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withAlpha(128),
                  AppColors.background.withAlpha(235),
                ],
              )
            : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background,
                  AppColors.background.withAlpha(242),
                  AppColors.background.withAlpha(153),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.55, 0.75],
              ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? AppSpacing.marginMobile
            : AppSpacing.marginDesktop,
      ),
      child: Align(
        alignment: isMobile ? Alignment.bottomCenter : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: isMobile ? AppSpacing.xxl : 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 560,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isMobile
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'Maestría en cada corte,\nestilo en cada detalle',
                  style: AppTextStyles.headlineLg(mobile: isMobile),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Redefinimos la experiencia del cuidado masculino con técnicas '
                  'tradicionales y un ambiente diseñado para el caballero moderno.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                ),
                const SizedBox(height: AppSpacing.xl),
                _HeroButtons(isMobile: isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroButtons extends StatelessWidget {
  const _HeroButtons({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final primary = ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusSm,
        ),
      ),
      child: Text(
        'RESERVAR CITA',
        style: AppTextStyles.labelMd.copyWith(color: AppColors.onSecondary),
      ),
    );

    final secondary = OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.onSurface, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusSm,
        ),
      ),
      child: Text('NUESTROS SERVICIOS', style: AppTextStyles.labelMd),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          const SizedBox(height: AppSpacing.md),
          secondary,
        ],
      );
    }

    return Row(
      children: [
        primary,
        const SizedBox(width: AppSpacing.md),
        secondary,
      ],
    );
  }
}

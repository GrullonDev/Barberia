import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:go_router/go_router.dart';

class CtaBannerSection extends ConsumerWidget {
  const CtaBannerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.secondary,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 64 : 96,
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Text(
                    l10n.get('elevate_style_title'),
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.onSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.get('elevate_style_desc'),
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSecondary.withAlpha(204),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => context.go('/booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.onSecondary,
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.md,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderRadiusSm,
                      ),
                    ),
                    child: Text(
                      l10n.get('book_now'),
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

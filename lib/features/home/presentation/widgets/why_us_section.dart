import 'package:barberia/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/core/providers/config_provider.dart';

class WhyUsSection extends ConsumerWidget {
  const WhyUsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.background,
          padding: EdgeInsets.symmetric(
            vertical: 96,
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('why_choose_us'),
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      l10n.get('why_choose_us_desc'),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  isMobile ? _buildMobile(l10n) : _buildDesktop(l10n),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktop(AppLocalizations l10n) {
    return SizedBox(
      height: 440,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _LargeFeatureCard(
              icon: Icons.emoji_events_outlined,
              title: l10n.get('traditional_experience'),
              description: l10n.get('traditional_experience_desc'),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: _SmallFeatureCard(
                    icon: Icons.local_cafe_outlined,
                    title: l10n.get('luxury_atmosphere').toUpperCase(),
                    description: l10n.get('luxury_atmosphere_desc'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _SmallFeatureCard(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.get('premium_products').toUpperCase(),
                    description: l10n.get('premium_products_desc'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(AppLocalizations l10n) {
    return Column(
      children: [
        _SmallFeatureCard(
          icon: Icons.local_cafe_outlined,
          title: l10n.get('luxury_atmosphere').toUpperCase(),
          description: l10n.get('luxury_atmosphere_desc'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _LargeFeatureCard(
          icon: Icons.emoji_events_outlined,
          title: l10n.get('traditional_experience'),
          description: l10n.get('traditional_experience_desc'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SmallFeatureCard(
          icon: Icons.inventory_2_outlined,
          title: l10n.get('premium_products').toUpperCase(),
          description: l10n.get('premium_products_desc'),
        ),
      ],
    );
  }
}

// Uses constraints.hasBoundedHeight to decide between Expanded and fixed-height
// image slot — no useExpandedImage parameter needed.
class _LargeFeatureCard extends StatelessWidget {
  const _LargeFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSlot = ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          child: Image.asset(
            'assets/images/why_us_bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppColors.surfaceContainerHigh),
          ),
        );

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.borderRadiusLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expand to fill bounded height (desktop); fixed height on mobile
              constraints.hasBoundedHeight
                  ? Expanded(child: imageSlot)
                  : SizedBox(height: 200, child: imageSlot),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.secondary, size: 28),
                    const SizedBox(height: AppSpacing.md),
                    Text(title, style: AppTextStyles.headlineSm),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallFeatureCard extends StatelessWidget {
  const _SmallFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

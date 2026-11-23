import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/core/providers/config_provider.dart';

class ServicesSection extends ConsumerWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    final services = [
      _ServiceData(
        icon: Icons.content_cut,
        title: l10n.get('service_cut_title'),
        description: l10n.get('service_cut_desc'),
        price: 35.0,
      ),
      _ServiceData(
        icon: Icons.face_retouching_natural,
        title: l10n.get('service_beard_title'),
        description: l10n.get('service_beard_desc'),
        price: 25.0,
      ),
      _ServiceData(
        icon: Icons.spa,
        title: l10n.get('service_facial_title'),
        description: l10n.get('service_facial_desc'),
        price: 46.0,
      ),
    ];

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
                children: [
                  _SectionTitle(title: l10n.get('nuestros_servicios_title')),
                  const SizedBox(height: 56),
                  isMobile
                      ? Column(
                          children: services
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: _ServiceCard(data: s),
                                ),
                              )
                              .toList(),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < services.length; i++) ...[
                              Expanded(child: _ServiceCard(data: services[i])),
                              if (i < services.length - 1)
                                const SizedBox(width: AppSpacing.lg),
                            ],
                          ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: AppTextStyles.headlineMd),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ServiceData {
  const _ServiceData({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
  });

  final IconData icon;
  final String title;
  final String description;
  final double price;
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.data});
  final _ServiceData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final config = ref.watch(appConfigProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: AppColors.secondary, size: 28),
          const SizedBox(height: AppSpacing.xl),
          Text(data.title, style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.description,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${config.currencySymbol}${data.price.toStringAsFixed(0)}',
                style: AppTextStyles.headlineSm.copyWith(fontSize: 20),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.get('details'),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

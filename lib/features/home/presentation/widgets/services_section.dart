import 'package:flutter/material.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  static const _services = [
    _ServiceData(
      icon: Icons.content_cut,
      title: 'Corte de Autor',
      description:
          'Un estudio detallado de tu fisionomía para crear el estilo que mejor proyecte tu personalidad.',
      price: '35€',
    ),
    _ServiceData(
      icon: Icons.face_retouching_natural,
      title: 'Ritual de Barba',
      description:
          'Afeitado tradicional a navaja con toallas calientes y aceites esenciales de sándalo.',
      price: '25€',
    ),
    _ServiceData(
      icon: Icons.spa,
      title: 'Tratamiento Facial',
      description:
          'Exfoliación e hidratación profunda diseñada específicamente para la piel masculina.',
      price: '46€',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                  const _SectionTitle(title: 'Nuestros Servicios'),
                  const SizedBox(height: 56),
                  isMobile
                      ? Column(
                          children: _services
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
                            for (int i = 0; i < _services.length; i++) ...[
                              Expanded(child: _ServiceCard(data: _services[i])),
                              if (i < _services.length - 1)
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
  final String price;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.data});
  final _ServiceData data;

  @override
  Widget build(BuildContext context) {
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
                data.price,
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
                  'DETALLES',
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

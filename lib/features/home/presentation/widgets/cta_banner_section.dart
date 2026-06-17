import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class CtaBannerSection extends StatelessWidget {
  const CtaBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < Breakpoints.tablet;
      return Container(
        color: AppColors.secondary,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 64 : 96,
          horizontal:
              isMobile ? AppSpacing.marginMobile : AppSpacing.marginDesktop,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Text(
                  '¿Listo para elevar tu estilo?',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.onSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Agenda la cita hoy mismo y descubre por qué somos la '
                  'referencia en barbería de lujo.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSecondary.withAlpha(204),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () {},
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
                    'RESERVAR AHORA',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';

class GallerySection extends StatelessWidget {
  const GallerySection({super.key});

  static const _images = [
    'assets/images/gallery_1.jpg',
    'assets/images/gallery_2.jpg',
    'assets/images/gallery_3.jpg',
    'assets/images/gallery_4.jpg',
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GalleryHeader(),
                  SizedBox(height: 40),
                  _GalleryGrid(images: _images),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// No isMobile parameter — reads its own constraints via LayoutBuilder.
class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;

        final portfolioLink = TextButton.icon(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Text(
            'VER PORTAFOLIO COMPLETO',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.secondary),
          ),
          label: const Icon(
            Icons.arrow_forward,
            size: 16,
            color: AppColors.secondary,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Galería de Estilos',
                        style: AppTextStyles.headlineMd,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Una muestra de nuestra dedicación diaria a la precisión '
                        'y el estilo impecable.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: AppSpacing.xl),
                  portfolioLink,
                ],
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: AppSpacing.md),
              portfolioLink,
            ],
          ],
        );
      },
    );
  }
}

// No isMobile parameter — reads its own constraints via LayoutBuilder.
class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            children: images.map((p) => _GalleryImage(path: p)).toList(),
          );
        }

        return SizedBox(
          height: 320,
          child: Row(
            children: [
              for (int i = 0; i < images.length; i++) ...[
                Expanded(child: _GalleryImage(path: images[i])),
                if (i < images.length - 1) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusMd,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceContainerHigh,
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

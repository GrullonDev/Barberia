import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../home/presentation/widgets/home_footer.dart';
import '../../../home/presentation/widgets/home_nav_bar.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _StyleData {
  const _StyleData({
    required this.image,
    required this.badge,
    required this.name,
    required this.description,
    required this.category,
  });

  final String image;
  final String badge;
  final String name;
  final String description;
  final String category;
}

const _styles = <_StyleData>[
  _StyleData(
    image: 'assets/images/gallery_1.jpg',
    badge: 'POPULAR',
    name: 'Modern Fade',
    description:
        'Un degradado impecable que fusiona la piel con una transición suave '
        'hacia un cabello más largo y texturizado en la parte superior.',
    category: 'moderno',
  ),
  _StyleData(
    image: 'assets/images/gallery_2.jpg',
    badge: 'ELEGANTE',
    name: 'Pompadour',
    description:
        'El epítome de la sofisticación. Volumen alto en la parte superior '
        'con un acabado pulido y laterales perfectamente perfilados.',
    category: 'clasico',
  ),
  _StyleData(
    image: 'assets/images/gallery_3.jpg',
    badge: 'MINIMALISTA',
    name: 'Buzz Cut',
    description:
        'Simplicidad y fuerza. Un corte uniforme y preciso que resalta las '
        'facciones del rostro con un perfilado milimétrico.',
    category: 'corto',
  ),
  _StyleData(
    image: 'assets/images/gallery_4.jpg',
    badge: 'CLASSIC',
    name: 'Executive',
    description:
        'El estándar del profesionalismo. Raya lateral marcada y longitud '
        'moderada para un estilo versátil que nunca pasa de moda.',
    category: 'clasico',
  ),
];

const _filterOptions = <(String, String)>[
  ('todos', 'TODOS'),
  ('clasico', 'CLÁSICOS'),
  ('moderno', 'MODERNOS'),
  ('corto', 'CORTOS'),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeFilter = 'todos';

  List<_StyleData> get _filteredStyles => _activeFilter == 'todos'
      ? _styles
      : _styles.where((s) => s.category == _activeFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const _GalleryMobileDrawer(),
      body: Column(
        children: [
          HomeNavBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            activePage: 'Gallery',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GalleryHero(),
                  _FilterSection(
                    activeFilter: _activeFilter,
                    onFilterChanged: (f) => setState(() => _activeFilter = f),
                    filteredStyles: _filteredStyles,
                  ),
                  const _ExclusiveCta(),
                  const HomeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────────────

class _GalleryHero extends StatelessWidget {
  const _GalleryHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < Breakpoints.tablet;
      return Container(
        color: AppColors.background,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 64 : 96,
          horizontal:
              isMobile ? AppSpacing.marginMobile : AppSpacing.marginDesktop,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Text(
                  'Nuestros Estilos de Firma',
                  style: AppTextStyles.headlineLg(mobile: isMobile),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Una selección curada de cortes clásicos y modernos, '
                  'diseñados para el hombre que valora la precisión y el carácter.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Filter section ───────────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.filteredStyles,
  });

  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final List<_StyleData> filteredStyles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < Breakpoints.tablet;
      final hPad = isMobile ? AppSpacing.marginMobile : AppSpacing.marginDesktop;
      return Container(
        color: AppColors.background,
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 80),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.containerMax),
            child: LayoutBuilder(builder: (context, inner) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _FilterTabs(
                    activeFilter: activeFilter,
                    onFilterChanged: onFilterChanged,
                  ),
                  const SizedBox(height: AppSpacing.xxl + AppSpacing.md),
                  _StyleCardsGrid(
                    styles: filteredStyles,
                    availableWidth: inner.maxWidth,
                    isMobile: isMobile,
                  ),
                ],
              );
            }),
          ),
        ),
      );
    });
  }
}

// ─── Filter tabs ──────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: _filterOptions.map(((String, String) opt) {
        final (value, label) = opt;
        return _FilterButton(
          label: label,
          isActive: activeFilter == value,
          onTap: () => onFilterChanged(value),
        );
      }).toList(),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : Colors.transparent,
          border: Border.all(
            color: isActive ? AppColors.secondary : AppColors.outlineVariant,
          ),
          borderRadius: AppRadius.borderRadiusSm,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: isActive ? AppColors.onSecondary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Style cards grid ─────────────────────────────────────────────────────────

class _StyleCardsGrid extends StatelessWidget {
  const _StyleCardsGrid({
    required this.styles,
    required this.availableWidth,
    required this.isMobile,
  });

  final List<_StyleData> styles;
  final double availableWidth;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (styles.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No hay estilos en esta categoría.',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final columns = isMobile ? 1 : (availableWidth >= 900 ? 4 : 2);
    const gap = AppSpacing.md;
    final cardWidth = (availableWidth - gap * (columns - 1)) / columns;

    if (columns == 1) {
      return Column(
        children: [
          for (int i = 0; i < styles.length; i++) ...[
            _StyleCard(style: styles[i]),
            if (i < styles.length - 1) const SizedBox(height: gap),
          ],
        ],
      );
    }

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: styles
          .map((s) => SizedBox(width: cardWidth, child: _StyleCard(style: s)))
          .toList(),
    );
  }
}

// ─── Style card ───────────────────────────────────────────────────────────────

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style});

  final _StyleData style;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: Image.asset(
                  style.image,
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
              ),
              Positioned(
                bottom: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Text(
                    style.badge,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.name,
                  style: AppTextStyles.headlineSm.copyWith(fontSize: 22),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  style.description,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/personalizer'),
                    child: Text(
                      'PERSONALIZAR ESTE ESTILO',
                      style: AppTextStyles.labelMd,
                    ),
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

// ─── Exclusive CTA ────────────────────────────────────────────────────────────

class _ExclusiveCta extends StatelessWidget {
  const _ExclusiveCta();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < Breakpoints.tablet;
      return Container(
        color: AppColors.surfaceContainerLowest,
        padding: EdgeInsets.symmetric(
          vertical: 96,
          horizontal:
              isMobile ? AppSpacing.marginMobile : AppSpacing.marginDesktop,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Text(
                  '¿BUSCAS ALGO EXCLUSIVO?',
                  style: AppTextStyles.headlineMd.copyWith(letterSpacing: 2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Nuestros maestros barberos pueden crear una versión '
                  'personalizada que se adapte perfectamente a tu tipo de '
                  'cabello y estructura facial.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            child: Text(
                              'RESERVA UNA CONSULTA',
                              style: AppTextStyles.labelMd,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: () {},
                            child: Text(
                              'VER PORTAFOLIO COMPLETO',
                              style: AppTextStyles.labelMd,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            child: Text(
                              'RESERVA UNA CONSULTA',
                              style: AppTextStyles.labelMd,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          OutlinedButton(
                            onPressed: () {},
                            child: Text(
                              'VER PORTAFOLIO COMPLETO',
                              style: AppTextStyles.labelMd,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Mobile drawer ────────────────────────────────────────────────────────────

class _GalleryMobileDrawer extends StatelessWidget {
  const _GalleryMobileDrawer();

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
              Text('THE GENTLEMAN', style: AppTextStyles.headlineSm),
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

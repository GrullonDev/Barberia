import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/features/home/presentation/widgets/home_footer.dart';
import 'package:barberia/features/home/presentation/widgets/home_nav_bar.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

typedef _BaseOption = ({String label, IconData icon});

const _baseOptions = <_BaseOption>[
  (label: 'CLASSIC', icon: Icons.content_cut_outlined),
  (label: 'MODERN', icon: Icons.wb_sunny_outlined),
  (label: 'EDGY', icon: Icons.content_cut),
];

const _fadeOptions = ['Low Fade', 'Mid Fade', 'High Fade'];

const _beardOptions = ['Clean Shaven', 'Light Stubble', 'Full Beard', 'Goatee'];

const _baseImages = <String, String>{
  'CLASSIC': 'assets/images/style_executive.png',
  'MODERN': 'assets/images/style_modern_fade.png',
  'EDGY': 'assets/images/style_pompadour.png',
};

// ─── Page ─────────────────────────────────────────────────────────────────────

class CustomCutPersonalizerPage extends StatefulWidget {
  const CustomCutPersonalizerPage({super.key});

  @override
  State<CustomCutPersonalizerPage> createState() =>
      _CustomCutPersonalizerPageState();
}

class _CustomCutPersonalizerPageState extends State<CustomCutPersonalizerPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedBase = 'MODERN';
  double _topLength = 3;
  String _selectedFade = 'Low Fade';
  String _selectedBeard = 'Clean Shaven';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _PersonalizerDrawer(),
      body: Column(
        children: [
          HomeNavBar(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMainSection(),
                  _buildFeaturesSection(),
                  const HomeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main two-column section ────────────────────────────────────────────────

  Widget _buildMainSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.background,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftPanel(isMobile: true),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildRightPanel(isMobile: true),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 420,
                          child: _buildLeftPanel(isMobile: false),
                        ),
                        const SizedBox(width: AppSpacing.xxl),
                        Expanded(child: _buildRightPanel(isMobile: false)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ─── Left panel ─────────────────────────────────────────────────────────────

  Widget _buildLeftPanel({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Custom Cut\nPersonalizer',
          style: AppTextStyles.headlineLg(
            mobile: isMobile,
          ).copyWith(color: AppColors.secondary, height: 1.1),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Define your legacy with a precision-tailored grooming experience. '
          'Select your signature elements below.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _SectionLabel(text: 'CHOOSE YOUR BASE'),
        const SizedBox(height: AppSpacing.md),
        _buildBaseSelector(),
        const SizedBox(height: AppSpacing.xl),
        _buildTopLengthSlider(),
        const SizedBox(height: AppSpacing.xl),
        const _SectionLabel(text: 'TIPO DE DEGRADADO'),
        const SizedBox(height: AppSpacing.md),
        _buildFadeSelector(),
        const SizedBox(height: AppSpacing.xl),
        const _SectionLabel(text: 'DETALLE DE BARBA'),
        const SizedBox(height: AppSpacing.md),
        _buildBeardDropdown(),
      ],
    );
  }

  Widget _buildBaseSelector() {
    return Row(
      children: List.generate(_baseOptions.length, (i) {
        final opt = _baseOptions[i];
        final isSelected = _selectedBase == opt.label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i < _baseOptions.length - 1 ? AppSpacing.sm : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedBase = opt.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surfaceContainerHigh
                      : AppColors.surfaceContainerLow,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      opt.label,
                      style: AppTextStyles.labelSm.copyWith(
                        color: isSelected
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopLengthSlider() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LARGO DE ARRIBA',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08 * 12,
                ),
              ),
              Text(
                '${_topLength.toStringAsFixed(0)} cm',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.secondary,
              inactiveTrackColor: AppColors.outlineVariant,
              thumbColor: AppColors.secondary,
              overlayColor: AppColors.secondary.withValues(alpha: 0.15),
              trackHeight: 2,
            ),
            child: Slider(
              value: _topLength,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _topLength = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Corto',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Largo',
                  style: AppTextStyles.labelSm.copyWith(
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

  Widget _buildFadeSelector() {
    return Column(
      children: _fadeOptions.map((fade) {
        final isSelected = _selectedFade == fade;
        return GestureDetector(
          onTap: () => setState(() => _selectedFade = fade),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border.all(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fade, style: AppTextStyles.bodyMd),
                _RadioDot(selected: isSelected),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBeardDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.zero,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBeard,
          dropdownColor: AppColors.surfaceContainerHigh,
          style: AppTextStyles.bodyMd,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.onSurfaceVariant,
          ),
          isExpanded: true,
          items: _beardOptions
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: AppTextStyles.bodyMd),
                ),
              )
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedBeard = v ?? _selectedBeard),
        ),
      ),
    );
  }

  // ─── Right panel ─────────────────────────────────────────────────────────────

  Widget _buildRightPanel({required bool isMobile}) {
    final image =
        _baseImages[_selectedBase] ?? 'assets/images/style_modern_fade.png';
    final fadeBadge = _selectedFade.replaceAll(' ', '-');

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: isMobile ? 4 / 3 : 3 / 4,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
          // Style badges
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StyleBadge(label: 'STYLE', value: _selectedBase),
                const SizedBox(height: AppSpacing.xs),
                _StyleBadge(label: 'FADE', value: fadeBadge),
              ],
            ),
          ),
          // Bottom CTA card
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0F0F).withValues(alpha: 0.85),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tu Estilo\nGentleman',
                          style: AppTextStyles.headlineSm.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: const Color(0xFFE2E2E2),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Signature Precision Cut & Grooming',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => context.go('/booking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md + 4,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      'CONFIRMAR Y\nAGENDAR',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08 * 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Features section ────────────────────────────────────────────────────────

  Widget _buildFeaturesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.surfaceContainerLowest,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: isMobile
                  ? const Column(
                      children: [
                        _FeatureCard(
                          icon: Icons.verified_outlined,
                          title: 'Prestigio & Precisión',
                          subtitle:
                              'Nuestros barberos maestros aseguran que cada '
                              'milímetro de tu elección se ejecute con excelencia técnica.',
                          serifTitle: true,
                        ),
                        SizedBox(height: AppSpacing.md),
                        _FeatureCard(
                          icon: Icons.schedule,
                          title: '45 MINUTOS',
                          subtitle: 'Dedicación completa',
                          centered: true,
                        ),
                        SizedBox(height: AppSpacing.md),
                        _FeatureCard(
                          icon: Icons.local_cafe_outlined,
                          title: 'COMPLIMENTARY',
                          subtitle: 'Single malt o café artesanal',
                          centered: true,
                        ),
                      ],
                    )
                  : const IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.verified_outlined,
                              title: 'Prestigio & Precisión',
                              subtitle:
                                  'Nuestros barberos maestros aseguran que cada '
                                  'milímetro de tu elección se ejecute con excelencia técnica.',
                              serifTitle: true,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.schedule,
                              title: '45 MINUTOS',
                              subtitle: 'Dedicación completa',
                              centered: true,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.local_cafe_outlined,
                              title: 'COMPLIMENTARY',
                              subtitle: 'Single malt o café artesanal',
                              centered: true,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelSm.copyWith(
        color: AppColors.secondary,
        letterSpacing: 0.1 * 12,
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
            )
          : null,
    );
  }
}

class _StyleBadge extends StatelessWidget {
  const _StyleBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F0F).withValues(alpha: 0.85),
        border: const Border(
          right: BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: const Color(0xFFE2E2E2),
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.12 * 10,
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 12, width: 1.5, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.serifTitle = false,
    this.centered = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool serifTitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (centered) ...[
            Icon(icon, color: AppColors.secondary, size: 32),
            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                icon,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: serifTitle
                ? AppTextStyles.headlineSm.copyWith(
                    fontSize: 22,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  )
                : AppTextStyles.labelMd.copyWith(
                    fontSize: 14,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08 * 14,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile drawer ────────────────────────────────────────────────────────────

class _PersonalizerDrawer extends StatelessWidget {
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

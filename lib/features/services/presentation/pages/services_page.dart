import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/features/home/presentation/widgets/home_footer.dart';
import 'package:barberia/features/home/presentation/widgets/home_nav_bar.dart';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:barberia/core/l10n/app_localizations.dart';

class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  static final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const _ServicesDrawer(),
      body: Column(
        children: [
          HomeNavBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            activePage: 'Services',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroSection(context, l10n),
                  _buildHaircutsSection(context, l10n, config),
                  _buildShavesSection(context, l10n, config),
                  _buildSpaSection(context, l10n, config),
                  _buildMembershipCtaSection(context, l10n),
                  const HomeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Section ───────────────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl + 32,
        horizontal: AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F0F),
        image: DecorationImage(
          image: const AssetImage('assets/images/services_hero_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.88),
            BlendMode.dstATop,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                l10n.languageCode == 'es'
                    ? 'EL RITUAL DEL CABALLERO'
                    : 'THE GENTLEMAN\'S RITUAL',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12 * 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.get('barberia_subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLg().copyWith(
                  color: const Color(0xFFE2E2E2),
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(width: 60, height: 2, color: AppColors.secondary),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.get('barberia_hero_text'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Header Helper ──────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 3, height: 28, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: AppTextStyles.headlineSm.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE2E2E2),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            subtitle,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Haircuts & Styling Section ─────────────────────────────────────────────

  Widget _buildHaircutsSection(
    BuildContext context,
    AppLocalizations l10n,
    AppConfigState config,
  ) {
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
              child: Column(
                children: [
                  _buildSectionHeader(
                    title: l10n.languageCode == 'es'
                        ? 'Cortes & Estilizado'
                        : 'Haircuts & Styling',
                    subtitle: l10n.languageCode == 'es'
                        ? 'Siluetas esculpidas con maestría y adaptadas a tu identidad.'
                        : 'Masterfully sculpted silhouettes tailored to your identity.',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  isMobile
                      ? Column(
                          children: [
                            _buildCutCard(
                              title: l10n.get('service_cut_title'),
                              price: '${config.currencySymbol}65',
                              duration: '45 MIN',
                              desc: l10n.get('signature_cut_desc'),
                              l10n: l10n,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _buildCutCard(
                              title: l10n.languageCode == 'es'
                                  ? 'Sesión de Maestro Estilista'
                                  : 'Master Stylist Session',
                              price: '${config.currencySymbol}85',
                              duration: '60 MIN',
                              desc: l10n.get('master_session_desc'),
                              l10n: l10n,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _buildQuoteCard(l10n),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildCutCard(
                                  title: l10n.get('service_cut_title'),
                                  price: '${config.currencySymbol}65',
                                  duration: '45 MIN',
                                  desc: l10n.get('signature_cut_desc'),
                                  l10n: l10n,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(
                                child: _buildCutCard(
                                  title: l10n.languageCode == 'es'
                                      ? 'Sesión de Maestro Estilista'
                                      : 'Master Stylist Session',
                                  price: '${config.currencySymbol}85',
                                  duration: '60 MIN',
                                  desc: l10n.get('master_session_desc'),
                                  l10n: l10n,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(child: _buildQuoteCard(l10n)),
                            ],
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

  Widget _buildCutCard({
    required String title,
    required String price,
    required String duration,
    required String desc,
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl + 4,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: AppTextStyles.headlineLg().copyWith(
                      color: const Color(0xFFE2E2E2),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    duration,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                desc,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Builder(
            builder: (context) {
              return OutlinedButton(
                onPressed: () => context.go('/booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(
                    color: AppColors.secondary,
                    width: 1.5,
                  ),
                  minimumSize: const Size(double.infinity, 44),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                  l10n.get('select_service_pricing'),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.08 * 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: BorderRadius.zero,
        image: const DecorationImage(
          image: AssetImage('assets/images/services_haircut_quote.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        padding: const EdgeInsets.all(AppSpacing.xl + 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              l10n.get('style_quote'),
              style: AppTextStyles.bodyMd.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 18,
                color: const Color(0xFFE2E2E2),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ─── Shaves & Beard Care Section ───────────────────────────────────────────

  Widget _buildShavesSection(
    BuildContext context,
    AppLocalizations l10n,
    AppConfigState config,
  ) {
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
              child: Column(
                children: [
                  _buildSectionHeader(
                    title: l10n.languageCode == 'es'
                        ? 'Afeitados & Cuidado de Barba'
                        : 'Shaves & Beard Care',
                    subtitle: l10n.languageCode == 'es'
                        ? 'El ritual definitivo de calor, acero y botánicos relajantes.'
                        : 'The ultimate ritual of heat, steel, and soothing botanicals.',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  isMobile
                      ? Column(
                          children: [
                            _buildPopularShaveCard(
                              context,
                              l10n,
                              config,
                              isMobile: true,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _buildBeardSculptureCard(l10n, config),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildPopularShaveCard(
                                  context,
                                  l10n,
                                  config,
                                  isMobile: false,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(
                                flex: 1,
                                child: _buildBeardSculptureCard(l10n, config),
                              ),
                            ],
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

  Widget _buildPopularShaveCard(
    BuildContext context,
    AppLocalizations l10n,
    AppConfigState config, {
    required bool isMobile,
  }) {
    final detailsWidget = Padding(
      padding: const EdgeInsets.all(AppSpacing.xl + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    l10n.get('most_popular'),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${config.currencySymbol}55',
                        style: AppTextStyles.headlineLg().copyWith(
                          color: const Color(0xFFE2E2E2),
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '45 MIN',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.languageCode == 'es'
                    ? 'Afeitado Real a Navaja'
                    : 'Royal Straight Razor Shave',
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.get('royal_shave_desc'),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: () => context.go('/booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              elevation: 0,
              minimumSize: const Size(double.infinity, 44),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              l10n.get('book_ritual'),
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSecondary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.08 * 14,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.secondary, width: 1.5),
        borderRadius: BorderRadius.zero,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    'assets/images/services_shave_beard.png',
                    fit: BoxFit.cover,
                  ),
                ),
                detailsWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    'assets/images/services_shave_beard.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(flex: 1, child: detailsWidget),
              ],
            ),
    );
  }

  Widget _buildBeardSculptureCard(
    AppLocalizations l10n,
    AppConfigState config,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl + 4,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${config.currencySymbol}40',
                    style: AppTextStyles.headlineLg().copyWith(
                      color: const Color(0xFFE2E2E2),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '20 MIN',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.languageCode == 'es'
                    ? 'Escultura de Barba'
                    : 'Beard Sculpture',
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.get('beard_sculpture_desc'),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Builder(
            builder: (context) {
              return OutlinedButton(
                onPressed: () => context.go('/booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(
                    color: AppColors.secondary,
                    width: 1.5,
                  ),
                  minimumSize: const Size(double.infinity, 44),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                  l10n.get('select_service_pricing'),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.08 * 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Spa & Extras Section ──────────────────────────────────────────────────

  Widget _buildSpaSection(
    BuildContext context,
    AppLocalizations l10n,
    AppConfigState config,
  ) {
    final List<Map<String, dynamic>> spaServices = [
      {
        'category': l10n.languageCode == 'es' ? 'CUIDADO DE PIEL' : 'SKINCARE',
        'categoryColor': const Color(0xFFC5A880),
        'title': l10n.languageCode == 'es'
            ? 'Mascarilla de Carbón Activado'
            : 'Activated Charcoal Mask',
        'desc': l10n.get('activated_charcoal_desc'),
        'price': '${config.currencySymbol}25',
        'duration': '15 MIN',
      },
      {
        'category': l10n.languageCode == 'es' ? 'RELAJACIÓN' : 'RELAXATION',
        'categoryColor': const Color(0xFFC5A880),
        'title': l10n.languageCode == 'es' ? 'Masaje Capilar' : 'Scalp Massage',
        'desc': l10n.get('scalp_massage_desc'),
        'price': '${config.currencySymbol}30',
        'duration': '15 MIN',
      },
      {
        'category': l10n.languageCode == 'es' ? 'CUIDADO' : 'GROOMING',
        'categoryColor': const Color(0xFFC5A880),
        'title': l10n.languageCode == 'es'
            ? 'Matización de Canas'
            : 'Grey Blending',
        'desc': l10n.get('grey_blending_desc'),
        'price': '${config.currencySymbol}45',
        'duration': '30 MIN',
      },
      {
        'category': l10n.languageCode == 'es' ? 'EL ACABADO' : 'THE FINISH',
        'categoryColor': const Color(0xFFC5A880),
        'title': l10n.languageCode == 'es'
            ? 'Depilación de Nariz & Orejas'
            : 'Nose & Ear Wax',
        'desc': l10n.get('ear_nose_wax_desc'),
        'price': '${config.currencySymbol}20',
        'duration': '10 MIN',
      },
    ];

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
              child: Column(
                children: [
                  _buildSectionHeader(
                    title: l10n.languageCode == 'es'
                        ? 'Spa & Extras'
                        : 'Spa & Extras',
                    subtitle: l10n.languageCode == 'es'
                        ? 'Tratamientos refinados para el caballero exigente.'
                        : 'Refined treatments for the discerning gentleman.',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  isMobile
                      ? Column(
                          children: spaServices.map((service) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xl,
                              ),
                              child: _buildSpaCard(service),
                            );
                          }).toList(),
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: spaServices.map((service) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  child: _buildSpaCard(service),
                                ),
                              );
                            }).toList(),
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

  Widget _buildSpaCard(Map<String, dynamic> service) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service['category'],
                style: AppTextStyles.labelSm.copyWith(
                  color: service['categoryColor'],
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                service['title'],
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                service['desc'],
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                service['price'],
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              Text(
                service['duration'],
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Executive Lounge Membership Section ───────────────────────────────────

  Widget _buildMembershipCtaSection(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.surfaceContainerLowest,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
            vertical: AppSpacing.xxl + 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Text(
                    l10n.languageCode == 'es'
                        ? 'Membresía del Club Ejecutivo'
                        : 'The Executive Lounge Membership',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSm.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE2E2E2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.languageCode == 'es'
                        ? 'Únete a nuestro círculo exclusivo para reservas prioritarias, bebidas de cortesía y una cita permanente que asegura tu distinción.'
                        : 'Join our exclusive circle for priority bookings, complimentary beverages, and a standing appointment that ensures you never have a hair out of place.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCtaButton(
                              context,
                              l10n.languageCode == 'es'
                                  ? 'DESCUBRIR BENEFICIOS'
                                  : 'DISCOVER BENEFITS',
                              true,
                              '/membership',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildCtaButton(
                              context,
                              l10n.languageCode == 'es'
                                  ? 'RESERVAR CITA'
                                  : 'BOOK APPOINTMENT',
                              false,
                              '/booking',
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCtaButton(
                              context,
                              l10n.languageCode == 'es'
                                  ? 'DESCUBRIR BENEFICIOS'
                                  : 'DISCOVER BENEFITS',
                              true,
                              '/membership',
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _buildCtaButton(
                              context,
                              l10n.languageCode == 'es'
                                  ? 'RESERVAR CITA'
                                  : 'BOOK APPOINTMENT',
                              false,
                              '/booking',
                            ),
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

  Widget _buildCtaButton(
    BuildContext context,
    String text,
    bool isSolid,
    String route,
  ) {
    return ElevatedButton(
      onPressed: () => context.go(route),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSolid ? AppColors.secondary : Colors.transparent,
        foregroundColor: isSolid ? AppColors.onSecondary : AppColors.secondary,
        elevation: 0,
        side: isSolid
            ? null
            : const BorderSide(color: AppColors.secondary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md + 4,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelMd.copyWith(
          color: isSolid ? AppColors.onSecondary : AppColors.secondary,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.08 * 14,
        ),
      ),
    );
  }
}

class _ServicesDrawer extends ConsumerWidget {
  const _ServicesDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LUXE & BLADE', style: AppTextStyles.headlineSm),
              const SizedBox(height: 40),
              ...HomeNavBar.navItems.map((item) {
                final label = l10n.get(item.toLowerCase());
                return Padding(
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
                    child: Text(label, style: AppTextStyles.bodyLg),
                  ),
                );
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/booking');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                  l10n.get('book_appointment'),
                  style: AppTextStyles.labelMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

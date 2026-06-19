import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/features/home/presentation/widgets/home_footer.dart';
import 'package:barberia/features/home/presentation/widgets/home_nav_bar.dart';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:barberia/core/l10n/app_localizations.dart';

class MembershipPage extends ConsumerWidget {
  const MembershipPage({super.key});

  static final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const _MembershipDrawer(),
      body: Column(
        children: [
          HomeNavBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            activePage: 'Membership',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroSection(context, l10n),
                  _buildPricingSection(context, l10n, config),
                  _buildBenefitsSection(context, l10n),
                  _buildElevateSection(context, l10n),
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
        vertical: AppSpacing.xxl + 24,
        horizontal: AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F0F),
        image: DecorationImage(
          image: const AssetImage('assets/images/barber_bg_pattern.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.92),
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
                'ESTABLISHED PRESTIGE',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12 * 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.languageCode == 'es'
                    ? 'El Círculo Interno'
                    : 'The Inner Circle',
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
                l10n.languageCode == 'es'
                    ? 'Experimenta la cima del cuidado masculino. Nuestras membresías exclusivas ofrecen más que un corte: brindan un santuario de estilo, acceso prioritario y el máximo lujo del tiempo.'
                    : 'Experience the pinnacle of grooming. Our exclusive memberships offer more than just a cut—they provide a sanctuary of style, priority access, and the ultimate luxury of time.',
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

  // ─── Pricing Section ────────────────────────────────────────────────────────

  Widget _buildPricingSection(
    BuildContext context,
    AppLocalizations l10n,
    AppConfigState config,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        final isSpanish = l10n.languageCode == 'es';

        final essentialBullets = isSpanish
            ? [
                '1 Corte Mensual de Autor',
                '10% de Descuento en Todos los Productos de Venta',
                'Café o Agua de Cortesía',
                'Acceso a Eventos Selectos',
              ]
            : [
                '1 Signature Monthly Cut',
                '10% Off All Retail Products',
                'Complimentary Coffee or Water',
                'Access to Select Events',
              ];

        final prestigeBullets = isSpanish
            ? [
                '2 Cortes Mensuales de Autor',
                'Estado de Reserva Prioritaria',
                '1 Afeitado con Toalla Caliente al Trimestre',
                'Servicio de Bebidas Premium',
                '15% de Descuento en Todos los Productos de Venta',
              ]
            : [
                '2 Signature Monthly Cuts',
                'Priority Booking Status',
                '1 Hot Towel Shave per Quarter',
                'Premium Drink Service',
                '15% Off All Retail Products',
              ];

        final legendaryBullets = isSpanish
            ? [
                'Cortes & Estilizado Ilimitados',
                'Acceso a Suite Privada VIP',
                'Kit Mensual de Productos de Autor',
                'Servicio de Valet Parking',
                'Pases de Invitado de Conserjería',
              ]
            : [
                'Unlimited Cuts & Styling',
                'VIP Private Suite Access',
                'Monthly Signature Product Kit',
                'Valet Parking Service',
                'Concierge Guest Passes',
              ];

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
                      children: [
                        _buildPricingCard(
                          context: context,
                          l10n: l10n,
                          title: isSpanish ? 'Esencial' : 'Essential',
                          price: '${config.currencySymbol}85',
                          bullets: essentialBullets,
                          isHighlighted: false,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildPricingCard(
                          context: context,
                          l10n: l10n,
                          title: isSpanish ? 'Prestigio' : 'Prestige',
                          price: '${config.currencySymbol}150',
                          bullets: prestigeBullets,
                          isHighlighted: true,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildPricingCard(
                          context: context,
                          l10n: l10n,
                          title: isSpanish ? 'Legendario' : 'Legendary',
                          price: '${config.currencySymbol}225',
                          bullets: legendaryBullets,
                          isHighlighted: false,
                        ),
                      ],
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildPricingCard(
                              context: context,
                              l10n: l10n,
                              title: isSpanish ? 'Esencial' : 'Essential',
                              price: '${config.currencySymbol}85',
                              bullets: essentialBullets,
                              isHighlighted: false,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildPricingCard(
                              context: context,
                              l10n: l10n,
                              title: isSpanish ? 'Prestigio' : 'Prestige',
                              price: '${config.currencySymbol}150',
                              bullets: prestigeBullets,
                              isHighlighted: true,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildPricingCard(
                              context: context,
                              l10n: l10n,
                              title: isSpanish ? 'Legendario' : 'Legendary',
                              price: '${config.currencySymbol}225',
                              bullets: legendaryBullets,
                              isHighlighted: false,
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

  Widget _buildPricingCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required String title,
    required String price,
    required List<String> bullets,
    required bool isHighlighted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(
          color: isHighlighted ? AppColors.secondary : AppColors.outlineVariant,
          width: isHighlighted ? 2 : 1,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTextStyles.headlineSm.copyWith(
                    color: isHighlighted
                        ? AppColors.secondary
                        : const Color(0xFFE2E2E2),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: AppTextStyles.headlineLg().copyWith(
                        color: const Color(0xFFE2E2E2),
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.languageCode == 'es' ? '/ mes' : '/ month',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // Divider line
                const Divider(color: AppColors.outlineVariant, thickness: 1),
                const SizedBox(height: AppSpacing.xl),
                // Bullets
                ...bullets.map((bullet) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            bullet,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 14,
                              color: const Color(0xFFE2E2E2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                // Join Club button
                ElevatedButton(
                  onPressed: () => context.go('/booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isHighlighted
                        ? AppColors.secondary
                        : Colors.transparent,
                    foregroundColor: isHighlighted
                        ? AppColors.onSecondary
                        : AppColors.secondary,
                    elevation: 0,
                    side: isHighlighted
                        ? null
                        : const BorderSide(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                    minimumSize: const Size(double.infinity, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    l10n.get('join_club'),
                    style: AppTextStyles.labelMd.copyWith(
                      color: isHighlighted
                          ? AppColors.onSecondary
                          : AppColors.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.08 * 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isHighlighted)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  color: AppColors.secondary,
                  child: Text(
                    l10n.get('most_popular'),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.1 * 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Benefits Section ──────────────────────────────────────────────────────

  Widget _buildBenefitsSection(BuildContext context, AppLocalizations l10n) {
    final isSpanish = l10n.languageCode == 'es';
    final List<Map<String, dynamic>> benefits = [
      {
        'icon': Icons.priority_high,
        'title': isSpanish ? 'Reserva Prioritaria' : 'Priority Booking',
        'desc': isSpanish
            ? 'Los miembros tienen acceso exclusivo primero a las agendas de nuestros maestros barberos.'
            : 'Members get first access to our master barbers\' schedules.',
      },
      {
        'icon': Icons.local_bar_outlined,
        'title': isSpanish ? 'Bar de Cortesía' : 'Complimentary Bar',
        'desc': isSpanish
            ? 'Disfruta de una selección exclusiva de whiskies premium y café artesanal.'
            : 'Enjoy a curated selection of premium whiskeys and artisan coffee.',
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'title': isSpanish ? 'Productos de Autor' : 'Signature Products',
        'desc': isSpanish
            ? 'Descuentos exclusivos y acceso anticipado a nuestras fragancias de marca propia.'
            : 'Exclusive discounts and early access to our private label scents.',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': isSpanish ? 'Eventos para Miembros' : 'Member Events',
        'desc': isSpanish
            ? 'Reuniones mensuales de networking y clases magistrales de estilismo.'
            : 'Monthly networking mixers and styling masterclasses.',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.surfaceContainerLowest,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
            vertical: AppSpacing.xxl + 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: Column(
                children: [
                  Text(
                    isSpanish
                        ? 'Beneficios Inigualables'
                        : 'Unrivaled Benefits',
                    style: AppTextStyles.headlineSm.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE2E2E2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isSpanish
                        ? 'Más que un corte de cabello. Un compromiso con la excelencia.'
                        : 'More than a haircut. A commitment to excellence.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl + 16),
                  isMobile
                      ? Column(
                          children: benefits.map((b) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xl,
                              ),
                              child: _buildBenefitCard(b),
                            );
                          }).toList(),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: benefits.map((b) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: _buildBenefitCard(b),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitCard(Map<String, dynamic> b) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.secondary, width: 1.5),
            borderRadius: BorderRadius.zero,
          ),
          child: Center(
            child: Icon(b['icon'], color: AppColors.secondary, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          b['title'],
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.04 * 15,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          b['desc'],
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── Elevate Presence Section ──────────────────────────────────────────────

  Widget _buildElevateSection(BuildContext context, AppLocalizations l10n) {
    final isSpanish = l10n.languageCode == 'es';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.background,
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
                    isSpanish
                        ? '¿Listo para elevar tu presencia?'
                        : 'Ready to elevate your presence?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSm.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE2E2E2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isSpanish
                        ? 'Los cupos de membresía son limitados para garantizar la más alta calidad de servicio para nuestro Círculo Interno. Solicítalo hoy para asegurar tu lugar.'
                        : 'Membership slots are limited to ensure the highest quality of service for our Inner Circle. Apply today to secure your place.',
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
                            _buildElevateButton(
                              context,
                              isSpanish
                                  ? 'UNIRSE A PRESTIGIO'
                                  : 'JOIN PRESTIGE',
                              true,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildElevateButton(
                              context,
                              isSpanish
                                  ? 'CONTACTAR CONSERJERÍA'
                                  : 'CONTACT CONCIERGE',
                              false,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildElevateButton(
                              context,
                              isSpanish
                                  ? 'UNIRSE A PRESTIGIO'
                                  : 'JOIN PRESTIGE',
                              true,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _buildElevateButton(
                              context,
                              isSpanish
                                  ? 'CONTACTAR CONSERJERÍA'
                                  : 'CONTACT CONCIERGE',
                              false,
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

  Widget _buildElevateButton(BuildContext context, String text, bool isSolid) {
    return ElevatedButton(
      onPressed: () => context.go('/booking'),
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

class _MembershipDrawer extends ConsumerWidget {
  const _MembershipDrawer();

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

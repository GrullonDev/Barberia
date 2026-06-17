import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../home/presentation/widgets/home_footer.dart';
import '../../../home/presentation/widgets/home_nav_bar.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedBarberId;

  final List<Map<String, dynamic>> _barbers = [
    {
      'id': 'julian',
      'name': 'Julian Vance',
      'specialty': 'Especialista en Navaja',
      'tag': 'MASTER',
      'image': 'assets/images/barber_julian_vance.png',
      'rating': '4.9',
      'reviews': '124 reseñas',
    },
    {
      'id': 'marcus',
      'name': 'Marcus Reed',
      'specialty': 'Cortes Clásicos',
      'tag': 'SENIOR',
      'image': 'assets/images/barber_marcus_reed.png',
      'rating': '5.0',
      'reviews': '98 reseñas',
    },
    {
      'id': 'dorian',
      'name': 'Dorian Grey',
      'specialty': 'Barba y Cuidado Facial',
      'tag': 'ELITE',
      'image': 'assets/images/barber_dorian_grey.png',
      'rating': '4.8',
      'reviews': '215 reseñas',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _BookingDrawer(),
      body: Column(
        children: [
          HomeNavBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            activePage: 'Booking',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSection(),
                  _buildStepperSection(),
                  _buildBarberSelectionSection(),
                  const HomeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header Section ─────────────────────────────────────────────────────────

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.gutter),
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Text(
                'Reserva tu Experiencia',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLg().copyWith(
                  color: const Color(0xFFE2E2E2),
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Precisión, tradición y el estilo que mereces. Sigue los pasos para agendar tu cita en The Gentleman\'s Lounge.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stepper Section ────────────────────────────────────────────────────────

  Widget _buildStepperSection() {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStep(
                number: '1',
                label: 'BARBERO',
                isActive: true,
              ),
              _buildStepDivider(),
              _buildStep(
                number: '2',
                label: 'AGENDA',
                isActive: false,
              ),
              _buildStepDivider(),
              _buildStep(
                number: '3',
                label: 'RESUMEN',
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.secondary : AppColors.outlineVariant,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.labelMd.copyWith(
                color: isActive ? AppColors.secondary : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? AppColors.secondary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08 * 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 64,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: 20),
      color: AppColors.outlineVariant,
    );
  }

  // ─── Barber Selection Grid ──────────────────────────────────────────────────

  Widget _buildBarberSelectionSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < Breakpoints.tablet;
      return Container(
        color: AppColors.background,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.marginMobile : AppSpacing.marginDesktop,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.containerMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona tu Barbero',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: const Color(0xFFE2E2E2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cada uno de nuestros expertos tiene un estilo único de maestría.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                isMobile ? _buildBarberListMobile() : _buildBarberGridDesktop(),
                const SizedBox(height: AppSpacing.xxl + 16),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBarberGridDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _barbers.map((barber) {
        final isSelected = _selectedBarberId == barber['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: _buildBarberCard(barber, isSelected),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarberListMobile() {
    return Column(
      children: _barbers.map((barber) {
        final isSelected = _selectedBarberId == barber['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: _buildBarberCard(barber, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildBarberCard(Map<String, dynamic> barber, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedBarberId = barber['id']),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Portrait image with Tag overlay
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0, // Square image aspect ratio matching mockup
                    child: Image.asset(
                      barber['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.onSurfaceVariant,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: AppColors.secondary,
                      child: Text(
                        barber['tag'],
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.08 * 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Details section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Specialty
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barber['name'],
                            style: AppTextStyles.headlineSm.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE2E2E2),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            barber['specialty'],
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Rating & Reviews Count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_border,
                              color: AppColors.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              barber['rating'],
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          barber['reviews'],
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDrawer extends StatelessWidget {
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

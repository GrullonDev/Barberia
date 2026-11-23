import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/features/home/presentation/widgets/home_footer.dart';
import 'package:barberia/features/home/presentation/widgets/home_nav_bar.dart';

class BarbersPage extends StatelessWidget {
  const BarbersPage({super.key});

  static final _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _artisans = const [
    {
      'name': 'Julian Sterling',
      'tag': 'MASTER BARBER',
      'image': 'assets/images/barber_julian_vance.png',
      'subtags': ['Scissor Cuts', 'Beard Sculpting'],
      'description':
          'With over 15 years of international experience, Julian blends classic London techniques with modern aesthetic precision. His signature \'Sculpted Scissor Cut\' has become a lounge legend.',
      'buttonText': 'BOOK WITH JULIAN',
    },
    {
      'name': 'Elias Thorne',
      'tag': 'DIRECTOR BARBER',
      'image': 'assets/images/barber_marcus_reed.png',
      'subtags': ['Classic Shaves', 'Texture Specialists'],
      'description':
          'Elias specializes in the ritual of the traditional straight-razor shave. For him, grooming is an art of patience and detail, ensuring every guest leaves feeling completely restored.',
      'buttonText': 'BOOK WITH ELIAS',
    },
    {
      'name': 'Sebastian Vane',
      'tag': 'SENIOR ARTISAN',
      'image': 'assets/images/barber_dorian_grey.png',
      'subtags': ['Modern Fades', 'Hair Coloring'],
      'description':
          'Bringing a contemporary edge to the Lounge, Sebastian is a master of the precise skin fade and avant-garde texturing. He is the go-to for those seeking a sharp, modern evolution.',
      'buttonText': 'BOOK WITH SEBASTIAN',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _BarbersDrawer(),
      body: Column(
        children: [
          HomeNavBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            activePage: 'Barbers',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSection(context),
                  _buildArtisansSection(context),
                  _buildJoinCircleSection(context),
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

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl + 16,
        bottom: AppSpacing.xl,
      ),
      color: AppColors.background,
      child: Center(
        child: Column(
          children: [
            Text(
              'MEET OUR TEAM',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.12 * 12,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Master Artisans',
              style: AppTextStyles.headlineLg().copyWith(
                color: const Color(0xFFE2E2E2),
                fontSize: 42,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(width: 50, height: 2, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  // ─── Artisans Section ───────────────────────────────────────────────────────

  Widget _buildArtisansSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.background,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: isMobile
                  ? Column(
                      children: _artisans.map((artisan) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: _buildArtisanCard(context, artisan),
                        );
                      }).toList(),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _artisans.map((artisan) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: _buildArtisanCard(context, artisan),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtisanCard(BuildContext context, Map<String, dynamic> artisan) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with tag overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: Image.asset(
                  artisan['image'],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  color: AppColors.secondary,
                  child: Text(
                    artisan['tag'],
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artisan['name'],
                  style: AppTextStyles.headlineSm.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE2E2E2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Subtags
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: (artisan['subtags'] as List<String>).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Description
                Text(
                  artisan['description'],
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Book button
                OutlinedButton(
                  onPressed: () => context.go('/booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(
                      color: AppColors.secondary,
                      width: 1.5,
                    ),
                    minimumSize: const Size(double.infinity, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    artisan['buttonText'],
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08 * 14,
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

  // ─── Join Exclusive Circle Section ─────────────────────────────────────────

  Widget _buildJoinCircleSection(BuildContext context) {
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xxl + 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  border: Border.all(color: AppColors.outlineVariant, width: 1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  children: [
                    Text(
                      'Join The Exclusive Circle',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSm.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE2E2E2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Text(
                        'Our Membership offers more than just a cut; it\'s a commitment to excellence. Secure priority bookings with your preferred artisan and enjoy the Lounge\'s private amenities.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => context.go('/membership'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.md + 4,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'EXPLORE MEMBERSHIP',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSecondary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.08 * 14,
                        ),
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

class _BarbersDrawer extends StatelessWidget {
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
              Text('LUXE & BLADE', style: AppTextStyles.headlineSm),
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

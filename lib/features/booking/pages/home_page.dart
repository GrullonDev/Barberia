import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:barberia/app/router.dart';
import 'package:barberia/app/theme.dart';
import 'package:barberia/app/theme_controller.dart';
import 'package:barberia/common/design_tokens.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/auth/models/user.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageCtrl;
  late final ValueNotifier<double> _pageNotifier;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.85);
    _pageNotifier = ValueNotifier<double>(0);
    _pageCtrl.addListener(() {
      _pageNotifier.value = _pageCtrl.page ?? 0;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<Service>> asyncServices = ref.watch(
      servicesAsyncProvider,
    );
    final List<Service> popular =
        asyncServices.valueOrNull?.take(6).toList() ?? const <Service>[];
    final User? user = ref.watch(authStateProvider);
    final ThemePrefs themePrefs = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clipz'),
        actions: <Widget>[
          if (user?.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.pushNamed(RouteNames.addService),
            ),
          if (user?.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.pushNamed(RouteNames.admin),
            ),
          PopupMenuButton<String>(
            onSelected: (final String v) {
              if (v == 'profile') {
                context.pushNamed(RouteNames.profile);
              } else if (v.startsWith('mode:')) {
                final String m = v.split(':')[1];
                ref.read(themeControllerProvider.notifier).setMode(switch (m) {
                  'light' => ThemeMode.light,
                  'dark' => ThemeMode.dark,
                  _ => ThemeMode.system,
                });
              } else if (v.startsWith('seed:')) {
                final String s = v.split(':')[1];
                ref.read(themeControllerProvider.notifier).setSeed(switch (s) {
                  'indigo' => ThemeSeedOption.indigo,
                  'rose' => ThemeSeedOption.rose,
                  'amber' => ThemeSeedOption.amber,
                  _ => ThemeSeedOption.emerald,
                });
              }
            },
            itemBuilder: (final BuildContext _) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'mode:light',
                child: Text('Modo Claro'),
              ),
              const PopupMenuItem<String>(
                value: 'mode:dark',
                child: Text('Modo Oscuro'),
              ),
              const PopupMenuItem<String>(
                value: 'mode:system',
                child: Text('Modo Sistema'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'seed:emerald',
                child: Text('Verde'),
              ),
              const PopupMenuItem<String>(
                value: 'seed:indigo',
                child: Text('Índigo'),
              ),
              const PopupMenuItem<String>(
                value: 'seed:rose',
                child: Text('Rose'),
              ),
              const PopupMenuItem<String>(
                value: 'seed:amber',
                child: Text('Amber'),
              ),
            ],
            icon: Container(
              height: 26,
              width: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themePrefs.seed.color,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeroSection(
            onPrimary: () => context.goNamed(RouteNames.services),
            onSecondary: () => context.goNamed(RouteNames.services),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Servicios Populares',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.services),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: asyncServices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (final Object e, final StackTrace st) =>
                  const Center(child: Text('Error cargando servicios')),
              data: (final List<Service> data) => PageView.builder(
                controller: _pageCtrl,
                padEnds: false,
                itemCount: popular.length,
                itemBuilder: (final BuildContext _, final int i) {
                  return ValueListenableBuilder<double>(
                    valueListenable: _pageNotifier,
                    builder: (context, value, _) {
                      final double progress = (value - i).abs();
                      final double scale = (1 - (progress * 0.08)).clamp(
                        0.9,
                        1.0,
                      );
                      final Service s = popular[i];
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: (1 - progress * 0.5).clamp(0.3, 1.0),
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == popular.length - 1 ? 0 : 14,
                            ),
                            child: _ServiceCard(
                              service: s,
                              onTap: () => context.goNamed(RouteNames.services),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<double>(
            valueListenable: _pageNotifier,
            builder: (_, final double v, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(popular.length, (final int i) {
                final double sel = (v - i).abs();
                final bool active = sel < 0.5;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: active ? 22 : 6,
                  decoration: BoxDecoration(
                    color: active ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          _QuickActionsSection(),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => context.goNamed(RouteNames.myBookings),
              child: Text('Ver mis citas', style: TextStyle(color: cs.primary)),
            ),
          ),
          const SizedBox(height: 80), // Space for bottom nav
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _HeroSection({required this.onPrimary, required this.onSecondary});

  @override
  Widget build(BuildContext context) {
    final TextTheme txt = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Dark Navy for premium contrast
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NUEVO',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.stars, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Luce tu mejor versión',
            style: txt.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reserva tu corte premium hoy y destaca.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('RESERVAR AHORA'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    final String price = NumberFormat.currency(
      name: 'GTQ',
      symbol: 'Q',
    ).format(service.price);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.content_cut, color: cs.primary),
            ),
            const Spacer(),
            Text(
              service.name,
              style: txt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${service.durationMinutes} min',
              style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: txt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: Icons.calendar_today,
          label: 'Mis Citas',
          onTap: () => context.goNamed(RouteNames.myBookings),
        ),
        _ActionButton(
          icon: Icons.location_on,
          label: 'Ubicación',
          onTap: () {},
        ),
        _ActionButton(icon: Icons.phone, label: 'Contacto', onTap: () {}),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

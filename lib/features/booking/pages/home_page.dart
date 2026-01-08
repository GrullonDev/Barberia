import 'package:barberia/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:barberia/features/auth/models/user.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:barberia/app/router.dart';

import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';

import 'package:barberia/common/design_tokens.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/auth/models/user.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<List<Service>> asyncServices = ref.watch(
      servicesAsyncProvider,
    );
    final List<Service> popular =
        asyncServices.valueOrNull?.take(6).toList() ?? const <Service>[];
    final User? user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clipz'),
        actions: <Widget>[
          if (ref.watch(authStateProvider)?.role == UserRole.admin)
            // Note: RouteNames.addService might be missing, ensure it exists or comment out if temporary
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.pushNamed(
                'add_service',
              ), // Fallback literal if const missing
            ),
          if (ref.watch(authStateProvider)?.role == UserRole.admin)
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
                S.of(context).home_popular_title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.services),
                child: Text(S.of(context).see_all),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: asyncServices.when(
              loading: () => _ShimmerCarousel(),
              error: (final Object e, final StackTrace st) =>
                  const Center(child: Text('Error cargando servicios')),
              data: (final List<Service> data) => PageView.builder(
                controller: pageCtrl,
                padEnds: false,
                itemCount: popular.length,
                itemBuilder: (final BuildContext _, final int i) {
                  final double progress = (pageNotifier.value - i).abs();
                  final double scale = (1 - (progress * 0.08)).clamp(0.9, 1.0);
                  final Service s = popular[i];
                  return AnimatedBuilder(
                    animation: pageNotifier,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: (1 - progress * 0.5).clamp(0.3, 1.0),
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == popular.length - 1 ? 0 : 14,
                            ),
                            child: _PopularServiceCard(
                              service: s,
                              selected: (pageNotifier.value.round() == i),
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
            valueListenable: pageNotifier,
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
          TextButton(
            onPressed: () => context.goNamed(RouteNames.myBookings),
            child: Text('Ver mis citas', style: TextStyle(color: cs.primary)),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 80,
          ), // Extra space for nav bar
        ],
      ),
    );
  }
}

class _HomeAppBar extends ConsumerWidget {
  final User? user;
  const _HomeAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final S tr = S.of(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints c) {
        final bool wide = MediaQuery.of(ctx).size.aspectRatio > 1.2;
        final Widget image = Semantics(
          label: tr.hero_image_semantics,
          image: true,
          child: Container(
            width: wide ? double.infinity : 110,
            height: wide ? 200 : 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(wide ? 32 : 24),
              gradient: LinearGradient(
                colors: <Color>[
                  cs.primaryContainer,
                  cs.primaryContainer.withValues(alpha: .6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.image,
              size: wide ? 90 : 54,
              color: cs.onPrimaryContainer.withValues(alpha: 0.9),
            ),
          ),
        );
        final Widget text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Bienvenido de nuevo,',
              style: txt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              user?.name.split(' ').first ?? 'Invitado',
              style: txt.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                cs.surfaceContainerHighest.withValues(alpha: 0.5),
                cs.surface,
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (user?.role == UserRole.admin)
          IconButton(
            icon: Icon(Icons.admin_panel_settings, color: cs.primary),
            onPressed: () => context.pushNamed(RouteNames.admin),
            tooltip: 'Admin Panel',
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => context.pushNamed(RouteNames.profile),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                radius: 16,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextTheme txt = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // Always Dark Navy for premium contrast
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
                child: Text(
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
              Icon(Icons.stars, color: AppColors.primary, size: 20),
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
          Text(
            'Reserva tu corte premium hoy y destaca.',
            style: txt.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.goNamed(RouteNames.services),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onPrimary,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          );
        }

        // Mobile layout (default)
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              image,
              const SizedBox(height: 24),
              DefaultTextStyle(
                style: txt.bodyMedium!.copyWith(color: cs.onPrimaryContainer),
                child: text,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAction;

  const _SectionHeader({required this.title, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final TextTheme txt = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: txt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: cs.primary),
          child: const Text('Ver Todo'),
        ),
      ],
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
    final S tr = S.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
        ), // Placeholder
        _ActionButton(
          icon: Icons.phone,
          label: 'Contacto',
          onTap: () {},
        ), // Placeholder
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

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (_, __) => Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

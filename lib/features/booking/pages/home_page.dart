import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/app/theme.dart';
import 'package:barberia/app/theme_controller.dart';

import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:intl/intl.dart';
import 'package:barberia/l10n/app_localizations.dart';
import 'package:barberia/common/design_tokens.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<List<Service>> asyncServices = ref.watch(
      servicesAsyncProvider,
    );
    final List<Service> popular =
        asyncServices.valueOrNull?.take(6).toList() ?? const <Service>[];
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemePrefs themePrefs = ref.watch(themeControllerProvider);
    final PageController pageCtrl = PageController(viewportFraction: 0.78);
    final ValueNotifier<double> pageNotifier = ValueNotifier<double>(0);
    pageCtrl.addListener(() => pageNotifier.value = pageCtrl.page ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clipz'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (final String v) {
              if (v.startsWith('mode:')) {
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
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onPrimary, required this.onSecondary});
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final S tr = S.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withAlpha(51),
                  AppColors.surfaceDark,
                ]
              : [AppColors.primaryContainer, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.content_cut_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Clipz Premium',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            tr.hero_title,
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            tr.hero_subtitle,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              color: isDark ? AppColors.secondary : AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(tr.hero_cta_primary),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: Text(tr.hero_cta_secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PopularServiceCard extends StatelessWidget {
  const _PopularServiceCard({
    required this.service,
    required this.onTap,
    required this.selected,
  });
  final Service service;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final S tr = S.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String price = NumberFormat.currency(
      name: 'GTQ',
      symbol: 'Q',
    ).format(service.price);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 230,
        padding: EdgeInsets.all(selected ? AppSpacing.m + 2 : AppSpacing.m),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.outlineDark : AppColors.outline),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.l),
          color: selected
              ? AppColors.primary.withAlpha(12)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          boxShadow: selected ? AppShadows.medium : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    color: AppColors.primaryContainer,
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    color: AppColors.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    service.name,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: selected ? 18 : 16,
                      color: isDark
                          ? AppColors.onSurfaceDark
                          : AppColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: isDark ? AppColors.secondary : AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${service.durationMinutes} min',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.secondary : AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.secondaryContainer
                    : AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Text(
                '${tr.price_from_prefix} $price',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSecondaryContainer,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCarousel extends StatefulWidget {
  @override
  State<_ShimmerCarousel> createState() => _ShimmerCarouselState();
}

class _ShimmerCarouselState extends State<_ShimmerCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, int i) {
            return _ShimmerBlock(
              progress: (_ctrl.value + i * 0.33) % 1,
              color: cs.primary,
            );
          },
        );
      },
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.surfaceContainerHighest.withAlpha(51),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 18,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: cs.onSurface.withAlpha(18),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: cs.onSurface.withAlpha(15),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  height: 28,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cs.onSurface.withAlpha(15),
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ShimmerPainter(
                  progress: progress,
                  base: cs.surfaceContainerHighest,
                  highlight: color.withAlpha(64),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.progress,
    required this.base,
    required this.highlight,
  });
  final double progress;
  final Color base;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..shader = LinearGradient(
        colors: <Color>[base, highlight, base],
        stops: const <double>[0, 0.5, 1],
        begin: Alignment(-1 + progress * 2, -1),
        end: Alignment(1 + progress * 2, 1),
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// Shimmer replaces old skeleton implementation.

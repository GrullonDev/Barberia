import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/app/theme.dart';
import 'package:barberia/app/theme_controller.dart';
import 'package:barberia/common/widgets/primary_button.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/service_card_modern.dart';

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
          // Hero
          Text(
            'Tu corte, a tu hora ✂️',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reserva en 3 pasos. Sin registrarte.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Populares',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.services),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: asyncServices.when(
              loading: () => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => const _SkeletonCard(),
              ),
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
                            child: ServiceCardModern(
                              service: s,
                              onTap: () => context.goNamed(RouteNames.services),
                              selected: (pageNotifier.value.round() == i),
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
          PrimaryButton(
            label: 'Reservar ahora',
            onPressed: () => context.goNamed(RouteNames.services),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.goNamed(RouteNames.myBookings),
            child: Text('Ver mis citas', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 20,
            width: 120,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 14,
            width: 80,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              height: 26,
              width: 70,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

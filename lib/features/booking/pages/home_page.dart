import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/widgets/primary_button.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/service_card_modern.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Service> services = ref.watch(servicesProvider);
    final List<Service> popular = services.take(6).toList();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Clipz')),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.services),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (final BuildContext _, final int i) {
                final Service s = popular[i];
                return SizedBox(
                  width: 220,
                  child: ServiceCardModern(
                    service: s,
                    onTap: () => context.goNamed(RouteNames.services),
                  ),
                );
              },
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
            child: Text(
              'Ver mis citas',
              style: TextStyle(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Service> services = ref.watch(servicesProvider);
    final List<Service> featured = services.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Barbería')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text(
            'Reserva tu cita',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige uno de nuestros servicios profesionales y asegura tu horario.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const Text(
            'Servicios destacados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...featured.map(
            (final Service s) => Card(
              child: ListTile(
                title: Text(s.name),
                subtitle: Text(
                  '${s.durationMinutes} min · \$${s.price.toStringAsFixed(2)}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.goNamed(RouteNames.services),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.goNamed(RouteNames.services),
            child: const Text('Reservar ahora'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.goNamed(RouteNames.myBookings),
            child: const Text('Ver mis citas'),
          ),
        ],
      ),
    );
  }
}

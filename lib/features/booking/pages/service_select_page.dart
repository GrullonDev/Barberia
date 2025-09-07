import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class ServiceSelectPage extends ConsumerWidget {
  const ServiceSelectPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Service> services = ref.watch(servicesProvider);
    final BookingDraft draft = ref.watch(bookingDraftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Servicio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Elige un servicio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...services.map(
            (final Service s) => Card(
              child: ListTile(
                title: Text(s.name),
                subtitle: Text(
                  '${s.durationMinutes} min · \$${s.price.toStringAsFixed(2)}',
                ),
                trailing: draft.service?.id == s.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () =>
                    ref.read(bookingDraftProvider.notifier).setService(s),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: draft.service == null
                ? null
                : () => context.goNamed(RouteNames.calendar),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

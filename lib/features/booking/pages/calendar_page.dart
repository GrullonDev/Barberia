import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final BookingDraft draft = ref.watch(bookingDraftProvider);

    Future<void> openTimeSlots() async {
      final DateTime baseDate = draft.date ?? DateTime.now();
      final List<DateTime> slots = List<DateTime>.generate(
        8,
        (final int i) =>
            DateTime(baseDate.year, baseDate.month, baseDate.day, 9 + i),
      );
      final DateTime? picked = await showModalBottomSheet<DateTime>(
        context: context,
        builder: (final BuildContext ctx) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Selecciona una hora',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...slots.map(
              (final DateTime dt) => ListTile(
                title: Text('${dt.hour.toString().padLeft(2, '0')}:00'),
                onTap: () => Navigator.of(ctx).pop(dt),
              ),
            ),
          ],
        ),
      );
      if (picked != null) {
        ref.read(bookingDraftProvider.notifier).setDateTime(picked);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Fecha y Hora')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  draft.date == null
                      ? 'Selecciona una fecha'
                      : 'Fecha: ${draft.date!.toIso8601String().substring(0, 10)}',
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final DateTime today = DateTime.now();
                    ref
                        .read(bookingDraftProvider.notifier)
                        .setDate(DateTime(today.year, today.month, today.day));
                  },
                  child: const Text('Usar fecha de hoy'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: draft.date == null ? null : openTimeSlots,
                  child: const Text('Seleccionar Hora'),
                ),
                if (draft.dateTime != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Hora seleccionada: ${draft.dateTime!.hour.toString().padLeft(2, '0')}:00',
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: draft.dateTime == null
                  ? null
                  : () => context.goNamed(RouteNames.details),
              child: const Text('Siguiente: Detalles'),
            ),
          ),
        ],
      ),
    );
  }
}

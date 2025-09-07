import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final bool canPop = context.canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        automaticallyImplyLeading: canPop,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Tus citas programadas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (bookings.isEmpty)
            const Text('No tienes citas aún')
          else
            ...bookings.map(
              (final Booking b) {
                final DateTime now = DateTime.now();
                final bool past = b.endTime.isBefore(now);
                String two(int v) => v.toString().padLeft(2, '0');
                final DateTime s = b.dateTime;
                final DateTime e = b.endTime;
                final String date = '${two(s.day)}/${two(s.month)}/${s.year}';
                final String range = '${two(s.hour)}:${two(s.minute)} - ${two(e.hour)}:${two(e.minute)}';
                final TextStyle baseSubtitle = Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
                final TextStyle timeStyle = past
                    ? baseSubtitle.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: baseSubtitle.color?.withOpacity(0.5),
                      )
                    : baseSubtitle;
                return Opacity(
                  opacity: past ? 0.55 : 1,
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        past ? Icons.history : Icons.schedule,
                        color: past ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(b.service.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('$date  $range', style: timeStyle),
                          Text('Duración: ${b.service.durationMinutes} min', style: baseSubtitle.copyWith(fontSize: 11)),
                          if (b.customerName.isNotEmpty)
                            Text('Cliente: ${b.customerName}', style: baseSubtitle.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

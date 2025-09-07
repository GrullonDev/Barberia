import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../booking/models/booking.dart';
import '../../booking/providers/booking_providers.dart';

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Booking> bookings = ref.watch(bookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Citas')),
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
              (final Booking b) => Card(
                child: ListTile(
                  title: Text(b.service.name),
                  subtitle: Text('${b.dateTime}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

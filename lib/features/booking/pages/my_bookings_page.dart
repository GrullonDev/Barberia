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

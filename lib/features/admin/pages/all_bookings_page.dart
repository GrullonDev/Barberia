import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/common/utils/responsive_helper.dart';

import 'package:barberia/features/booking/providers/booking_providers.dart';

class AllBookingsPage extends ConsumerWidget {
  const AllBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AGENDA COMPLETA'), centerTitle: true),
      body: bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: cs.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay citas registradas',
                    style: txt.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (BuildContext context, int index) {
                final Booking booking = bookings[index];
                return Card(
                  margin: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsivePadding(context),
                    vertical: ResponsiveHelper.getSpacing(context, mobile: 8),
                  ),
                  child: ListTile(
                    title: Text(booking.serviceName),
                    subtitle: Text(
                      'Cliente: ${booking.customerName}\nFecha: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.dateTime)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

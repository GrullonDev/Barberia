import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:barberia/features/booking/models/booking.dart';
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
                final bool isCanceled =
                    booking.status == BookingStatus.canceled;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: isCanceled
                          ? cs.errorContainer
                          : cs.primaryContainer,
                      child: Icon(
                        isCanceled ? Icons.cancel : Icons.event,
                        color: isCanceled ? cs.error : cs.primary,
                      ),
                    ),
                    title: Text(
                      booking.serviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCanceled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'dd MMM, yyyy - HH:mm',
                      ).format(booking.dateTime),
                      style: txt.bodySmall,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCanceled)
                          const Badge(
                            label: Text('Cancelado'),
                            backgroundColor: Colors.red,
                          )
                        else
                          const Badge(
                            label: Text('Activo'),
                            backgroundColor: Colors.green,
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              icon: Icons.person,
                              label: 'Cliente',
                              value: booking.customerName,
                            ),
                            if (booking.customerPhone != null)
                              _DetailRow(
                                icon: Icons.phone,
                                label: 'Teléfono',
                                value: booking.customerPhone!,
                              ),
                            if (booking.customerEmail != null)
                              _DetailRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: booking.customerEmail!,
                              ),
                            if (booking.notes != null &&
                                booking.notes!.isNotEmpty)
                              _DetailRow(
                                icon: Icons.note,
                                label: 'Notas',
                                value: booking.notes!,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

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
                return _BookingCard(booking: booking);
              },
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    final String formattedDate = DateFormat(
      'EEEE d, MMM',
      'es',
    ).format(booking.dateTime);
    final String formattedTime = DateFormat('h:mm a').format(booking.dateTime);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Time Column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formattedTime,
                    style: txt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate.toUpperCase(),
                    style: txt.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const VerticalDivider(width: 32, thickness: 1),
              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.customerName,
                            style: txt.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.serviceName,
                        style: txt.bodyMedium?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Indicator (Optional)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: booking.status == BookingStatus.active
                      ? Colors.green
                      : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (booking.status == BookingStatus.active
                                  ? Colors.green
                                  : Colors.orange)
                              .withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

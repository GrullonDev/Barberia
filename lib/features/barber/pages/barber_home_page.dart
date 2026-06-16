import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class BarberHomePage extends ConsumerWidget {
  const BarberHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authStateProvider);
    final List<Booking> allBookings = ref.watch(bookingsProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filter bookings that belong to this barber only.
    final List<Booking> myBookings = allBookings
        .where((Booking b) =>
            b.barberId == user.id && b.status != BookingStatus.canceled)
        .toList()
      ..sort((Booking a, Booking b) => a.startAt.compareTo(b.startAt));

    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));
    final DateTime dayAfterStart = tomorrowStart.add(const Duration(days: 1));

    final List<Booking> todayBookings = myBookings
        .where((Booking b) =>
            b.startAt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            b.startAt.isBefore(tomorrowStart))
        .toList();

    final List<Booking> upcomingBookings = myBookings
        .where((Booking b) =>
            b.startAt.isAfter(tomorrowStart.subtract(const Duration(seconds: 1))) &&
            b.startAt.isBefore(dayAfterStart.add(const Duration(days: 6))))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MI AGENDA'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Riverpod will auto-refresh; a short delay gives it time to settle.
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          slivers: <Widget>[
            // Greeting header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cs.onPrimary.withValues(alpha: 0.15),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Hola, ${user.name.split(' ').first}',
                            style: txt.titleLarge?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat("EEEE d 'de' MMMM", 'es').format(now),
                            style: txt.bodyMedium?.copyWith(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Today's appointments
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Hoy',
                count: todayBookings.length,
              ),
            ),
            if (todayBookings.isEmpty)
              const SliverToBoxAdapter(child: _EmptySlot(message: 'Sin citas para hoy'))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: todayBookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int i) =>
                      _AppointmentCard(booking: todayBookings[i]),
                ),
              ),

            // Upcoming appointments (next 7 days)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Próximos días',
                count: upcomingBookings.length,
              ),
            ),
            if (upcomingBookings.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptySlot(message: 'Sin citas en los próximos días'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: upcomingBookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int i) =>
                      _AppointmentCard(booking: upcomingBookings[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: txt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: txt.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.event_available_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appointment card
// ---------------------------------------------------------------------------

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    final String timeLabel =
        DateFormat('HH:mm').format(booking.startAt);
    final String endLabel =
        DateFormat('HH:mm').format(booking.endAt);
    final String dateLabel =
        DateFormat('EEE d MMM', 'es').format(booking.startAt);

    final Color statusColor = _statusColor(booking.status, cs);
    final String statusLabel = _statusLabel(booking.status);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            // Time block
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  timeLabel,
                  style: txt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                Text(
                  endLabel,
                  style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Divider
            Container(
              width: 2,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    booking.customerName,
                    style: txt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.serviceName,
                    style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (booking.customerPhone != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Icon(Icons.phone_outlined, size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          booking.customerPhone!,
                          style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right column: date + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  dateLabel,
                  style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    statusLabel,
                    style: txt.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BookingStatus status, ColorScheme cs) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.done:
        return cs.onSurfaceVariant;
      case BookingStatus.noShow:
        return Colors.orange;
      case BookingStatus.canceled:
        return cs.error;
      case BookingStatus.pending:
        return Colors.amber.shade700;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pendiente';
      case BookingStatus.confirmed:
        return 'Confirmada';
      case BookingStatus.inProgress:
        return 'En curso';
      case BookingStatus.done:
        return 'Completada';
      case BookingStatus.noShow:
        return 'No se presentó';
      case BookingStatus.canceled:
        return 'Cancelada';
    }
  }
}

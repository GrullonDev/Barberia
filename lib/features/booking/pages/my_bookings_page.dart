import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/appointment_card.dart';
import 'package:barberia/l10n/app_localizations.dart';

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final bool canPop = context.canPop();
    final S tr = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.my_bookings_title),
        centerTitle: true,
        automaticallyImplyLeading: canPop,
      ),
      body: bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr.empty_no_bookings,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/services'),
                    icon: const Icon(Icons.add),
                    label: Text(tr.empty_bookings_cta),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (final BuildContext _, final int i) {
                final Booking b = bookings[i];
                return AppointmentCard(booking: b)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (50 * i).ms)
                    .slideX(begin: 0.05, curve: Curves.easeOut);
              },
            ),
    );
  }
}

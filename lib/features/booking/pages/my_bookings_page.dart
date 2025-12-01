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
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final bool canPop = context.canPop();
    final S tr = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.my_bookings_title),
        automaticallyImplyLeading: canPop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (canPop) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            tr.my_bookings_heading,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (bookings.isEmpty)
            Center(
              child:
                  Column(
                        children: <Widget>[
                          const SizedBox(height: 40),
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(tr.empty_no_bookings),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.go('/services'),
                            child: Text(tr.empty_bookings_cta),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 80.ms)
                      .slideY(begin: .1, curve: Curves.easeOutCubic),
            )
          else
            ...List<Widget>.generate(bookings.length, (int i) {
              final Booking b = bookings[i];
              return AppointmentCard(booking: b)
                  .animate()
                  .fadeIn(duration: 280.ms, delay: (60 * i).ms)
                  .slideY(begin: .08, curve: Curves.easeOut);
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (bookings.isEmpty) {
            context.go('/');
          } else {
            context.go('/services');
          }
        },
        icon: Icon(bookings.isEmpty ? Icons.home : Icons.add),
        label: Text(bookings.isEmpty ? tr.confirm_home : tr.select_service_cta),
      ),
    );
  }
}

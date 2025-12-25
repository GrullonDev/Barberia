import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/widgets/appointment_card.dart';
import 'package:barberia/l10n/app_localizations.dart';
import 'package:barberia/common/design_tokens.dart';

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final S tr = S.of(context);
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                tr.my_bookings_title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      cs.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (bookings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.soft,
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: cs.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr.empty_no_bookings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.go('/services'),
                      icon: const Icon(Icons.add),
                      label: Text(tr.empty_bookings_cta),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final Booking b = bookings[index];
                  return AppointmentCard(booking: b)
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                      .slideX(begin: 0.05, curve: Curves.easeOut);
                }, childCount: bookings.length),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/barber/widgets/barber_chrome.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

const Color _kBg = Color(0xFF0B0B0B);
const Color _kSurface = Color(0xFF1C1C1C);
const Color _kGold = Color(0xFFD4AF37);
const Color _kGoldDim = Color(0xFF8B7028);
const Color _kText = Color(0xFFFFFFFF);
const Color _kMuted = Color(0xFF888888);
const Color _kBorder = Color(0xFF2A2A2A);

class BarberDashboardPage extends ConsumerStatefulWidget {
  const BarberDashboardPage({super.key});

  @override
  ConsumerState<BarberDashboardPage> createState() =>
      _BarberDashboardPageState();
}

class _BarberDashboardPageState extends ConsumerState<BarberDashboardPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider);
    final List<Booking> all = ref.watch(bookingsProvider);

    if (user == null) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGold)),
      );
    }

    final List<Booking> mine =
        all
            .where(
              (Booking b) =>
                  b.barberId == user.id && b.status != BookingStatus.canceled,
            )
            .toList()
          ..sort((Booking a, Booking b) => a.startAt.compareTo(b.startAt));

    final DateTime todayStart = DateTime(_now.year, _now.month, _now.day);
    final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));

    final List<Booking> todayBookings = mine
        .where(
          (Booking b) =>
              b.startAt.isAfter(
                todayStart.subtract(const Duration(seconds: 1)),
              ) &&
              b.startAt.isBefore(tomorrowStart),
        )
        .toList();

    final Booking? activeSession = todayBookings
        .where((Booking b) => b.status == BookingStatus.inProgress)
        .cast<Booking?>()
        .firstOrNull;

    final List<Booking> queue = todayBookings
        .where(
          (Booking b) =>
              b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.pending,
        )
        .take(3)
        .toList();

    final int completedToday = todayBookings
        .where((Booking b) => b.status == BookingStatus.done)
        .length;
    final double earningsToday = todayBookings
        .where((Booking b) => b.status == BookingStatus.done)
        .fold(0.0, (double sum, Booking b) => sum + b.servicePrice);
    final int totalScheduled = todayBookings.length;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: <Widget>[
          _buildAppBar(user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ActiveSessionCard(
                    booking: activeSession,
                    now: _now,
                    onFinish: activeSession == null
                        ? null
                        : () => ref
                              .read(bookingsProvider.notifier)
                              .updateStatus(
                                activeSession.id,
                                BookingStatus.done,
                              ),
                    onCancel: activeSession == null
                        ? null
                        : () => ref
                              .read(bookingsProvider.notifier)
                              .updateStatus(
                                activeSession.id,
                                BookingStatus.canceled,
                                cancelReason: CancelReason.byStaff,
                              ),
                  ),
                  const SizedBox(height: 28),
                  _QueueSection(queue: queue),
                  const SizedBox(height: 28),
                  _DailyPerformanceSection(
                    earnings: earningsToday,
                    completed: completedToday,
                    total: totalScheduled,
                  ),
                  const SizedBox(height: 28),
                  _FullTimelineSection(
                    todayBookings: todayBookings,
                    now: _now,
                    onOpenSchedule: () => context.go('/barber/schedule'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(User user) {
    return SliverAppBar(
      backgroundColor: _kBg,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: _kText),
        onPressed: () {},
      ),
      title: const Text(
        'THE GENTLEMAN',
      ),
      titleTextStyle: barberBrandStyle(fontSize: 22, height: 1),
      centerTitle: true,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _AvatarWidget(user: user),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Active Session Card
// ---------------------------------------------------------------------------

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.booking,
    required this.now,
    required this.onFinish,
    required this.onCancel,
  });

  final Booking? booking;
  final DateTime now;
  final VoidCallback? onFinish;
  final VoidCallback? onCancel;

  String _elapsed() {
    if (booking == null) {
      return '00:00';
    }
    final Duration d = now.difference(booking!.startAt);
    final int m = d.inMinutes.abs();
    final int s = d.inSeconds.abs() % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool active = booking != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Active Session',
              style: barberHeadingStyle(fontSize: 28),
            ),
            if (active)
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: _kGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: active
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              booking!.customerName,
                              style: const TextStyle(
                                color: _kText,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking!.serviceName,
                              style: const TextStyle(
                                color: _kMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              _elapsed(),
                              style: const TextStyle(
                                color: _kGold,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const Text(
                              'ELAPSED TIME',
                              style: TextStyle(
                                color: _kMuted,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActionButton(
                            label: 'Finish & Charge',
                            icon: Icons.check_circle_outline,
                            filled: true,
                            onTap: onFinish,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Cancel',
                            icon: Icons.close,
                            filled: false,
                            onTap: onCancel,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No active session right now',
                      style: TextStyle(color: _kMuted, fontSize: 14),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Next in Queue
// ---------------------------------------------------------------------------

class _QueueSection extends StatelessWidget {
  const _QueueSection({required this.queue});

  final List<Booking> queue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Next in Queue',
              style: barberHeadingStyle(fontSize: 28),
            ),
            GestureDetector(
              onTap: () => context.go('/barber/schedule'),
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  color: _kGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (queue.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: const Center(
              child: Text(
                'No upcoming appointments today',
                style: TextStyle(color: _kMuted, fontSize: 14),
              ),
            ),
          )
        else
          ...queue.map((Booking b) => _QueueCard(booking: b)),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final String time = DateFormat('HH:mm').format(booking.startAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.serviceName,
                  style: const TextStyle(color: _kMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: _kMuted, size: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Performance
// ---------------------------------------------------------------------------

class _DailyPerformanceSection extends StatelessWidget {
  const _DailyPerformanceSection({
    required this.earnings,
    required this.completed,
    required this.total,
  });

  final double earnings;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Daily Performance',
          style: barberHeadingStyle(fontSize: 28),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _PerfCard(
                icon: Icons.credit_card_outlined,
                label: 'EARNINGS',
                value: '\$${earnings.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerfCard(
                icon: Icons.content_cut_outlined,
                label: 'SERVICES',
                value: '$completed / $total',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PerfCard extends StatelessWidget {
  const _PerfCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: _kGold, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _kText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full Timeline
// ---------------------------------------------------------------------------

class _FullTimelineSection extends StatelessWidget {
  const _FullTimelineSection({
    required this.todayBookings,
    required this.now,
    required this.onOpenSchedule,
  });

  final List<Booking> todayBookings;
  final DateTime now;
  final VoidCallback onOpenSchedule;

  String _nextGapLabel() {
    final List<Booking> active =
        todayBookings.where((Booking b) => b.occupiesSlot).toList()
          ..sort((Booking a, Booking b) => a.startAt.compareTo(b.startAt));

    DateTime cursor = now;
    for (final Booking b in active) {
      if (cursor.isBefore(b.startAt)) {
        final int gap = b.startAt.difference(cursor).inMinutes;
        if (gap >= 15) {
          return 'Next available gap: ${DateFormat('HH:mm').format(cursor)} (${gap}m)';
        }
      }
      if (cursor.isBefore(b.endAt)) {
        cursor = b.endAt;
      }
    }
    return 'Next available gap: ${DateFormat('HH:mm').format(cursor)} (open)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Full Timeline',
              style: barberHeadingStyle(fontSize: 28),
            ),
            const Icon(Icons.calendar_today_outlined, color: _kGold, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF1A1A1A), Color(0xFF252010)],
                  ),
                ),
              ),
              const Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(Icons.content_cut, size: 140, color: _kGold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _nextGapLabel(),
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onOpenSchedule,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _kGold),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Open Schedule',
                          style: TextStyle(
                            color: _kGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? _kGold : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 16, color: filled ? Colors.black : _kText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.black : _kText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(user.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: _kGoldDim,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: _kText,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

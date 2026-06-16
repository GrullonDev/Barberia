import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/barber/widgets/barber_chrome.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

const Color _kBg = Color(0xFF0B0B0B);
const Color _kSurface = Color(0xFF1C1C1C);
const Color _kSurface2 = Color(0xFF252525);
const Color _kGold = Color(0xFFD4AF37);
const Color _kText = Color(0xFFFFFFFF);
const Color _kMuted = Color(0xFFB8B8B8);
const Color _kBorder = Color(0xFF3A3A3A);

class BarberSchedulePage extends ConsumerStatefulWidget {
  const BarberSchedulePage({super.key});

  @override
  ConsumerState<BarberSchedulePage> createState() => _BarberSchedulePageState();
}

class _BarberSchedulePageState extends ConsumerState<BarberSchedulePage> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
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

    final DateTime nextDay = _selectedDay.add(const Duration(days: 1));
    final List<Booking> appointments =
        all
            .where(
              (Booking b) =>
                  b.barberId == user.id &&
                  b.status != BookingStatus.canceled &&
                  !b.startAt.isBefore(_selectedDay) &&
                  b.startAt.isBefore(nextDay),
            )
            .toList()
          ..sort((Booking a, Booking b) => a.startAt.compareTo(b.startAt));

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kGold,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: () {},
        child: const Icon(Icons.add, size: 32),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: BarberTopBar(name: user.name, photoUrl: user.photoUrl),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'MASTER SCHEDULE',
                              style: TextStyle(
                                color: _kMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('EEEE, MMM d').format(_selectedDay),
                              style: barberHeadingStyle(fontSize: 34),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kGold,
                          side: const BorderSide(color: _kGold),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('View Calendar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _DayStrip(
                    selectedDay: _selectedDay,
                    onSelected: (DateTime day) => setState(() {
                      _selectedDay = DateTime(day.year, day.month, day.day);
                    }),
                  ),
                  const SizedBox(height: 42),
                  Row(
                    children: <Widget>[
                      Text(
                        'APPOINTMENTS (${appointments.length})',
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: Divider(color: _kBorder)),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.tune, color: _kMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (appointments.isEmpty)
                    const _AvailableSlot(time: '12:30')
                  else
                    ...appointments.map(
                      (Booking booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _ScheduleCard(
                          booking: booking,
                          onConfirm: () => ref
                              .read(bookingsProvider.notifier)
                              .updateStatus(
                                booking.id,
                                BookingStatus.confirmed,
                              ),
                          onCheckIn: () => ref
                              .read(bookingsProvider.notifier)
                              .updateStatus(
                                booking.id,
                                BookingStatus.inProgress,
                              ),
                          onCancel: () => ref
                              .read(bookingsProvider.notifier)
                              .updateStatus(
                                booking.id,
                                BookingStatus.canceled,
                                cancelReason: CancelReason.byStaff,
                              ),
                        ),
                      ),
                    ),
                  const _AvailableSlot(time: '12:30'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selectedDay, required this.onSelected});

  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final DateTime monday = selectedDay.subtract(
      Duration(days: selectedDay.weekday - 1),
    );
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (BuildContext context, int index) {
          final DateTime day = monday.add(Duration(days: index));
          final bool selected = DateUtils.isSameDay(day, selectedDay);
          return GestureDetector(
            onTap: () => onSelected(day),
            child: Container(
              width: 82,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF3A310F) : _kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? _kGold : _kBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    DateFormat('EEE').format(day).toUpperCase(),
                    style: TextStyle(
                      color: selected ? _kGold : _kText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected ? _kGold : _kText,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.booking,
    required this.onConfirm,
    required this.onCheckIn,
    required this.onCancel,
  });

  final Booking booking;
  final VoidCallback onConfirm;
  final VoidCallback onCheckIn;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bool pending = booking.status == BookingStatus.pending;
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Container(width: 2, color: _kGold),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: _kSurface2,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _kGold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            pending
                                ? Icons.sentiment_satisfied_alt
                                : Icons.content_cut,
                            color: pending ? _kMuted : _kGold,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                booking.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _kText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                booking.serviceName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _kMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              DateFormat('HH:mm').format(booking.startAt),
                              style: const TextStyle(
                                color: _kText,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StatusPill(status: booking.status),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Divider(color: Color(0xFF303030)),
                    const SizedBox(height: 22),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pending ? _kGold : _kSurface2,
                              foregroundColor: pending ? Colors.black : _kText,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                                side: BorderSide(
                                  color: pending ? _kGold : _kBorder,
                                ),
                              ),
                            ),
                            onPressed: pending ? onConfirm : onCheckIn,
                            icon: Icon(
                              pending
                                  ? Icons.thumb_up_alt_outlined
                                  : Icons.check_circle_outline,
                            ),
                            label: Text(pending ? 'Confirm' : 'Check In'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 72,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: pending
                                  ? const Color(0xFFFF9E8F)
                                  : _kText,
                              side: const BorderSide(color: _kBorder),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            onPressed: pending ? onCancel : () {},
                            child: Icon(
                              pending
                                  ? Icons.cancel_outlined
                                  : Icons.more_horiz,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final String label = switch (status) {
      BookingStatus.pending => 'PENDING',
      BookingStatus.confirmed => 'CONFIRMED',
      BookingStatus.inProgress => 'ACTIVE',
      BookingStatus.done => 'DONE',
      BookingStatus.noShow => 'NO SHOW',
      BookingStatus.canceled => 'CANCELED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: _kGold.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: const TextStyle(color: _kGold, fontSize: 11)),
    );
  }
}

class _AvailableSlot extends StatelessWidget {
  const _AvailableSlot({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _kBorder,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Text(
          '$time - Available Slot',
          style: TextStyle(
            color: _kMuted.withValues(alpha: 0.55),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

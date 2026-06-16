import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/barber/providers/barber_providers.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

// ─── Admin dark palette ───────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0B0B0B);
const Color _kCard = Color(0xFF1A1A1A);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kGold = Color(0xFFD4AF37);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kGray = Color(0xFF888888);
const Color _kOrange = Color(0xFFF59E0B);

class AllBookingsPage extends ConsumerStatefulWidget {
  const AllBookingsPage({super.key});

  @override
  ConsumerState<AllBookingsPage> createState() => _AllBookingsPageState();
}

class _AllBookingsPageState extends ConsumerState<AllBookingsPage> {
  int _filterIdx = 0; // 0 = All, 1 = Today, 2 = Pending

  @override
  Widget build(BuildContext context) {
    final List<Booking> all = ref.watch(bookingsProvider);
    final List<Barber> barbers =
        ref.watch(allBarbersStreamProvider).valueOrNull ?? [];

    final DateTime now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Booking> filtered;
    switch (_filterIdx) {
      case 1:
        filtered = all.where((b) {
          final d = b.startAt;
          return d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        }).toList();
      case 2:
        filtered = all.where((b) => b.status == BookingStatus.pending).toList();
      default:
        filtered = List.of(all);
    }
    filtered.sort((a, b) => b.startAt.compareTo(a.startAt));

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // Header
          const SliverAppBar(
            backgroundColor: _kBg,
            pinned: true,
            automaticallyImplyLeading: false,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings',
                        style: TextStyle(
                          color: _kWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your lounge schedule',
                        style: TextStyle(color: _kGray, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _FilterTabs(
                selected: _filterIdx,
                onTap: (i) => setState(() => _filterIdx = i),
              ),
            ),
          ),

          // List or empty state
          if (filtered.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final Barber? barber = barbers.cast<Barber?>().firstWhere(
                    (b) => b?.id == filtered[i].barberId,
                    orElse: () => null,
                  );
                  return _BookingCard(booking: filtered[i], barber: barber);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Filter tabs ──────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onTap});

  final int selected;
  final void Function(int) onTap;

  static const List<String> _labels = ['All', 'Today', 'Pending'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final bool sel = i == selected;
        return Padding(
          padding: EdgeInsets.only(right: i < _labels.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? _kGold : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: sel ? _kGold : const Color(0xFF2A2A2A),
                ),
              ),
              child: Text(
                _labels[i],
                style: TextStyle(
                  color: sel ? const Color(0xFF0B0B0B) : _kGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.barber});

  final Booking booking;
  final Barber? barber;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel, accentColor) = _statusInfo(booking.status);
    final timeRange =
        '${DateFormat('hh:mm a').format(booking.startAt)} — ${DateFormat('hh:mm a').format(booking.endAt)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: _kCard,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time + status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeRange,
                            style: const TextStyle(
                              color: _kGray,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                          _StatusBadge(label: statusLabel, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Client name
                      Text(
                        booking.customerName,
                        style: const TextStyle(
                          color: _kWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFF2A2A2A), height: 1),
                      const SizedBox(height: 10),
                      // Service + Barber
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SERVICE',
                                  style: TextStyle(
                                    color: _kGray,
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  booking.serviceName,
                                  style: const TextStyle(
                                    color: _kWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (barber != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'BARBER',
                                  style: TextStyle(
                                    color: _kGray,
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  barber!.name,
                                  style: const TextStyle(
                                    color: _kWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      // Details + phone row (only when phone exists)
                      if (booking.customerPhone != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _kBorder),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Details',
                                    style: TextStyle(
                                      color: _kGold,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                border: Border.all(color: _kBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.phone_outlined,
                                color: _kGray,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String, Color) _statusInfo(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return (_kOrange, 'In Progress', _kOrange);
      case BookingStatus.confirmed:
        return (const Color(0xFFE5E5E5), 'Confirmed', _kGold);
      case BookingStatus.done:
        return (_kGray, 'Completed', _kGray);
      case BookingStatus.canceled:
        return (Colors.redAccent, 'Canceled', Colors.redAccent);
      case BookingStatus.pending:
        return (_kGold, 'Pending', _kGold);
      case BookingStatus.noShow:
        return (Colors.orange, 'No Show', Colors.orange);
    }
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: _kGray,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings found',
            style: TextStyle(color: _kGray, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

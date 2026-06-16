import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:barberia/app/router.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/barber/providers/barber_providers.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/config/models/barberia_config.dart';
import 'package:barberia/features/config/providers/barberia_config_providers.dart';

// ─── Admin dark palette ───────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0B0B0B);
const Color _kCard = Color(0xFF1A1A1A);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kGold = Color(0xFFD4AF37);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kGray = Color(0xFF888888);
const Color _kGreen = Color(0xFF22C55E);
const Color _kOrange = Color(0xFFF59E0B);

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authStateProvider);
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final AsyncValue<List<Barber>> barbersAsync = ref.watch(
      allBarbersStreamProvider,
    );
    final AsyncValue<BarberiaConfig> configAsync = ref.watch(
      barberiaConfigProvider,
    );

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime monthStart = DateTime(now.year, now.month);

    bool isActive(Booking b) => b.status != BookingStatus.canceled;

    List<Booking> dayBookings(DateTime d) => bookings
        .where(
          (b) =>
              b.startAt.year == d.year &&
              b.startAt.month == d.month &&
              b.startAt.day == d.day &&
              isActive(b),
        )
        .toList();

    final todayList = dayBookings(today);
    final yesterdayList = dayBookings(yesterday);
    final monthList = bookings
        .where(
          (b) =>
              b.startAt.isAfter(
                monthStart.subtract(const Duration(seconds: 1)),
              ) &&
              isActive(b),
        )
        .toList();

    final todayRevenue = todayList.fold(0.0, (s, b) => s + b.servicePrice);
    final yesterdayRevenue = yesterdayList.fold(
      0.0,
      (s, b) => s + b.servicePrice,
    );
    final monthRevenue = monthList.fold(0.0, (s, b) => s + b.servicePrice);

    final growthPct = yesterdayRevenue > 0
        ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100
        : (todayRevenue > 0 ? 100.0 : 0.0);

    // Sales trend: last 7 days booking counts (normalised)
    final trendRaw = List.generate(7, (i) {
      return dayBookings(
        today.subtract(Duration(days: 6 - i)),
      ).length.toDouble();
    });
    final maxTrend = trendRaw.reduce((a, b) => a > b ? a : b);
    final trendNorm = maxTrend > 0
        ? trendRaw.map((v) => v / maxTrend).toList()
        : List.filled(7, 0.0);
    final trendLabels = List.generate(7, (i) {
      return DateFormat('EEE')
          .format(today.subtract(Duration(days: 6 - i)))
          .substring(0, 3)
          .toUpperCase();
    });

    // Next appointment
    final upcoming =
        bookings.where((b) => b.startAt.isAfter(now) && isActive(b)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final Booking? next = upcoming.isEmpty ? null : upcoming.first;

    // On duty barbers
    final barbers = barbersAsync.valueOrNull ?? <Barber>[];
    final onDuty = barbers.where((b) => b.isAvailable).toList();

    // Greeting
    final firstName = user?.name.split(' ').first.toUpperCase() ?? 'ADMIN';
    final greet = now.hour < 12
        ? 'GOOD MORNING'
        : now.hour < 17
        ? 'GOOD AFTERNOON'
        : 'GOOD EVENING';
    final businessName =
        configAsync.valueOrNull?.businessName.toUpperCase() ?? 'THE GENTLEMAN';

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _AdminAppBar(
            title: businessName,
            avatar: user?.name.isNotEmpty == true
                ? user!.name[0].toUpperCase()
                : 'A',
            onAvatarTap: () => ref.read(authStateProvider.notifier).logout(),
          ),

          // Greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greet, $firstName',
                    style: const TextStyle(
                      color: _kGray,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daily Overview',
                    style: TextStyle(
                      color: _kWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stat cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.payments_outlined,
                      badge: growthPct >= 0
                          ? '+${growthPct.toStringAsFixed(0)}%'
                          : '${growthPct.toStringAsFixed(0)}%',
                      badgeColor: growthPct >= 0 ? _kGreen : Colors.redAccent,
                      label: "TODAY'S\nEARNINGS",
                      value: NumberFormat.currency(
                        symbol: r'$',
                        decimalDigits: 0,
                      ).format(todayRevenue),
                      valueColor: _kGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.track_changes_outlined,
                      badge: '${todayList.length} APPTS',
                      badgeColor: _kGray,
                      label: 'MONTHLY\nEARNINGS',
                      value: NumberFormat.compactCurrency(
                        symbol: r'$',
                      ).format(monthRevenue),
                      valueColor: _kWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sales Trend
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SalesTrendCard(
                normValues: trendNorm,
                labels: trendLabels,
              ),
            ),
          ),

          // Next Appointment
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NEXT APPOINTMENT',
                        style: TextStyle(
                          color: _kWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed(RouteNames.allBookings),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: _kGold,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: _kGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  next == null
                      ? const _EmptyCard('No upcoming appointments')
                      : _NextAppointmentCard(booking: next, barbers: barbers),
                ],
              ),
            ),
          ),

          // On Duty
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ON DUTY',
                    style: TextStyle(
                      color: _kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  onDuty.isEmpty
                      ? const _EmptyCard('No barbers on duty')
                      : SizedBox(
                          height: 158,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: onDuty.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (ctx, i) => _OnDutyCard(
                              barber: onDuty[i],
                              inSession: bookings.any(
                                (b) =>
                                    b.barberId == onDuty[i].id &&
                                    b.status == BookingStatus.inProgress,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _AdminAppBar extends StatelessWidget {
  const _AdminAppBar({
    required this.title,
    required this.avatar,
    required this.onAvatarTap,
  });

  final String title;
  final String avatar;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: _kBg,
      pinned: true,
      toolbarHeight: 64,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: _kWhite),
        onPressed: () {},
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _kGold,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: 3,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _kGold.withValues(alpha: 0.15),
              child: Text(
                avatar,
                style: const TextStyle(
                  color: _kGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String badge;
  final Color badgeColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: _kGold, size: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: _kGray,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sales trend chart ────────────────────────────────────────────────────────

class _SalesTrendCard extends StatelessWidget {
  const _SalesTrendCard({required this.normValues, required this.labels});

  final List<double> normValues;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Trend',
                    style: TextStyle(
                      color: _kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Last 7 Business Days',
                    style: TextStyle(color: _kGray, fontSize: 10),
                  ),
                ],
              ),
              Icon(Icons.trending_up, color: _kGold, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(normValues.length, (i) {
                final v = normValues[i].clamp(0.05, 1.0);
                final isHighlight = normValues[i] >= 0.6;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: v,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isHighlight
                                    ? _kGold
                                    : const Color(0xFF2A2A2A),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        labels[i],
                        style: const TextStyle(
                          color: _kGray,
                          fontSize: 9,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next appointment card ────────────────────────────────────────────────────

String _formatBarberName(String name) {
  final parts = name.trim().split(' ');
  if (parts.length < 2 || parts.last.isEmpty) return name;
  return '${parts.first} ${parts.last[0]}.';
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.booking, required this.barbers});

  final Booking booking;
  final List<Barber> barbers;

  @override
  Widget build(BuildContext context) {
    final Barber? barber = barbers.cast<Barber?>().firstWhere(
      (b) => b?.id == booking.barberId,
      orElse: () => null,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: _kCard,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, color: _kGold),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('h').format(booking.startAt),
                              style: const TextStyle(
                                color: _kWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'a',
                              ).format(booking.startAt).toUpperCase(),
                              style: const TextStyle(
                                color: _kGray,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(
                                color: _kWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              booking.serviceName,
                              style: const TextStyle(
                                color: _kGray,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (barber != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'BARBER',
                              style: TextStyle(
                                color: _kGray,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatBarberName(barber.name),
                              style: const TextStyle(
                                color: _kGold,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
      ),
    );
  }
}

// ─── On Duty card ─────────────────────────────────────────────────────────────

class _OnDutyCard extends StatelessWidget {
  const _OnDutyCard({required this.barber, required this.inSession});

  final Barber barber;
  final bool inSession;

  @override
  Widget build(BuildContext context) {
    final statusColor = inSession ? _kOrange : _kGreen;
    final statusLabel = inSession ? 'IN SESSION' : 'AVAILABLE';

    return SizedBox(
      width: 112,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: barber.photoUrl != null && barber.photoUrl!.isNotEmpty
                      ? Image.network(
                          barber.photoUrl!,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AvatarPlaceholder(name: barber.name),
                        )
                      : _AvatarPlaceholder(name: barber.name),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kCard, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatBarberName(barber.name),
              style: const TextStyle(
                color: _kWhite,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 3),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: _kGold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: _kGray, fontSize: 13),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:barberia/core/l10n/app_localizations.dart';

class AdminPortalPage extends ConsumerStatefulWidget {
  const AdminPortalPage({super.key});

  @override
  ConsumerState<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends ConsumerState<AdminPortalPage> {
  int _currentTabIndex = 0;
  String _bookingFilter = 'All'; // 'All', 'Today', 'Pending'

  StreamSubscription<QuerySnapshot>? _notificationCountSubscription;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  int _unreadNotificationsCount = 0;
  final DateTime _pageOpenTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _listenToNotifications() {
    // Read initial unread notifications count
    _notificationCountSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _unreadNotificationsCount = snapshot.docs.length;
            });
          }
        }, onError: (_) {});

    // Listen to new notifications for in-app SnackBars (created after page opened)
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (!mounted || snapshot.docs.isEmpty) return;

          final doc = snapshot.docs.first;
          final data = doc.data();
          final createdAtVal = data['createdAt'];

          if (createdAtVal is Timestamp) {
            final createdAt = createdAtVal.toDate();
            // Check if notification was created after the page opened (or very close)
            if (createdAt.isAfter(_pageOpenTime)) {
              final String title =
                  data['title'] ??
                  (ref.read(l10nProvider).languageCode == 'es'
                      ? 'Nueva Notificación'
                      : 'New Notification');
              final String message = data['message'] ?? '';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.secondary,
                  duration: const Duration(seconds: 4),
                  content: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: AppColors.onSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title.toUpperCase(),
                              style: GoogleFonts.hankenGrotesk(
                                color: AppColors.onSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              style: GoogleFonts.hankenGrotesk(
                                color: AppColors.onSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final adminName = authState.displayName ?? 'Administrator';
    final config = ref.watch(appConfigProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, adminName, l10n),
      body: _buildBody(adminName, config, l10n),
      bottomNavigationBar: _buildBottomNavBar(l10n),
      floatingActionButton: _currentTabIndex == 1
          ? _buildFAB(context, l10n)
          : null,
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String adminName,
    AppLocalizations l10n,
  ) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLow,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.secondary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.languageCode == 'es'
                    ? 'Menú del salón abierto.'
                    : 'Lounge menu opened.',
              ),
              duration: const Duration(milliseconds: 800),
            ),
          );
        },
      ),
      title: Text(
        'THE GENTLEMAN',
        style: GoogleFonts.playfairDisplay(
          color: AppColors.secondary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
              onPressed: () => _showNotificationsDialog(context, l10n),
            ),
            if (_unreadNotificationsCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_unreadNotificationsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceContainerHigh,
              child: Text(
                adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bottom Navigation Bar ─────────────────────────────────────────
  Widget _buildBottomNavBar(AppLocalizations l10n) {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          activeIcon: const Icon(Icons.dashboard, color: AppColors.secondary),
          label: l10n.get('dashboard'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today_outlined),
          activeIcon: const Icon(
            Icons.calendar_today,
            color: AppColors.secondary,
          ),
          label: l10n.get('bookings_tab'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_outline),
          activeIcon: const Icon(Icons.people, color: AppColors.secondary),
          label: l10n.get('barbers_tab'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings, color: AppColors.secondary),
          label: l10n.get('settings_tab'),
        ),
      ],
    );
  }

  // ─── Floating Action Button (for Bookings Tab) ──────────────────────
  Widget _buildFAB(BuildContext context, AppLocalizations l10n) {
    return FloatingActionButton(
      onPressed: () => _showAddBookingDialog(context, l10n),
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.onSecondary,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: const Icon(Icons.add, size: 28),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  // ─── Body Routing ──────────────────────────────────────────────────
  Widget _buildBody(
    String adminName,
    AppConfigState config,
    AppLocalizations l10n,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab(adminName, config, l10n);
      case 1:
        return _buildBookingsTab(config, l10n);
      case 2:
        return _buildBarbersTab(l10n);
      case 3:
        return _buildSettingsTab(config, l10n);
      default:
        return _buildDashboardTab(adminName, config, l10n);
    }
  }

  // ─── TAB 0: DASHBOARD ──────────────────────────────────────────────
  Widget _buildDashboardTab(
    String adminName,
    AppConfigState config,
    AppLocalizations l10n,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, bookingsSnapshot) {
        final totalBookings = bookingsSnapshot.data?.docs ?? [];

        // Compute earnings per calendar day from completed/finished bookings,
        // so today's total, last week's same weekday, the monthly total and
        // the 7-day trend chart all derive from the same real data.
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final startOfMonth = DateTime(now.year, now.month, 1);
        final earningsByDay = <DateTime, double>{};

        for (var doc in totalBookings) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          final dateVal = data['date'];

          if ((status.toUpperCase() == 'COMPLETED' ||
                  status.toUpperCase() == 'FINISHED') &&
              dateVal is Timestamp) {
            final date = dateVal.toDate();
            final day = DateTime(date.year, date.month, date.day);
            earningsByDay[day] = (earningsByDay[day] ?? 0) + price;
          }
        }

        final todayEarnings = earningsByDay[startOfToday] ?? 0.0;
        final lastWeekSameDayEarnings =
            earningsByDay[startOfToday.subtract(const Duration(days: 7))] ??
            0.0;
        final String earningsBadge = lastWeekSameDayEarnings > 0
            ? '${todayEarnings >= lastWeekSameDayEarnings ? '+' : ''}${(((todayEarnings - lastWeekSameDayEarnings) / lastWeekSameDayEarnings) * 100).toStringAsFixed(0)}%'
            : (todayEarnings > 0 ? '+100%' : '—');

        double monthEarnings = 0.0;
        earningsByDay.forEach((day, value) {
          if (!day.isBefore(startOfMonth)) {
            monthEarnings += value;
          }
        });
        final monthlyProgress = config.monthlyTarget > 0
            ? (monthEarnings / config.monthlyTarget).clamp(0.0, 1.0)
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (l10n.languageCode == 'es'
                        ? 'BUENOS DÍAS, '
                        : 'GOOD MORNING, ') +
                    adminName.toUpperCase(),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.languageCode == 'es' ? 'Resumen Diario' : 'Daily Overview',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Overview Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      icon: Icons.payments_outlined,
                      label: l10n.get('today_earnings'),
                      value:
                          '${config.currencySymbol}${todayEarnings.toStringAsFixed(0)}',
                      badge: earningsBadge,
                      badgeColor: const Color(
                        0xFFE9C349,
                      ).withValues(alpha: 0.15),
                      badgeTextColor: const Color(0xFFE9C349),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDashboardCard(
                      icon: Icons.track_changes_outlined,
                      label: l10n.get('monthly_target').toUpperCase(),
                      value: config.monthlyTarget > 0
                          ? '${config.currencySymbol}${_formatCompactAmount(config.monthlyTarget)}'
                          : '—',
                      badge: config.monthlyTarget > 0
                          ? '${(monthlyProgress * 100).toStringAsFixed(0)}%'
                          : '—',
                      badgeColor: Colors.white.withValues(alpha: 0.08),
                      badgeTextColor: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sales Trend Chart Card
              _buildSalesTrendCard(earningsByDay, l10n),
              const SizedBox(height: AppSpacing.xl),

              // Next Appointment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.languageCode == 'es'
                        ? 'PRÓXIMA CITA'
                        : 'NEXT APPOINTMENT',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentTabIndex = 1; // Go to bookings tab
                      });
                    },
                    child: Text(
                      l10n.languageCode == 'es' ? 'Ver Todo' : 'View All',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildNextAppointmentCard(totalBookings, l10n),
              const SizedBox(height: AppSpacing.xl),

              // Barbers On Duty Section
              Text(
                l10n.languageCode == 'es' ? 'EN TURNO' : 'ON DUTY',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildOnDutyBarbersList(l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required String value,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.secondary, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _weekdayAbbrevEs = [
    'LUN',
    'MAR',
    'MIÉ',
    'JUE',
    'VIE',
    'SÁB',
    'DOM',
  ];
  static const List<String> _weekdayAbbrevEn = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  String _formatCompactAmount(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildSalesTrendCard(
    Map<DateTime, double> earningsByDay,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final last7Days = List.generate(
      7,
      (i) => startOfToday.subtract(Duration(days: 6 - i)),
    );
    final dailyValues = last7Days
        .map((day) => earningsByDay[day] ?? 0.0)
        .toList();
    final maxValue = dailyValues.fold<double>(0, (max, v) => v > max ? v : max);
    final abbrevs = l10n.languageCode == 'es'
        ? _weekdayAbbrevEs
        : _weekdayAbbrevEn;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageCode == 'es'
                        ? 'Tendencia de Ventas'
                        : 'Sales Trend',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.languageCode == 'es'
                        ? 'Últimos 7 Días'
                        : 'Last 7 Days',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.trending_up,
                color: AppColors.secondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Custom Styled Chart
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = last7Days[i];
                final weekdayLabel = abbrevs[day.weekday - 1];
                final heightFactor = maxValue > 0
                    ? (dailyValues[i] / maxValue).clamp(0.04, 1.0)
                    : 0.04;
                return _buildChartBar(
                  weekdayLabel,
                  heightFactor,
                  day == startOfToday,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double percentage, bool isHighlighted) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: percentage,
              child: Container(
                width: 28,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.secondary
                      : AppColors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildNextAppointmentCard(
    List<QueryDocumentSnapshot> bookings,
    AppLocalizations l10n,
  ) {
    // Find the next confirmed/pending booking in Firestore.
    Map<String, dynamic>? nextBooking;
    for (var doc in bookings) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      if (status.toUpperCase() == 'CONFIRMED' ||
          status.toUpperCase() == 'PENDING') {
        nextBooking = data;
        break;
      }
    }

    if (nextBooking == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          l10n.get('no_upcoming_booking'),
          style: GoogleFonts.hankenGrotesk(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      );
    }

    final String time = nextBooking['time'] as String? ?? '--:--';
    final String client = nextBooking['clientName'] as String? ?? 'No Name';
    final String service = nextBooking['service'] as String? ?? 'No Service';
    final String barberName =
        nextBooking['barberName'] as String? ?? 'Unassigned';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gold line on the left
            Container(width: 4, color: AppColors.secondary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Time slot
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: AppRadius.borderRadiusMd,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            time.split(' ')[0],
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            time.contains(' ') ? time.split(' ')[1] : 'AM',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Appointment detail
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            client,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Barber name
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.get('barber').toUpperCase(),
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          barberName,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
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

  Widget _buildOnDutyBarbersList(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'barber')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          );
        }

        final barbers = snapshot.data?.docs ?? [];
        if (barbers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              l10n.languageCode == 'es'
                  ? 'No hay barberos en turno actualmente.'
                  : 'No barbers currently on duty.',
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          );
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: barbers.length,
            itemBuilder: (context, index) {
              final barberDoc = barbers[index];
              final data = barberDoc.data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'Barber';
              final bool isAvailable = data['isAvailable'] ?? true;
              final String specialty = data['specialty'] ?? 'Specialist';

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppRadius.borderRadiusLg,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'B',
                            style: GoogleFonts.playfairDisplay(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surfaceContainerLow,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 9,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable
                          ? (l10n.languageCode == 'es'
                                ? 'DISPONIBLE'
                                : 'AVAILABLE')
                          : (l10n.languageCode == 'es'
                                ? 'EN SESIÓN'
                                : 'IN SESSION'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── TAB 1: BOOKINGS ───────────────────────────────────────────────
  Widget _buildBookingsTab(AppConfigState config, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.gutter,
            AppSpacing.gutter,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('bookings_tab'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.languageCode == 'es'
                    ? 'Gestiona el horario del salón de hoy'
                    : "Manage today's lounge schedule",
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // Filter Tabs
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              _buildFilterChip(
                'All',
                l10n.languageCode == 'es' ? 'Todas' : 'All',
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                'Today',
                l10n.languageCode == 'es' ? 'Hoy' : 'Today',
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                'Pending',
                l10n.languageCode == 'es' ? 'Pendientes' : 'Pending',
              ),
            ],
          ),
        ),

        // Live Bookings List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              // Apply UI filter filters
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] as String? ?? '').toUpperCase();

                if (_bookingFilter == 'Pending') {
                  return status == 'PENDING';
                }

                if (_bookingFilter == 'Today') {
                  final dateVal = data['date'];
                  if (dateVal is Timestamp) {
                    final date = dateVal.toDate();
                    final now = DateTime.now();
                    return date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                  }
                  return true; // if date missing but today filter active, display it for debug
                }

                return true;
              }).toList();

              if (filteredDocs.isEmpty) {
                return _buildBookingsEmptyState(l10n);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final bookingDoc = filteredDocs[index];
                  final data = bookingDoc.data() as Map<String, dynamic>;
                  final String id = bookingDoc.id;
                  final String clientName = data['clientName'] ?? 'No Name';
                  final String serviceName = data['service'] ?? 'No Service';
                  final String barberName = data['barberName'] ?? 'Unassigned';
                  final String time = data['time'] ?? '12:00 PM';
                  final String status = data['status'] ?? 'PENDING';
                  final double price =
                      (data['price'] as num?)?.toDouble() ?? 0.0;

                  return _buildBookingCard(
                    id: id,
                    clientName: clientName,
                    serviceName: serviceName,
                    barberName: barberName,
                    time: time,
                    status: status,
                    price: price,
                    config: config,
                    l10n: l10n,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final bool isSelected = _bookingFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bookingFilter = filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : AppColors.surfaceContainerLow,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.onSecondary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.languageCode == 'es'
                  ? 'No se encontraron reservas'
                  : 'No reservations found',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.languageCode == 'es'
                  ? 'No hay reservas que coincidan con el filtro seleccionado. Puedes registrar una manualmente usando el botón de abajo.'
                  : 'There are no bookings matching the selected filter. You can manually register one using the button below.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required String id,
    required String clientName,
    required String serviceName,
    required String barberName,
    required String time,
    required String status,
    required double price,
    required AppConfigState config,
    required AppLocalizations l10n,
  }) {
    Color statusBg = Colors.white.withValues(alpha: 0.05);
    Color statusText = Colors.white;
    if (status.toUpperCase() == 'CONFIRMED') {
      statusBg = Colors.green.withValues(alpha: 0.15);
      statusText = Colors.green;
    } else if (status.toUpperCase() == 'PENDING') {
      statusBg = AppColors.secondary.withValues(alpha: 0.15);
      statusText = AppColors.secondary;
    } else if (status.toUpperCase() == 'COMPLETED') {
      statusBg = Colors.blue.withValues(alpha: 0.15);
      statusText = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: AppRadius.borderRadiusFull,
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            clientName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get('service').toUpperCase(),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get('barber').toUpperCase(),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      barberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${config.currencySymbol}${price.toStringAsFixed(2)}',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Row(
                children: [
                  if (status.toUpperCase() == 'PENDING') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.secondary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () =>
                          _updateBookingStatus(id, 'CONFIRMED', l10n),
                      child: Text(
                        l10n.languageCode == 'es' ? 'Confirmar' : 'Confirm',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (status.toUpperCase() == 'CONFIRMED') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () =>
                          _updateBookingStatus(id, 'COMPLETED', l10n),
                      child: Text(
                        l10n.languageCode == 'es' ? 'Completar' : 'Complete',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _deleteBooking(id, l10n),
                    child: Text(
                      l10n.get('delete'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateBookingStatus(
    String bookingId,
    String newStatus,
    AppLocalizations l10n,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageCode == 'es'
                ? 'Estado de la reserva actualizado a $newStatus'
                : 'Booking status updated to $newStatus',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageCode == 'es'
                ? 'Error al actualizar estado: $e'
                : 'Error updating status: $e',
          ),
        ),
      );
    }
  }

  void _deleteBooking(String bookingId, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.languageCode == 'es'
              ? '¿Eliminar Reserva?'
              : 'Delete Reservation?',
        ),
        content: Text(
          l10n.languageCode == 'es'
              ? '¿Estás seguro de que deseas eliminar esta reserva permanentemente?'
              : 'Are you sure you want to remove this booking permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.languageCode == 'es' ? 'NO' : 'NO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              l10n.languageCode == 'es' ? 'SÍ, ELIMINAR' : 'YES, DELETE',
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageCode == 'es'
                  ? 'Reserva eliminada exitosamente.'
                  : 'Booking deleted successfully.',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageCode == 'es'
                  ? 'Error al eliminar reserva: $e'
                  : 'Error deleting booking: $e',
            ),
          ),
        );
      }
    }
  }

  // ─── TAB 2: BARBERS ────────────────────────────────────────────────
  Widget _buildBarbersTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.languageCode == 'es'
                          ? 'Nuestros Barberos'
                          : 'Our Barbers',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.languageCode == 'es'
                          ? 'Gestión de Personal'
                          : 'Staff Management',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddEditBarberDialog(context, l10n, null, null),
                icon: const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: AppColors.onSecondary,
                ),
                label: Text(l10n.get('add_new')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                ),
              ),
            ],
          ),
        ),

        // Live Barbers list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'barber')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    l10n.get('no_barbers'),
                    style: GoogleFonts.hankenGrotesk(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                itemCount:
                    docs.length + 1, // Barbers + Performance overview card
                itemBuilder: (context, index) {
                  if (index == docs.length) {
                    // Performance Overview Summary Card at the bottom
                    return _buildPerformanceOverviewCard(l10n);
                  }

                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final String barberId = doc.id;
                  final String name = data['name'] ?? 'No Name';
                  final String specialty = data['specialty'] ?? 'Master Barber';
                  final bool isAvailable = data['isAvailable'] ?? true;
                  final String bio =
                      data['bio'] ?? 'Precision is the only standard.';

                  return _buildBarberCard(
                    id: barberId,
                    name: name,
                    specialty: specialty,
                    isAvailable: isAvailable,
                    bio: bio,
                    data: data,
                    l10n: l10n,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarberCard({
    required String id,
    required String name,
    required String specialty,
    required bool isAvailable,
    required String bio,
    required Map<String, dynamic> data,
    required AppLocalizations l10n,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo placeholder
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'B',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceContainerLow,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          child: Text(
                            l10n.languageCode == 'es' ? 'MAESTRO' : 'MASTER',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          isAvailable
                              ? Icons.check_circle_outline
                              : Icons.schedule,
                          color: isAvailable ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable
                              ? (l10n.languageCode == 'es'
                                    ? 'Disponible'
                                    : 'Available')
                              : (l10n.languageCode == 'es'
                                    ? 'Ocupado'
                                    : 'Busy'),
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: isAvailable ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$bio"',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _showAddEditBarberDialog(context, l10n, data, id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outlineVariant),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Text(
                    l10n.get('edit_profile'),
                    style: GoogleFonts.hankenGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteBarber(id, name, l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverviewCard(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.get('performance_overview'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bar_chart,
                color: AppColors.secondary.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewMetric('94%', l10n.get('satisfaction')),
              Container(width: 1, height: 32, color: AppColors.outlineVariant),
              _buildOverviewMetric('120', l10n.get('weekly_cuts')),
              Container(width: 1, height: 32, color: AppColors.outlineVariant),
              _buildOverviewMetric('4.8', l10n.get('avg_rating')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _deleteBarber(String id, String name, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete_barber_confirm')),
        content: Text(
          l10n.languageCode == 'es'
              ? '¿Estás seguro de que deseas eliminar al barbero "$name" del personal?'
              : 'Are you sure you want to delete barber "$name" from staff?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFunctions.instance.httpsCallable('removeBarber').call(
          <String, dynamic>{'barberId': id},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageCode == 'es'
                  ? 'Barbero "$name" eliminado exitosamente.'
                  : 'Barber "$name" deleted successfully.',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageCode == 'es'
                  ? 'Error al eliminar barbero: $e'
                  : 'Error deleting barber: $e',
            ),
          ),
        );
      }
    }
  }

  // ─── TAB 3: SETTINGS ───────────────────────────────────────────────
  Widget _buildSettingsTab(AppConfigState config, AppLocalizations l10n) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('barberia')
          .snapshots(),
      builder: (context, configSnapshot) {
        final configData =
            configSnapshot.data?.data() as Map<String, dynamic>? ?? {};

        // Parse operating hours or set default
        final int openHour = configData['openHour'] ?? 9;
        final int closeHour = configData['closeHour'] ?? 19;
        final List<dynamic> openDays =
            configData['openDays'] ??
            [true, true, true, true, true, true, false];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.get('settings_title'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Shop Status switches
              Row(
                children: [
                  Expanded(
                    child: _buildSettingSwitchCard(
                      label: l10n.get('shop_status'),
                      valueText: openDays[DateTime.now().weekday - 1]
                          ? (l10n.languageCode == 'es' ? 'ABIERTO' : 'OPEN')
                          : (l10n.languageCode == 'es' ? 'CERRADO' : 'CLOSED'),
                      isActive: openDays[DateTime.now().weekday - 1],
                      onChanged: (val) {
                        _toggleShopStatus(openDays, l10n);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildSettingSwitchCard(
                      label: l10n.get('notifications'),
                      valueText: l10n.languageCode == 'es' ? 'ACTIVADO' : 'ON',
                      isActive: true,
                      onChanged: (val) {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Business Info
              _buildBusinessInfoSection(configData, l10n),
              const SizedBox(height: AppSpacing.lg),

              // App Configuration
              _buildAppConfigurationSection(configData, l10n),
              const SizedBox(height: AppSpacing.lg),

              // Manage Services
              _buildManageServicesSection(config, l10n),
              const SizedBox(height: AppSpacing.lg),

              // Operating Hours
              _buildOperatingHoursSection(openHour, closeHour, openDays, l10n),
              const SizedBox(height: AppSpacing.xl),

              // Delete Account
              OutlinedButton(
                onPressed: () => _handleLogout(context, l10n),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  l10n.get('logout_portal'),
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  '${l10n.get('version')} 2.4.0 (Enterprise Edition)',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingSwitchCard({
    required String label,
    required String valueText,
    required bool isActive,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valueText,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.secondary : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isActive,
            activeThumbColor: AppColors.secondary,
            activeTrackColor: AppColors.secondary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.outline,
            inactiveTrackColor: AppColors.surfaceContainerHigh,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _toggleShopStatus(List<dynamic> openDays, AppLocalizations l10n) async {
    // Toggle current weekday's status in the array
    final weekdayIndex = DateTime.now().weekday - 1;
    final List<bool> newOpenDays = List<bool>.from(
      openDays.map((x) => x as bool),
    );
    newOpenDays[weekdayIndex] = !newOpenDays[weekdayIndex];

    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('barberia')
          .update({'openDays': newOpenDays});
      final String newStatus = newOpenDays[weekdayIndex]
          ? (l10n.languageCode == 'es' ? 'ABIERTO' : 'OPEN')
          : (l10n.languageCode == 'es' ? 'CERRADO' : 'CLOSED');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageCode == 'es'
                ? 'Estado de la tienda actualizado para hoy a $newStatus.'
                : 'Shop status updated for today to $newStatus.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageCode == 'es'
                ? 'Error al actualizar estado: $e'
                : 'Error updating status: $e',
          ),
        ),
      );
    }
  }

  Widget _buildBusinessInfoSection(
    Map<String, dynamic> configData,
    AppLocalizations l10n,
  ) {
    final String shopName =
        configData['businessName'] ?? "The Gentleman's Lounge";
    final String phone = configData['phone'] ?? '+1 (555) 765-4321';
    final String address = configData['address'] ?? '42nd Mayfair Blvd, London';
    final String email = configData['email'] ?? 'concierge@thegentleman.com';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('business_info'),
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    _showEditBusinessInfoDialog(context, configData, l10n),
                child: Text(
                  l10n.get('edit'),
                  style: GoogleFonts.hankenGrotesk(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(l10n.get('shop_name'), shopName),
          const SizedBox(height: 16),
          _buildInfoRow(l10n.get('contact_email'), email),
          const SizedBox(height: 16),
          _buildInfoRow(l10n.get('phone_number'), phone),
          const SizedBox(height: 16),
          _buildInfoRow(l10n.get('location'), address),
        ],
      ),
    );
  }

  Widget _buildAppConfigurationSection(
    Map<String, dynamic> configData,
    AppLocalizations l10n,
  ) {
    final String currentLanguage = configData['language'] ?? 'es';
    final String currentCurrency = configData['currencySymbol'] ?? 'Q';
    final double currentMonthlyTarget =
        (configData['monthlyTarget'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es'
                    ? 'CONFIGURACIÓN DE LA APP'
                    : 'APP CONFIGURATION',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('language_setting'),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentLanguage == 'es' ? 'Español' : 'English',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: currentLanguage,
                dropdownColor: AppColors.surfaceContainerHigh,
                underline: Container(),
                items: const [
                  DropdownMenuItem(
                    value: 'es',
                    child: Text(
                      'Español',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(
                      'English',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (newLang) async {
                  if (newLang != null) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('config')
                          .doc('barberia')
                          .update({'language': newLang});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              newLang == 'es'
                                  ? 'Idioma cambiado a Español.'
                                  : 'Language changed to English.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating language: $e'),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('currency_setting'),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentCurrency,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.secondary,
                ),
                onPressed: () {
                  final currencyController = TextEditingController(
                    text: currentCurrency,
                  );
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        l10n.languageCode == 'es'
                            ? 'Editar Símbolo de Moneda'
                            : 'Edit Currency Symbol',
                      ),
                      content: TextField(
                        controller: currencyController,
                        maxLength: 5,
                        decoration: InputDecoration(
                          labelText: l10n.languageCode == 'es'
                              ? 'Símbolo de Moneda (ej. Q, \$, €)'
                              : 'Currency Symbol (e.g. Q, \$, €)',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.get('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final symbol = currencyController.text.trim();
                            if (symbol.isEmpty) return;
                            try {
                              await FirebaseFirestore.instance
                                  .collection('config')
                                  .doc('barberia')
                                  .update({'currencySymbol': symbol});
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.languageCode == 'es'
                                          ? 'Símbolo de moneda actualizado a "$symbol".'
                                          : 'Currency symbol updated to "$symbol".',
                                    ),
                                  ),
                                  // duration: const Duration(seconds: 2),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: Text(l10n.get('save')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('monthly_target').toUpperCase(),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentMonthlyTarget > 0
                        ? '$currentCurrency${currentMonthlyTarget.toStringAsFixed(0)}'
                        : '—',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.secondary,
                ),
                onPressed: () {
                  final targetController = TextEditingController(
                    text: currentMonthlyTarget > 0
                        ? currentMonthlyTarget.toStringAsFixed(0)
                        : '',
                  );
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.get('edit_monthly_target')),
                      content: TextField(
                        controller: targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              '${l10n.get('monthly_target_label')} ($currentCurrency)',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.get('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final target = double.tryParse(
                              targetController.text.trim(),
                            );
                            if (target == null || target < 0) return;
                            try {
                              await FirebaseFirestore.instance
                                  .collection('config')
                                  .doc('barberia')
                                  .update({'monthlyTarget': target});
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.get('monthly_target_updated'),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: Text(l10n.get('save')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildManageServicesSection(
    AppConfigState config,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('manage_services'),
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              ElevatedButton(
                onPressed: () => _showAddEditServiceDialog(context, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  l10n.get('add_new'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('services')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                );
              }

              final services = snapshot.data?.docs ?? [];
              if (services.isEmpty) {
                return Text(
                  l10n.languageCode == 'es'
                      ? 'Aún no se han agregado servicios.'
                      : 'No services added yet.',
                  style: GoogleFonts.hankenGrotesk(
                    color: AppColors.onSurfaceVariant,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final serviceDoc = services[index];
                  final data = serviceDoc.data() as Map<String, dynamic>;
                  final String serviceId = serviceDoc.id;
                  final String name = data['name'] ?? 'Unnamed Service';
                  final double price =
                      (data['price'] as num?)?.toDouble() ?? 0.0;
                  final int duration = data['durationMinutes'] ?? 30;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: AppRadius.borderRadiusMd,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: AppRadius.borderRadiusMd,
                          ),
                          child: const Icon(
                            Icons.content_cut,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.hankenGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.languageCode == 'es'
                                    ? '$duration min • Precisión de tijera y máquina'
                                    : '$duration mins • Scissor & Clipper precision',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${config.currencySymbol}${price.toStringAsFixed(2)}',
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white60,
                            size: 18,
                          ),
                          onPressed: () => _showAddEditServiceDialog(
                            context,
                            l10n,
                            data,
                            serviceId,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          onPressed: () =>
                              _deleteService(serviceId, name, l10n),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _deleteService(
    String serviceId,
    String name,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.languageCode == 'es' ? '¿Eliminar Servicio?' : 'Delete Service?',
        ),
        content: Text(
          l10n.languageCode == 'es'
              ? '¿Estás seguro de que deseas eliminar el servicio "$name"? Esto afectará las reservas en línea de los clientes.'
              : 'Are you sure you want to remove service "$name"? This will affect online client bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageCode == 'es'
                  ? 'Servicio "$name" eliminado.'
                  : 'Service "$name" deleted.',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.languageCode == 'es'
                  ? 'Error al eliminar servicio: $e'
                  : 'Error deleting service: $e',
            ),
          ),
        );
      }
    }
  }

  Widget _buildOperatingHoursSection(
    int openHour,
    int closeHour,
    List<dynamic> openDays,
    AppLocalizations l10n,
  ) {
    final weekdaysEs = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final weekdaysEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekdays = l10n.languageCode == 'es' ? weekdaysEs : weekdaysEn;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('operating_hours'),
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () => _showOperatingHoursDialog(
                  context,
                  openHour,
                  closeHour,
                  openDays,
                  l10n,
                ),
                child: Text(
                  l10n.get('edit'),
                  style: GoogleFonts.hankenGrotesk(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: weekdays.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final String day = weekdays[index];
              final bool isOpen = openDays[index] as bool;
              final String timeString = isOpen
                  ? "${openHour.toString().padLeft(2, '0')}:00 AM - ${(closeHour > 12 ? closeHour - 12 : closeHour).toString().padLeft(2, '0')}:00 PM"
                  : (l10n.languageCode == 'es' ? 'CERRADO' : 'CLOSED');

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOpen
                          ? Colors.white
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    timeString,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isOpen
                          ? AppColors.secondary
                          : Colors.redAccent.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.languageCode == 'es' ? '¿Cerrar Sesión?' : 'Log Out?'),
        content: Text(
          l10n.languageCode == 'es'
              ? '¿Estás seguro de que deseas cerrar sesión del Portal de Administración?'
              : 'Are you sure you want to log out from the Administrator Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: Text(
              l10n.languageCode == 'es' ? 'CERRAR SESIÓN' : 'LOG OUT',
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  // ─── DIALOGS & SHEET MODALS ─────────────────────────────────────────

  void _showNotificationsDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceContainerLow,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.get('notifications'),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.outlineVariant),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.languageCode == 'es'
                              ? 'No hay notificaciones.'
                              : 'No notifications.',
                          style: GoogleFonts.hankenGrotesk(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final String title =
                            data['title'] ??
                            (l10n.languageCode == 'es'
                                ? 'Nueva Cita'
                                : 'New Appointment');
                        final String message = data['message'] ?? '';
                        final bool read = data['read'] ?? false;
                        final timestamp = data['createdAt'] as Timestamp?;
                        final dateStr = timestamp != null
                            ? '${timestamp.toDate().day}/${timestamp.toDate().month} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                            : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: read
                                ? AppColors.surfaceContainerLowest
                                : AppColors.surfaceContainerHigh.withValues(
                                    alpha: 0.5,
                                  ),
                            border: Border.all(
                              color: read
                                  ? AppColors.outlineVariant.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppColors.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title.toUpperCase(),
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: read
                                            ? Colors.white70
                                            : AppColors.secondary,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                message,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!read)
                                    TextButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('notifications')
                                            .doc(doc.id)
                                            .update({'read': true});
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        l10n.languageCode == 'es'
                                            ? 'Marcar como leída'
                                            : 'Mark as read',
                                        style: GoogleFonts.hankenGrotesk(
                                          color: AppColors.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: AppSpacing.md),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('notifications')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      l10n.get('delete'),
                                      style: GoogleFonts.hankenGrotesk(
                                        color: AppColors.error,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      final batch = FirebaseFirestore.instance.batch();
                      final snapshot = await FirebaseFirestore.instance
                          .collection('notifications')
                          .get();
                      for (var doc in snapshot.docs) {
                        batch.delete(doc.reference);
                      }
                      await batch.commit();
                    },
                    child: Text(
                      l10n.languageCode == 'es' ? 'LIMPIAR TODO' : 'CLEAR ALL',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBusinessInfoDialog(
    BuildContext context,
    Map<String, dynamic> currentConfig,
    AppLocalizations l10n,
  ) {
    final nameController = TextEditingController(
      text: currentConfig['businessName'] ?? "The Gentleman's Lounge",
    );
    final phoneController = TextEditingController(
      text: currentConfig['phone'] ?? '',
    );
    final addressController = TextEditingController(
      text: currentConfig['address'] ?? '',
    );
    final emailController = TextEditingController(
      text: currentConfig['email'] ?? 'concierge@thegentleman.com',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.get('edit_business_info'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.get('shop_name')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: l10n.get('contact_email'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: l10n.get('phone_number'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: l10n.languageCode == 'es'
                      ? 'Dirección/Ubicación'
                      : 'Address/Location',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('config')
                    .doc('barberia')
                    .update({
                      'businessName': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                    });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.languageCode == 'es'
                            ? 'Información de negocio actualizada exitosamente.'
                            : 'Business Info updated successfully.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.languageCode == 'es'
                          ? 'Error al actualizar: $e'
                          : 'Error updating: $e',
                    ),
                  ),
                );
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  void _showAddEditServiceDialog(
    BuildContext context,
    AppLocalizations l10n, [
    Map<String, dynamic>? service,
    String? serviceId,
  ]) {
    final config = ref.read(appConfigProvider);
    final isEdit = service != null;
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final priceController = TextEditingController(
      text: service != null ? (service['price'] as num).toStringAsFixed(2) : '',
    );
    final durationController = TextEditingController(
      text: service != null
          ? (service['durationMinutes'] as num).toString()
          : '30',
    );
    final descController = TextEditingController(
      text: service?['extendedDescription'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEdit
              ? (l10n.languageCode == 'es' ? 'Editar Servicio' : 'Edit Service')
              : (l10n.languageCode == 'es'
                    ? 'Agregar Nuevo Servicio'
                    : 'Add New Service'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.languageCode == 'es'
                      ? 'Nombre del Servicio'
                      : 'Service Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${l10n.get('price')} (${config.currencySymbol})',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.languageCode == 'es'
                      ? 'Duración (Minutos)'
                      : 'Duration (Minutes)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: l10n.languageCode == 'es'
                      ? 'Descripción'
                      : 'Description',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? price = double.tryParse(priceController.text);
              final int? duration = int.tryParse(durationController.text);

              if (nameController.text.isEmpty ||
                  price == null ||
                  duration == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.languageCode == 'es'
                          ? 'Por favor completa todos los campos con formatos correctos.'
                          : 'Please fill all fields with correct formats.',
                    ),
                  ),
                );
                return;
              }

              final Map<String, dynamic> payload = {
                'name': nameController.text.trim(),
                'price': price,
                'durationMinutes': duration,
                'extendedDescription': descController.text.trim(),
                'isActive': true,
                'category': 'hair',
              };

              try {
                if (isEdit) {
                  await FirebaseFirestore.instance
                      .collection('services')
                      .doc(serviceId)
                      .update(payload);
                } else {
                  await FirebaseFirestore.instance
                      .collection('services')
                      .add(payload);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? (l10n.languageCode == 'es'
                                  ? 'Servicio actualizado.'
                                  : 'Service updated.')
                            : (l10n.languageCode == 'es'
                                  ? 'Servicio agregado exitosamente.'
                                  : 'Service added successfully.'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  void _showAddEditBarberDialog(
    BuildContext context,
    AppLocalizations l10n, [
    Map<String, dynamic>? barber,
    String? barberId,
  ]) {
    final isEdit = barber != null;
    final nameController = TextEditingController(text: barber?['name'] ?? '');
    final specialtyController = TextEditingController(
      text: barber?['specialty'] ?? 'Master Barber',
    );
    final bioController = TextEditingController(
      text: barber?['bio'] ?? 'Precision is the only standard.',
    );
    final emailController = TextEditingController(text: barber?['email'] ?? '');
    bool isAvailable = barber?['isAvailable'] ?? true;
    String? errorText;
    final rootMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(
            isEdit
                ? l10n.get('edit_barber')
                : (l10n.languageCode == 'es'
                      ? 'Invitar/Agregar Barbero'
                      : 'Invite/Add Barber'),
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.languageCode == 'es'
                        ? 'Nombre Completo del Barbero'
                        : 'Barber Full Name',
                  ),
                ),
                const SizedBox(height: 12),
                if (!isEdit) ...[
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: l10n.languageCode == 'es'
                          ? 'Correo del Barbero'
                          : 'Barber Email',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: specialtyController,
                  decoration: InputDecoration(
                    labelText: l10n.languageCode == 'es'
                        ? 'Especialidad/Título'
                        : 'Specialty/Title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(
                    labelText: l10n.languageCode == 'es'
                        ? 'Biografía Corta'
                        : 'Short Biography',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.languageCode == 'es'
                          ? 'Disponible para Sesiones:'
                          : 'Available for Sessions:',
                    ),
                    Switch(
                      value: isAvailable,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) {
                        setStateBuilder(() {
                          isAvailable = val;
                        });
                      },
                    ),
                  ],
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderRadiusMd,
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    (!isEdit && emailController.text.isEmpty)) {
                  setStateBuilder(() {
                    errorText = l10n.languageCode == 'es'
                        ? 'Por favor completa los campos requeridos.'
                        : 'Please fill required fields.';
                  });
                  return;
                }

                try {
                  if (isEdit) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(barberId)
                        .update({
                          'name': nameController.text.trim(),
                          'specialty': specialtyController.text.trim(),
                          'bio': bioController.text.trim(),
                          'isAvailable': isAvailable,
                        });
                  } else {
                    final result = await FirebaseFunctions.instance
                        .httpsCallable('inviteBarber')
                        .call(<String, dynamic>{
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim().toLowerCase(),
                          'specialty': specialtyController.text.trim(),
                          'bio': bioController.text.trim(),
                          'isAvailable': isAvailable,
                        });
                    final data = Map<String, dynamic>.from(result.data as Map);
                    if (context.mounted) {
                      _showTemporaryPasswordDialog(
                        context,
                        l10n,
                        emailController.text.trim().toLowerCase(),
                        data['temporaryPassword'] as String? ?? '',
                        data['emailSent'] == true,
                        data['reusedAuthUser'] == true,
                      );
                    }
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (!isEdit) return;
                    rootMessenger.showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green.shade600,
                        content: Text(
                          isEdit
                              ? (l10n.languageCode == 'es'
                                    ? 'Perfil actualizado.'
                                    : 'Profile updated.')
                              : (l10n.languageCode == 'es'
                                    ? 'Barbero invitado exitosamente. Revisa el correo o los logs de Functions si SendGrid no esta configurado.'
                                    : 'Barber added successfully.'),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  setStateBuilder(() {
                    errorText = l10n.languageCode == 'es'
                        ? 'Error: no se pudo guardar el barbero. $e'
                        : 'Error: could not save barber. $e';
                  });
                }
              },
              child: Text(l10n.get('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemporaryPasswordDialog(
    BuildContext context,
    AppLocalizations l10n,
    String email,
    String temporaryPassword,
    bool emailSent,
    bool reusedAuthUser,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.languageCode == 'es'
              ? 'Credenciales temporales'
              : 'Temporary credentials',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.languageCode == 'es'
                  ? 'Comparte esta contrasena con el barbero. Al iniciar sesion se le pedira cambiarla.'
                  : 'Share this password with the barber. They will be required to change it on first login.',
            ),
            const SizedBox(height: 12),
            SelectableText('Correo: $email'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: AppRadius.borderRadiusMd,
                border: Border.all(color: AppColors.secondary),
              ),
              child: SelectableText(
                temporaryPassword,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              emailSent
                  ? (l10n.languageCode == 'es'
                        ? 'Tambien se intento enviar por correo.'
                        : 'An email invitation was also attempted.')
                  : (l10n.languageCode == 'es'
                        ? 'No se pudo enviar correo automaticamente. Usa el boton copiar.'
                        : 'Automatic email was not sent. Use copy instead.'),
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (reusedAuthUser) ...[
              const SizedBox(height: 8),
              Text(
                l10n.languageCode == 'es'
                    ? 'Este correo ya existia; se genero una nueva contrasena temporal.'
                    : 'This email already existed; a new temporary password was generated.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      'Correo: $email\nContrasena temporal: $temporaryPassword',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credenciales copiadas.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(l10n.languageCode == 'es' ? 'COPIAR' : 'COPY'),
          ),
        ],
      ),
    );
  }

  void _showOperatingHoursDialog(
    BuildContext context,
    int openHour,
    int closeHour,
    List<dynamic> openDays,
    AppLocalizations l10n,
  ) {
    int localOpen = openHour;
    int localClose = closeHour;
    List<bool> localDays = List<bool>.from(openDays.map((x) => x as bool));
    final weekdaysEs = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final weekdaysEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final weekdays = l10n.languageCode == 'es' ? weekdaysEs : weekdaysEn;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(
            l10n.get('operating_hours_settings'),
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l10n.get('open_hour')} (AM):'),
                    DropdownButton<int>(
                      value: localOpen,
                      dropdownColor: AppColors.surfaceContainerHigh,
                      items: List.generate(12, (index) => index + 1).map((h) {
                        return DropdownMenuItem<int>(
                          value: h,
                          child: Text('$h:00 AM'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setStateBuilder(() => localOpen = val);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l10n.get('close_hour')} (PM):'),
                    DropdownButton<int>(
                      value: localClose > 12 ? localClose - 12 : localClose,
                      dropdownColor: AppColors.surfaceContainerHigh,
                      items: List.generate(12, (index) => index + 1).map((h) {
                        return DropdownMenuItem<int>(
                          value: h,
                          child: Text('$h:00 PM'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateBuilder(() => localClose = val + 12);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.get('days_open'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(weekdays.length, (index) {
                    return CheckboxListTile(
                      title: Text(weekdays[index]),
                      value: localDays[index],
                      activeColor: AppColors.secondary,
                      onChanged: (val) {
                        if (val != null) {
                          setStateBuilder(() => localDays[index] = val);
                        }
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('config')
                      .doc('barberia')
                      .update({
                        'openHour': localOpen,
                        'closeHour': localClose,
                        'openDays': localDays,
                      });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.languageCode == 'es'
                              ? 'Horario de atención actualizado.'
                              : 'Operating Hours updated.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.languageCode == 'es'
                            ? 'Error al actualizar: $e'
                            : 'Error updating: $e',
                      ),
                    ),
                  );
                }
              },
              child: Text(l10n.get('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBookingDialog(BuildContext context, AppLocalizations l10n) {
    final config = ref.read(appConfigProvider);
    final clientController = TextEditingController();
    final serviceController = TextEditingController();
    final priceController = TextEditingController(text: '50');
    final timeController = TextEditingController(text: '10:00 AM');
    String? selectedBarberName;

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'barber')
            .snapshots(),
        builder: (context, barberSnapshot) {
          final barbersList = barberSnapshot.data?.docs ?? [];
          final barberNames = barbersList
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['name'] as String? ??
                    'Barber',
              )
              .toList();

          return StatefulBuilder(
            builder: (context, setStateBuilder) => AlertDialog(
              title: Text(
                l10n.languageCode == 'es'
                    ? 'Registrar Reserva'
                    : 'Register Booking',
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clientController,
                      decoration: InputDecoration(
                        labelText: l10n.languageCode == 'es'
                            ? 'Nombre del Cliente'
                            : 'Client Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: serviceController,
                      decoration: InputDecoration(
                        labelText: l10n.languageCode == 'es'
                            ? 'Nombre del Servicio'
                            : 'Service Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            '${l10n.get('price')} (${config.currencySymbol})',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: l10n.languageCode == 'es'
                            ? 'Hora (ej. 02:30 PM)'
                            : 'Time (e.g. 02:30 PM)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (barberNames.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        dropdownColor: AppColors.surfaceContainerHigh,
                        decoration: InputDecoration(
                          labelText: l10n.languageCode == 'es'
                              ? 'Barbero Asignado'
                              : 'Assigned Barber',
                        ),
                        initialValue: selectedBarberName,
                        items: barberNames.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateBuilder(() => selectedBarberName = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final double? price = double.tryParse(priceController.text);
                    if (clientController.text.isEmpty ||
                        serviceController.text.isEmpty ||
                        price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.languageCode == 'es'
                                ? 'Por favor completa los campos requeridos con valores válidos.'
                                : 'Please fill required fields with valid values.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .add({
                            'clientName': clientController.text.trim(),
                            'service': serviceController.text.trim(),
                            'price': price,
                            'time': timeController.text.trim(),
                            'barberName': selectedBarberName ?? 'Unassigned',
                            'status': 'CONFIRMED',
                            'date': FieldValue.serverTimestamp(),
                          });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.languageCode == 'es'
                                  ? 'Reserva registrada exitosamente.'
                                  : 'Booking registered successfully.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding booking: $e')),
                      );
                    }
                  },
                  child: Text(l10n.get('save')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



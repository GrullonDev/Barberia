import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';

class AdminPortalPage extends ConsumerStatefulWidget {
  const AdminPortalPage({super.key});

  @override
  ConsumerState<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends ConsumerState<AdminPortalPage> {
  int _currentTabIndex = 0;
  String _bookingFilter = 'All'; // 'All', 'Today', 'Pending'

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final adminName = authState.displayName ?? 'Administrator';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, adminName),
      body: _buildBody(adminName),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _currentTabIndex == 1 ? _buildFAB() : null,
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, String adminName) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLow,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.secondary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lounge menu opened.'),
              duration: Duration(milliseconds: 800),
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
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          onPressed: () => _showNotificationsDialog(context),
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
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard, color: AppColors.secondary),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today, color: AppColors.secondary),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people, color: AppColors.secondary),
          label: 'Barbers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings, color: AppColors.secondary),
          label: 'Settings',
        ),
      ],
    );
  }

  // ─── Floating Action Button (for Bookings Tab) ──────────────────────
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showAddBookingDialog(context),
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
  Widget _buildBody(String adminName) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab(adminName);
      case 1:
        return _buildBookingsTab();
      case 2:
        return _buildBarbersTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab(adminName);
    }
  }

  // ─── TAB 0: DASHBOARD ──────────────────────────────────────────────
  Widget _buildDashboardTab(String adminName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, bookingsSnapshot) {
        final totalBookings = bookingsSnapshot.data?.docs ?? [];

        // Compute earnings based on finished bookings today
        double todayEarnings = 0.0;
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);

        for (var doc in totalBookings) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          final dateVal = data['date'];

          if (status.toUpperCase() == 'COMPLETED' ||
              status.toUpperCase() == 'FINISHED') {
            if (dateVal is Timestamp) {
              final date = dateVal.toDate();
              if (date.isAfter(startOfToday)) {
                todayEarnings += price;
              }
            }
          }
        }

        // Fallback placeholder values if no bookings exist in Firestore yet
        if (totalBookings.isEmpty) {
          todayEarnings = 1240.0; // matching screenshot $1,240
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'GOOD MORNING, ${adminName.toUpperCase()}',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Daily Overview',
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
                      label: "TODAY'S EARNINGS",
                      value: '\$${todayEarnings.toStringAsFixed(0)}',
                      badge: '+12%',
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
                      label: 'MONTHLY TARGET',
                      value: '\$22.5k',
                      badge: '84%',
                      badgeColor: Colors.white.withValues(alpha: 0.08),
                      badgeTextColor: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sales Trend Chart Card
              _buildSalesTrendCard(),
              const SizedBox(height: AppSpacing.xl),

              // Next Appointment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NEXT APPOINTMENT',
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
                      'View All',
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
              _buildNextAppointmentCard(totalBookings),
              const SizedBox(height: AppSpacing.xl),

              // Barbers On Duty Section
              Text(
                'ON DUTY',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildOnDutyBarbersList(),
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

  Widget _buildSalesTrendCard() {
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
                    'Sales Trend',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Last 7 Business Days',
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
              children: [
                _buildChartBar('MON', 0.25, false),
                _buildChartBar('TUE', 0.45, false),
                _buildChartBar('WED', 0.38, false),
                _buildChartBar('THU', 0.60, false),
                _buildChartBar('FRI', 0.52, true),
                _buildChartBar('SAT', 0.42, false),
                _buildChartBar('SUN', 0.75, true),
              ],
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

  Widget _buildNextAppointmentCard(List<QueryDocumentSnapshot> bookings) {
    // Attempt to find the next booking in Firestore. If none exist, display a beautiful placeholder.
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

    final String time = nextBooking != null
        ? (nextBooking['time'] as String? ?? '10:00 AM')
        : '10:00 AM';
    final String client = nextBooking != null
        ? (nextBooking['clientName'] as String? ?? 'Julian Rossi')
        : 'Julian Rossi';
    final String service = nextBooking != null
        ? (nextBooking['service'] as String? ?? 'Royal Shave & Hot Towel')
        : 'Royal Shave & Hot Towel';
    final String barberName = nextBooking != null
        ? (nextBooking['barberName'] as String? ?? 'Marco V.')
        : 'Marco V.';

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
                          'BARBER',
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

  Widget _buildOnDutyBarbersList() {
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
              'No barbers currently on duty.',
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
                      isAvailable ? 'AVAILABLE' : 'IN SESSION',
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
  Widget _buildBookingsTab() {
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
                'Bookings',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Manage today's lounge schedule",
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
              _buildFilterChip('All'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Today'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Pending'),
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
                return _buildBookingsEmptyState();
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
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _bookingFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bookingFilter = label;
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

  Widget _buildBookingsEmptyState() {
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
              'No reservations found',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no bookings matching the selected filter. You can manually register one using the button below.',
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
                      'SERVICE',
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
                      'BARBER',
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
                '\$${price.toStringAsFixed(2)}',
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
                      onPressed: () => _updateBookingStatus(id, 'CONFIRMED'),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 12),
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
                      onPressed: () => _updateBookingStatus(id, 'COMPLETED'),
                      child: const Text(
                        'Complete',
                        style: TextStyle(fontSize: 12, color: Colors.green),
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
                    onPressed: () => _deleteBooking(id),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
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

  void _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  void _deleteBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reservation?'),
        content: const Text(
          'Are you sure you want to remove this booking permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('YES, DELETE'),
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
          const SnackBar(content: Text('Booking deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting booking: $e')));
      }
    }
  }

  // ─── TAB 2: BARBERS ────────────────────────────────────────────────
  Widget _buildBarbersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Barbers',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Staff Management',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBarberDialog(context),
                icon: const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: AppColors.onSecondary,
                ),
                label: const Text('Add New'),
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
                    'No barbers registered yet.',
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
                    return _buildPerformanceOverviewCard();
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
                            'MASTER',
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
                          isAvailable ? 'Available' : 'Busy',
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
                  onPressed: () => _showAddEditBarberDialog(context, data, id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outlineVariant),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Text(
                    'Edit Profile',
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
                onPressed: () => _deleteBarber(id, name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverviewCard() {
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
                'Performance Overview',
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
              _buildOverviewMetric('94%', 'SATISFACTION'),
              Container(width: 1, height: 32, color: AppColors.outlineVariant),
              _buildOverviewMetric('120', 'WEEKLY CUTS'),
              Container(width: 1, height: 32, color: AppColors.outlineVariant),
              _buildOverviewMetric('4.8', 'AVG RATING'),
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

  void _deleteBarber(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Barber?'),
        content: Text(
          'Are you sure you want to delete barber "$name" from staff?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Barber "$name" deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting barber: $e')));
      }
    }
  }

  // ─── TAB 3: SETTINGS ───────────────────────────────────────────────
  Widget _buildSettingsTab() {
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
                'Settings & Config',
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
                      label: 'SHOP STATUS',
                      valueText: openDays[DateTime.now().weekday - 1]
                          ? 'OPEN'
                          : 'CLOSED',
                      isActive: openDays[DateTime.now().weekday - 1],
                      onChanged: (val) {
                        _toggleShopStatus(openDays);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildSettingSwitchCard(
                      label: 'NOTIFICATIONS',
                      valueText: 'ON',
                      isActive: true,
                      onChanged: (val) {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Business Info
              _buildBusinessInfoSection(configData),
              const SizedBox(height: AppSpacing.lg),

              // Manage Services
              _buildManageServicesSection(),
              const SizedBox(height: AppSpacing.lg),

              // Operating Hours
              _buildOperatingHoursSection(openHour, closeHour, openDays),
              const SizedBox(height: AppSpacing.xl),

              // Delete Account
              OutlinedButton(
                onPressed: () => _handleLogout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'LOG OUT FROM PORTAL',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Version 2.4.0 (Enterprise Edition)',
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
          Column(
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
              const SizedBox(height: 2),
              Text(
                valueText,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.secondary : Colors.white60,
                ),
              ),
            ],
          ),
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

  void _toggleShopStatus(List<dynamic> openDays) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shop status updated for today to ${newOpenDays[weekdayIndex] ? "OPEN" : "CLOSED"}.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  Widget _buildBusinessInfoSection(Map<String, dynamic> configData) {
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
                'BUSINESS INFO',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () => _showEditBusinessInfoDialog(context, configData),
                child: Text(
                  'Edit',
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
          _buildInfoRow('SHOP NAME', shopName),
          const SizedBox(height: 16),
          _buildInfoRow('CONTACT EMAIL', email),
          const SizedBox(height: 16),
          _buildInfoRow('PHONE NUMBER', phone),
          const SizedBox(height: 16),
          _buildInfoRow('LOCATION', address),
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

  Widget _buildManageServicesSection() {
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
                'MANAGE SERVICES',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              ElevatedButton(
                onPressed: () => _showAddEditServiceDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text('Add New', style: TextStyle(fontSize: 11)),
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
                  'No services added yet.',
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
                                '$duration mins • Scissor & Clipper precision',
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
                          '\$${price.toStringAsFixed(2)}',
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
                          onPressed: () => _deleteService(serviceId, name),
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

  void _deleteService(String serviceId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text(
          'Are you sure you want to remove service "$name"? This will affect online client bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Service "$name" deleted.')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting service: $e')));
      }
    }
  }

  Widget _buildOperatingHoursSection(
    int openHour,
    int closeHour,
    List<dynamic> openDays,
  ) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

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
                'OPERATING HOURS',
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
                ),
                child: Text(
                  'Edit',
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
                  : 'CLOSED';

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

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Are you sure you want to log out from the Administrator Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: const Text('LOG OUT'),
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

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new administrator notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditBusinessInfoDialog(
    BuildContext context,
    Map<String, dynamic> currentConfig,
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
          'Edit Business Info',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Shop Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Contact Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address/Location',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
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
                    const SnackBar(
                      content: Text('Business Info updated successfully.'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showAddEditServiceDialog(
    BuildContext context, [
    Map<String, dynamic>? service,
    String? serviceId,
  ]) {
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
          isEdit ? 'Edit Service' : 'Add New Service',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price (\$)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (Minutes)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? price = double.tryParse(priceController.text);
              final int? duration = int.tryParse(durationController.text);

              if (nameController.text.isEmpty ||
                  price == null ||
                  duration == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill all fields with correct formats.',
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
                            ? 'Service updated.'
                            : 'Service added successfully.',
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
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showAddEditBarberDialog(
    BuildContext context, [
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(
            isEdit ? 'Edit Barber Profile' : 'Invite/Add Barber',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Barber Full Name',
                  ),
                ),
                const SizedBox(height: 12),
                if (!isEdit) ...[
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Barber Email',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Specialty/Title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'Short Biography',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available for Sessions:'),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    (!isEdit && emailController.text.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill required fields.'),
                    ),
                  );
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
                    // Create direct barber user doc in Firestore (normally handles via Auth invitation,
                    // here we create a dummy document in users collection)
                    final String uid = FirebaseFirestore.instance
                        .collection('users')
                        .doc()
                        .id;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .set({
                          'id': uid,
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim().toLowerCase(),
                          'role': 'barber',
                          'specialty': specialtyController.text.trim(),
                          'bio': bioController.text.trim(),
                          'isAvailable': isAvailable,
                          'createdAt': FieldValue.serverTimestamp(),
                          'isAnonymous': false,
                          'inviteStatus': 'accepted',
                        });
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Profile updated.'
                              : 'Barber added successfully.',
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
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOperatingHoursDialog(
    BuildContext context,
    int openHour,
    int closeHour,
    List<dynamic> openDays,
  ) {
    int localOpen = openHour;
    int localClose = closeHour;
    List<bool> localDays = List<bool>.from(openDays.map((x) => x as bool));
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(
            'Edit Operating Hours',
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
                    const Text('Open Hour (AM):'),
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
                    const Text('Close Hour (PM):'),
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
                const Text(
                  'Workdays:',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
              child: const Text('CANCEL'),
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
                      const SnackBar(content: Text('Operating Hours updated.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBookingDialog(BuildContext context) {
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
                'Register Booking',
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clientController,
                      decoration: const InputDecoration(
                        labelText: 'Client Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: serviceController,
                      decoration: const InputDecoration(
                        labelText: 'Service Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time (e.g. 02:30 PM)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (barberNames.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        dropdownColor: AppColors.surfaceContainerHigh,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Barber',
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
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final double? price = double.tryParse(priceController.text);
                    if (clientController.text.isEmpty ||
                        serviceController.text.isEmpty ||
                        price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill required fields with valid values.',
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
                          const SnackBar(
                            content: Text('Booking registered successfully.'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding booking: $e')),
                      );
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

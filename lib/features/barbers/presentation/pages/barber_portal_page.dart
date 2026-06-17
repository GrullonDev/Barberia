import 'dart:async';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class BarberPortalPage extends ConsumerStatefulWidget {
  const BarberPortalPage({super.key});

  @override
  ConsumerState<BarberPortalPage> createState() => _BarberPortalPageState();
}

class _BarberPortalPageState extends ConsumerState<BarberPortalPage> {
  int _currentTabIndex = 0;

  // ─── Shared Interactive State ──────────────────────────────────────────────
  double _dailyEarnings = 482.50;
  int _completedServices = 12;
  final int _totalServices = 16;
  String _selectedDay = 'FRI 27';

  // Active Session State
  Map<String, dynamic>? _activeSession = {
    'clientName': 'Julian Sterling',
    'service': 'Modern Fade & Beard Trim',
    'secondsElapsed': 1461, // 24 mins 21 secs
  };
  Timer? _sessionTimer;

  // Appointments List
  final List<Map<String, dynamic>> _appointments = [
    {
      'id': '1',
      'clientName': 'Marcus Sterling',
      'service': 'Executive Cut & Hot Towel',
      'time': '09:00',
      'status': 'CONFIRMED',
      'checkedIn': false,
      'icon': Icons.content_cut_rounded,
    },
    {
      'id': '2',
      'clientName': 'Julian Rossi',
      'service': 'Beard Sculpt & Shape',
      'time': '10:30',
      'status': 'PENDING',
      'checkedIn': false,
      'icon': Icons.face_rounded,
    },
    {
      'id': '3',
      'clientName': 'Dominic West',
      'service': 'Signature Fade & Trim',
      'time': '11:15',
      'status': 'CONFIRMED',
      'checkedIn': false,
      'icon': Icons.keyboard_rounded, // comb looking comb
    },
  ];

  // Next in Queue list
  final List<Map<String, dynamic>> _queue = [
    {
      'clientName': 'Elias Thorne',
      'service': 'Signature Scissor Cut',
      'time': '14:30',
    },
    {
      'clientName': 'Arthur Vance',
      'service': 'Hot Towel Shave',
      'time': '15:15',
    },
  ];

  // Profile Settings State
  String _bio =
      'With over 15 years of experience in traditional barbering, Julian specializes in precision scissor cuts and classic straight-razor shaves.';
  final List<String> _specialties = [
    'Skin Fade',
    'Hot Towel Shave',
    'Beard Sculpting',
  ];
  bool _pushNotifications = true;
  bool _emailUpdates = false;

  final List<String> _days = [
    'MON 23',
    'TUE 24',
    'WED 25',
    'THU 26',
    'FRI 27',
    'SAT 28',
  ];

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSession != null) {
        setState(() {
          _activeSession!['secondsElapsed'] =
              (_activeSession!['secondsElapsed'] as int) + 1;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper to trigger save feedback
  void _saveProfileChanges() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(context).pop(); // pop loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.secondary,
              content: Text(
                'PROFILE CHANGES SAVED SUCCESSFULLY',
                style: GoogleFonts.hankenGrotesk(
                  color: AppColors.onSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        });
        return Dialog(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'PUBLISHING CHANGES...',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: _buildBody(),
      floatingActionButton: _currentTabIndex == 1 ? _buildFAB() : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ─── Custom Premium AppBar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.secondary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Luxe & Blade menu opened.'),
              duration: Duration(milliseconds: 800),
            ),
          );
        },
      ),
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THE',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  height: 1,
                ),
              ),
              Text(
                'GENTLEMAN',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 1.5),
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(
                'assets/images/barber_julian_vance.png',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bottom Navigation Handler ──────────────────────────────────────────────
  Widget _buildBottomNavBar() {
    // Dynamic Bottom Tabs names & icons to perfectly replicate each mockup!
    if (_currentTabIndex == 0) {
      // Dashboard state items (Image 3)
      return BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_rounded),
            label: 'Earnings',
          ),
        ],
      );
    } else {
      // Bookings, Barbers, and Settings tabs (Images 0, 1, 2)
      return BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut_rounded),
            label: 'Barbers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      );
    }
  }

  // ─── Body Routing ───────────────────────────────────────────────────────────
  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildBookingsTab();
      case 2:
        return _buildBarbersTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }

  // ─── Floating Action Button (Only on bookings tab) ──────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showAddBookingDialog(),
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.onSecondary,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: const Icon(Icons.add, size: 28),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  // ─── TAB 1: Dashboard / Active Session (Image 3) ────────────────────────────
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Session Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Session',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .fade(duration: 800.ms, begin: 0.3, end: 1.0),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'LIVE',
                    style: AppTextStyles.labelSm.copyWith(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActiveSessionCard(),

          const SizedBox(height: AppSpacing.xl),

          // Next in Queue Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next in Queue',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentTabIndex = 1; // Go to Bookings
                  });
                },
                child: Text(
                  'VIEW ALL',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildQueueList(),

          const SizedBox(height: AppSpacing.xl),

          // Daily Performance Section
          Text(
            'Daily Performance',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  icon: Icons.credit_card_rounded,
                  label: 'EARNINGS',
                  value: '\$${_dailyEarnings.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildPerformanceCard(
                  icon: Icons.content_cut_rounded,
                  label: 'SERVICES',
                  value: '$_completedServices / $_totalServices',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Full Timeline Section
          Text(
            'Full Timeline',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTimelineGapCard(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildActiveSessionCard() {
    if (_activeSession == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.secondary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No active session',
              style: AppTextStyles.bodyLg.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                if (_queue.isNotEmpty) {
                  _startSessionFromQueue(0);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No clients in queue.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
              child: const Text('START NEXT QUEUE SLOT'),
            ),
          ],
        ),
      );
    }

    final durationText = _formatDuration(
      _activeSession!['secondsElapsed'] as int,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeSession!['clientName'],
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _activeSession!['service'],
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    durationText,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ELAPSED TIME',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _finishActiveSession(),
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('Finish & Charge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelActiveSession(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  void _finishActiveSession() {
    if (_activeSession == null) {
      return;
    }
    final name = _activeSession!['clientName'];
    final service = _activeSession!['service'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          'SESSION COMPLETE',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Grooming session for $name is finished.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.background,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(service, style: AppTextStyles.bodyMd),
                      Text(
                        '\$45.00',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Charged', style: AppTextStyles.labelMd),
                      Text(
                        '\$45.00',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _dailyEarnings += 45.00;
                _completedServices += 1;
                _activeSession = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment processed successfully.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            child: const Text('CONFIRM CHARGE'),
          ),
        ],
      ),
    );
  }

  void _cancelActiveSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Active Session?'),
        content: const Text(
          'Are you sure you want to cancel the current session? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _activeSession = null;
              });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }

  void _startSessionFromQueue(int index) {
    setState(() {
      final item = _queue.removeAt(index);
      _activeSession = {
        'clientName': item['clientName'],
        'service': item['service'],
        'secondsElapsed': 0,
      };
      _startSessionTimer();
    });
  }

  Widget _buildQueueList() {
    if (_queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'No upcoming queue slots.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: _queue.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  item['time'],
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['clientName'],
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['service'],
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () => _showQueueItemMenu(context, i),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showQueueItemMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.secondary,
              ),
              title: Text('Start Session Now', style: AppTextStyles.labelMd),
              onTap: () {
                Navigator.of(context).pop();
                _startSessionFromQueue(index);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.access_time_rounded,
                color: Colors.blueAccent,
              ),
              title: Text('Delay 10 Minutes', style: AppTextStyles.labelMd),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  final timeParts = _queue[index]['time'].split(':');
                  int hour = int.parse(timeParts[0]);
                  int min = int.parse(timeParts[1]) + 10;
                  if (min >= 60) {
                    hour = (hour + 1) % 24;
                    min -= 60;
                  }
                  _queue[index]['time'] =
                      '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delayed queue item by 10 minutes.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text(
                'Cancel Appointment',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _queue.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment canceled.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 20,
      ),
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
            children: [
              Icon(icon, color: AppColors.secondary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGapCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        image: const DecorationImage(
          image: AssetImage('assets/images/barber_bg_pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderRadiusLg,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Next available gap: 16:00 (30m)',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: SizedBox(
                width: 180,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentTabIndex = 1; // Open Master Schedule
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(
                      color: AppColors.secondary,
                      width: 1.2,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('Open Schedule'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: Master Schedule / Bookings (Images 0 & 1) ──────────────────────
  Widget _buildBookingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subheader row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MASTER SCHEDULE',
                    style: GoogleFonts.hankenGrotesk(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Friday, Oct 27',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _selectCalendarDate(),
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                label: const Text('View Calendar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Horizontal day selector
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final dayStr = _days[index];
                final parts = dayStr.split(' ');
                final weekday = parts[0];
                final dateNum = parts[1];
                final isSelected = _selectedDay == dayStr;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = dayStr;
                    });
                  },
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppRadius.borderRadiusMd,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekday,
                          style: AppTextStyles.labelSm.copyWith(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateNum,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.secondary
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Appointments Title & Divider
          Row(
            children: [
              Text(
                'APPOINTMENTS (${_appointments.length + 1})',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: Divider()),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filter settings opened.')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Interactive Appointments List
          _buildAppointmentsList(),
          const SizedBox(height: 80), // spacer for FAB
        ],
      ),
    );
  }

  void _selectCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 10, 27),
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.secondary,
              onPrimary: AppColors.onSecondary,
              surface: AppColors.surfaceContainerLow,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected date: ${picked.toLocal().toString().split(' ')[0]}',
          ),
        ),
      );
    }
  }

  Widget _buildAppointmentsList() {
    return Column(
      children: [
        ..._appointments.map((apt) => _buildAppointmentCard(apt)),
        // Available Slot Card at 12:30
        _buildAvailableSlotCard('12:30'),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt) {
    final isConfirmed = apt['status'] == 'CONFIRMED';
    final isCheckedIn = apt['checkedIn'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  apt['icon'] as IconData,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt['clientName'],
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      apt['service'],
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Time & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    apt['time'],
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? AppColors.secondary.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isConfirmed
                            ? AppColors.secondary.withValues(alpha: 0.3)
                            : AppColors.outline,
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      apt['status'],
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isConfirmed
                            ? AppColors.secondary
                            : AppColors.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Action Row
          Row(
            children: [
              Expanded(
                child: isConfirmed
                    ? ElevatedButton.icon(
                        onPressed: isCheckedIn
                            ? null
                            : () {
                                setState(() {
                                  apt['checkedIn'] = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${apt['clientName']} checked in.',
                                    ),
                                  ),
                                );
                              },
                        icon: Icon(
                          isCheckedIn
                              ? Icons.check
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: isCheckedIn ? Colors.grey : Colors.white,
                        ),
                        label: Text(isCheckedIn ? 'Checked In' : 'Check In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.04,
                          ),
                          disabledForegroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderRadiusMd,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            apt['status'] = 'CONFIRMED';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Appointment for ${apt['clientName']} confirmed!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 16,
                          color: AppColors.onSecondary,
                        ),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderRadiusMd,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: IconButton(
                  icon: Icon(
                    isConfirmed
                        ? Icons.more_horiz_rounded
                        : Icons.cancel_outlined,
                    color: isConfirmed ? Colors.white : AppColors.error,
                  ),
                  onPressed: () {
                    if (isConfirmed) {
                      _showAppointmentActionMenu(apt);
                    } else {
                      _cancelAppointmentDialog(apt);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSlotCard(String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddBookingDialog(timeSlot: time),
          borderRadius: AppRadius.borderRadiusLg,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$time - Available Slot',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentActionMenu(Map<String, dynamic> apt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.secondary,
              ),
              title: Text('Start Session Now', style: AppTextStyles.labelMd),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _activeSession = {
                    'clientName': apt['clientName'],
                    'service': apt['service'],
                    'secondsElapsed': 0,
                  };
                  _startSessionTimer();
                  _appointments.remove(apt);
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Colors.blueAccent,
              ),
              title: Text('Reschedule Session', style: AppTextStyles.labelMd),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Select a new slot to reschedule.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text(
                'Cancel Appointment',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _cancelAppointmentDialog(apt);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cancelAppointmentDialog(Map<String, dynamic> apt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: Text(
          'Are you sure you want to cancel the appointment for ${apt['clientName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _appointments.remove(apt);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment removed.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }

  void _showAddBookingDialog({String? timeSlot}) {
    final clientNameController = TextEditingController();
    final serviceController = TextEditingController(
      text: 'Signature Cut & Shave',
    );
    final timeController = TextEditingController(text: timeSlot ?? '12:30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          'BOOK NEW CLIENT',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: clientNameController,
              decoration: const InputDecoration(
                labelText: 'Client Name',
                hintText: 'e.g. Liam Neeson',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: serviceController,
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'Time Slot'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (clientNameController.text.isEmpty) return;
              Navigator.of(context).pop();
              setState(() {
                _appointments.add({
                  'id': DateTime.now().toString(),
                  'clientName': clientNameController.text,
                  'service': serviceController.text,
                  'time': timeController.text,
                  'status': 'CONFIRMED',
                  'checkedIn': false,
                  'icon': Icons.content_cut_rounded,
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Client booked successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            child: const Text('BOOK APPOINTMENT'),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: Barbers (Team List) ─────────────────────────────────────────────
  Widget _buildBarbersTab() {
    final List<Map<String, dynamic>> artisans = [
      {
        'name': 'Julian Vane',
        'role': 'Master Barber & Manager',
        'rating': '4.9 (128 reviews)',
        'image': 'assets/images/barber_julian_vance.png',
        'status': 'Active',
      },
      {
        'name': 'Elias Thorne',
        'role': 'Director Barber',
        'rating': '4.8 (94 reviews)',
        'image': 'assets/images/barber_marcus_reed.png',
        'status': 'Active',
      },
      {
        'name': 'Sebastian Vane',
        'role': 'Senior Artisan',
        'rating': '4.7 (104 reviews)',
        'image': 'assets/images/barber_dorian_grey.png',
        'status': 'Active',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Luxe & Blade Team',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Coordinate and review statuses with the lounge artisans.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          ...artisans.map(
            (art) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppRadius.borderRadiusLg,
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage(art['image']),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          art['name'],
                          style: AppTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          art['role'],
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.secondary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              art['rating'],
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: AppRadius.borderRadiusFull,
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 4: Master Profile / Settings (Image 2) ─────────────────────────────
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Master Profile',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Configure your professional presence and availability.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Julian Profile Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadius.borderRadiusLg,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundImage: AssetImage(
                        'assets/images/barber_julian_vance.png',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppColors.onSecondary,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Julian Vane',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        'Executive Manager & Senior Stylist',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.secondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.9 (128 reviews)',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.secondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Biography Section
          Text(
            'PROFESSIONAL BIOGRAPHY',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 1.5,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _bio,
            maxLines: 4,
            style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
            decoration: const InputDecoration(
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => _bio = val,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Specialties section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Specialties',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.content_cut_rounded,
                color: AppColors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._specialties.map(
                (spec) => Chip(
                  label: Text(spec),
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onDeleted: () {
                    setState(() {
                      _specialties.remove(spec);
                    });
                  },
                ),
              ),
              GestureDetector(
                onTap: () => _showAddSpecialtyDialog(),
                child: Chip(
                  backgroundColor: AppColors.background,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add New',
                        style: TextStyle(
                          color: AppColors.secondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Languages Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Languages',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.translate_rounded,
                color: AppColors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('English', style: AppTextStyles.bodyMd),
                    Text(
                      'NATIVE',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Italian', style: AppTextStyles.bodyMd),
                    Text(
                      'FLUENT',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Availability Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Availability',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Column(
              children: [
                _buildAvailabilityRow('Mon', true, '09:00 AM - 06:00 PM'),
                const Divider(height: 16),
                _buildAvailabilityRow('Tue', true, '09:00 AM - 06:00 PM'),
                const Divider(height: 16),
                _buildAvailabilityRow('Sun', false, 'Closed'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Notifications Section
          Text(
            'Notifications',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Push Notifications',
                    style: AppTextStyles.bodyLg.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'New bookings and reminders',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  value: _pushNotifications,
                  activeThumbColor: AppColors.secondary,
                  onChanged: (val) {
                    setState(() {
                      _pushNotifications = val;
                    });
                  },
                ),
                const Divider(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Email Updates',
                    style: AppTextStyles.bodyLg.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Daily schedule & revenue reports',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  value: _emailUpdates,
                  activeThumbColor: AppColors.secondary,
                  onChanged: (val) {
                    setState(() {
                      _emailUpdates = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl * 1.5),

          // Save Button
          ElevatedButton(
            onPressed: () => _saveProfileChanges(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              minimumSize: const Size(double.infinity, 54),
            ),
            child: Text(
              'SAVE CHANGES',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Logout Button
          OutlinedButton(
            onPressed: () => _handleLogout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: AppColors.outlineVariant,
                width: 1.2,
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
            child: Text(
              'LOGOUT',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(String day, bool active, String time) {
    return Row(
      children: [
        Checkbox(
          value: active,
          activeColor: AppColors.secondary,
          checkColor: AppColors.onSecondary,
          onChanged: (val) {},
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          day,
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          time,
          style: AppTextStyles.bodyMd.copyWith(
            color: active
                ? AppColors.onSurfaceVariant
                : AppColors.error.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showAddSpecialtyDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('Add Specialty'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Specialty Name',
            hintText: 'e.g. Buzz Cut',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  _specialties.add(textController.text);
                });
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    ref.read(authProvider.notifier).logout();
    context.go('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out of Staff Portal.')),
    );
  }
}

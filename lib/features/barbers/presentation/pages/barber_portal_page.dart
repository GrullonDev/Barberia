import 'dart:async';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/l10n/app_localizations.dart';

class BarberPortalPage extends ConsumerStatefulWidget {
  const BarberPortalPage({super.key});

  @override
  ConsumerState<BarberPortalPage> createState() => _BarberPortalPageState();
}

class _BarberPortalPageState extends ConsumerState<BarberPortalPage> {
  int _currentTabIndex = 0;

  // ─── Shared Interactive State ──────────────────────────────────────────────
  double _dailyEarnings = 482.50;
  double _servicesEarnings = 395.00;
  double _tipsEarnings = 87.50;
  int _completedServices = 8;
  final int _totalServices = 10;
  String _selectedDay = 'FRI 27';
  String _earningsFilter = 'Today'; // 'Today' or 'Weekly'
  String _clientSearchQuery = '';

  // Active Session / Selected Active Appointment Details State
  Map<String, dynamic>? _selectedActiveAppointment;
  bool _isServiceStarted = false;

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
      'icon': Icons.keyboard_rounded,
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

  // Past Visit Notes for client details
  final List<Map<String, String>> _pastVisitNotes = [
    {
      'note':
          'Prefers a low taper fade with 1.5 on sides. Uses light pomade for a matte finish. Avoid thinning shears on top.',
      'date': 'Oct 14, 2023',
    },
    {
      'note':
          'Discussed switching to a classic side part next time. Trialed the sandalwood beard oil.',
      'date': 'Sept 10, 2023',
    },
  ];

  // Recent Activity Transactions
  final List<Map<String, dynamic>> _recentActivity = [
    {
      'service': 'Executive Fade + Beard',
      'client': 'James Wilson',
      'time': '2:30 PM',
      'price': 65.00,
      'tip': 15.00,
      'icon': Icons.content_cut_rounded,
    },
    {
      'service': 'Straight Razor Shave',
      'client': 'Marcus Reed',
      'time': '1:15 PM',
      'price': 45.00,
      'tip': 10.00,
      'icon': Icons.face_rounded,
    },
    {
      'service': 'Signature Grooming',
      'client': 'Ethan Hunt',
      'time': '11:45 AM',
      'price': 85.00,
      'tip': 20.00,
      'icon': Icons.dry_cleaning_rounded,
    },
  ];

  // Client Registry List
  final List<Map<String, dynamic>> _clients = [
    {
      'name': 'Julian Sterling',
      'status': 'Loyalty Member',
      'visits': '12 Visits',
      'phone': '+1 (555) 234-5678',
      'email': 'julian.s@lounge.com',
      'avatar':
          'assets/images/barber_julian_vance.png', // Fallback or working image
    },
    {
      'name': 'James Wilson',
      'status': 'Regular Client',
      'visits': '8 Visits',
      'phone': '+1 (555) 987-6543',
      'email': 'james.w@lounge.com',
      'avatar': 'assets/images/barber_marcus_reed.png',
    },
    {
      'name': 'Marcus Reed',
      'status': 'VIP Client',
      'visits': '24 Visits',
      'phone': '+1 (555) 456-7890',
      'email': 'marcus.r@lounge.com',
      'avatar': 'assets/images/barber_dorian_grey.png',
    },
    {
      'name': 'Ethan Hunt',
      'status': 'Loyalty Member',
      'visits': '15 Visits',
      'phone': '+1 (555) 111-2222',
      'email': 'ethan.h@lounge.com',
      'avatar': 'assets/images/barber_julian_vance.png',
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

  void _saveProfileChanges(AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.secondary,
              content: Text(
                l10n.languageCode == 'es'
                    ? 'CAMBIOS DE PERFIL GUARDADOS CON ÉXITO'
                    : 'PROFILE CHANGES SAVED SUCCESSFULLY',
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
                  l10n.languageCode == 'es'
                      ? 'PUBLICANDO CAMBIOS...'
                      : 'PUBLISHING CHANGES...',
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
    final l10n = ref.watch(l10nProvider);
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, l10n),
      body: _buildBody(l10n, config),
      floatingActionButton:
          (_currentTabIndex == 1 && _selectedActiveAppointment == null)
          ? _buildFAB(l10n)
          : null,
      bottomNavigationBar: _buildBottomNavBar(l10n),
    );
  }

  // ─── AppBar: "PRO CUTS" styling with avatar ───────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.secondary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.languageCode == 'es'
                    ? 'Menú de Luxe & Blade abierto.'
                    : 'Luxe & Blade menu opened.',
              ),
              duration: const Duration(milliseconds: 800),
            ),
          );
        },
      ),
      title: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 1),
            ),
            child: const CircleAvatar(
              backgroundImage: AssetImage(
                'assets/images/barber_julian_vance.png',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'PRO CUTS',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.languageCode == 'es'
                      ? 'No hay notificaciones nuevas.'
                      : 'No new notifications.',
                ),
              ),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentTabIndex = 4; // Special Index for Profile settings
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 1.5),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(
                  'assets/images/barber_julian_vance.png',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Unifed Bottom Navigation: Dashboard, Schedule, Clients, Earnings ──────
  Widget _buildBottomNavBar(AppLocalizations l10n) {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex == 4
          ? 1
          : _currentTabIndex, // keep schedule/profile tabs mapped properly
      onTap: (index) {
        setState(() {
          _selectedActiveAppointment = null; // Reset sub-screens
          _currentTabIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view_rounded),
          label: l10n.get('dashboard'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today_rounded),
          label: l10n.languageCode == 'es' ? 'Horario' : 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_alt_rounded),
          label: l10n.languageCode == 'es' ? 'Clientes' : 'Clients',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.credit_card_rounded),
          label: l10n.languageCode == 'es' ? 'Ingresos' : 'Earnings',
        ),
      ],
    );
  }

  // ─── Navigation routing switch ──────────────────────────────────────────────
  Widget _buildBody(AppLocalizations l10n, AppConfigState config) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab(l10n, config);
      case 1:
        return _buildScheduleRouterTab(l10n, config);
      case 2:
        return _buildClientsTab(l10n);
      case 3:
        return _buildEarningsPerformanceTab(l10n, config);
      case 4:
        return _buildSettingsTab(l10n); // settings tab via avatar click
      default:
        return _buildDashboardTab(l10n, config);
    }
  }

  Widget _buildFAB(AppLocalizations l10n) {
    return FloatingActionButton(
      onPressed: () => _showAddBookingDialog(l10n),
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.onSecondary,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: const Icon(Icons.add, size: 28),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  // ─── Tab 0: Dashboard (Julian's Active Session + Queue) ─────────────────────
  Widget _buildDashboardTab(AppLocalizations l10n, AppConfigState config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es' ? 'Sesión Activa' : 'Active Session',
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
                    l10n.languageCode == 'es' ? 'EN VIVO' : 'LIVE',
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
          _buildActiveSessionCard(l10n),

          const SizedBox(height: AppSpacing.xl),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es'
                    ? 'Siguiente en Fila'
                    : 'Next in Queue',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentTabIndex = 1;
                  });
                },
                child: Text(
                  l10n.languageCode == 'es' ? 'VER TODO' : 'VIEW ALL',
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
          _buildQueueList(l10n),

          const SizedBox(height: AppSpacing.xl),

          Text(
            l10n.languageCode == 'es'
                ? 'Rendimiento Diario'
                : 'Daily Performance',
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
                  label: l10n.languageCode == 'es' ? 'INGRESOS' : 'EARNINGS',
                  value:
                      '${config.currencySymbol}${_dailyEarnings.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildPerformanceCard(
                  icon: Icons.content_cut_rounded,
                  label: l10n.languageCode == 'es' ? 'SERVICIOS' : 'SERVICES',
                  value: '$_completedServices / $_totalServices',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            l10n.languageCode == 'es'
                ? 'Línea de Tiempo Completa'
                : 'Full Timeline',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTimelineGapCard(l10n),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildActiveSessionCard(AppLocalizations l10n) {
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
              l10n.languageCode == 'es'
                  ? 'Sin sesión activa'
                  : 'No active session',
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
                    SnackBar(
                      content: Text(
                        l10n.languageCode == 'es'
                            ? 'No hay clientes en fila.'
                            : 'No clients in queue.',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
              child: Text(
                l10n.languageCode == 'es'
                    ? 'INICIAR SIGUIENTE TURNO'
                    : 'START NEXT QUEUE SLOT',
              ),
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
                    l10n.languageCode == 'es'
                        ? 'TIEMPO TRANSCURRIDO'
                        : 'ELAPSED TIME',
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
                  onPressed: () {
                    // Open the client details active view in Schedule tab
                    setState(() {
                      _selectedActiveAppointment = {
                        'clientName': _activeSession!['clientName'],
                        'service': _activeSession!['service'],
                        'time': l10n.languageCode == 'es'
                            ? 'Activo Ahora'
                            : 'Active Now',
                        'status': 'LIVE',
                        'id': 'APPT-8821',
                      };
                      _currentTabIndex = 1;
                    });
                  },
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    l10n.languageCode == 'es'
                        ? 'Finalizar y Cobrar'
                        : 'Finish & Charge',
                  ),
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
                  onPressed: () => _cancelActiveSession(l10n),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    l10n.languageCode == 'es' ? 'Cancelar' : 'Cancel',
                  ),
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

  void _cancelActiveSession(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.languageCode == 'es'
              ? '¿Cancelar Sesión Activa?'
              : 'Cancel Active Session?',
        ),
        content: Text(
          l10n.languageCode == 'es'
              ? '¿Estás seguro de que deseas cancelar la sesión actual? Esto no se puede deshacer.'
              : 'Are you sure you want to cancel the current session? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.languageCode == 'es' ? 'NO' : 'NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _activeSession = null;
              });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              l10n.languageCode == 'es' ? 'SÍ, CANCELAR' : 'YES, CANCEL',
            ),
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

  Widget _buildQueueList(AppLocalizations l10n) {
    if (_queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          l10n.languageCode == 'es'
              ? 'No hay turnos próximos en fila.'
              : 'No upcoming queue slots.',
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
                onPressed: () => _showQueueItemMenu(context, i, l10n),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showQueueItemMenu(
    BuildContext context,
    int index,
    AppLocalizations l10n,
  ) {
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
              title: Text(
                l10n.languageCode == 'es'
                    ? 'Iniciar Sesión Ahora'
                    : 'Start Session Now',
                style: AppTextStyles.labelMd,
              ),
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
              title: Text(
                l10n.languageCode == 'es'
                    ? 'Retrasar 10 Minutos'
                    : 'Delay 10 Minutes',
                style: AppTextStyles.labelMd,
              ),
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
                  SnackBar(
                    content: Text(
                      l10n.languageCode == 'es'
                          ? 'Turno retrasado 10 minutos.'
                          : 'Delayed queue item by 10 minutes.',
                    ),
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
                l10n.languageCode == 'es'
                    ? 'Cancelar Cita'
                    : 'Cancel Appointment',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _queue.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.languageCode == 'es'
                          ? 'Cita cancelada.'
                          : 'Appointment canceled.',
                    ),
                  ),
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

  Widget _buildTimelineGapCard(AppLocalizations l10n) {
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
              l10n.languageCode == 'es'
                  ? 'Próximo espacio disponible: 16:00 (30m)'
                  : 'Next available gap: 16:00 (30m)',
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
                      _currentTabIndex = 1;
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
                  child: Text(
                    l10n.languageCode == 'es'
                        ? 'Abrir Horario'
                        : 'Open Schedule',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1 Router: Switches between Master Schedule & Active Appt Detail ────
  Widget _buildScheduleRouterTab(AppLocalizations l10n, AppConfigState config) {
    if (_selectedActiveAppointment != null) {
      return _buildActiveAppointmentDetailScreen(
        _selectedActiveAppointment!,
        l10n,
        config,
      );
    } else {
      return _buildMasterScheduleScreen(l10n);
    }
  }

  // Master Schedule Screen (Tab 1 base list)
  Widget _buildMasterScheduleScreen(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageCode == 'es'
                        ? 'HORARIO MAESTRO'
                        : 'MASTER SCHEDULE',
                    style: GoogleFonts.hankenGrotesk(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.languageCode == 'es'
                        ? 'Viernes, 27 Oct'
                        : 'Friday, Oct 27',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _selectCalendarDate(l10n),
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                label: Text(
                  l10n.languageCode == 'es'
                      ? 'Ver Calendario'
                      : 'View Calendar',
                ),
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

          // Horizontal day list
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

          Row(
            children: [
              Text(
                l10n.languageCode == 'es'
                    ? 'CITAS (${_appointments.length + 1})'
                    : 'APPOINTMENTS (${_appointments.length + 1})',
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
                    SnackBar(
                      content: Text(
                        l10n.languageCode == 'es'
                            ? 'Ajustes de filtro abiertos.'
                            : 'Filter settings opened.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Appointments list
          Column(
            children: [
              ..._appointments.map(
                (apt) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActiveAppointment = {
                        'clientName': apt['clientName'],
                        'service': apt['service'],
                        'time': apt['time'],
                        'status': apt['status'],
                        'id': 'APPT-8821',
                      };
                    });
                  },
                  child: _buildAppointmentCard(apt, l10n),
                ),
              ),
              _buildAvailableSlotCard('12:30', l10n),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _selectCalendarDate(AppLocalizations l10n) async {
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
            l10n.languageCode == 'es'
                ? 'Fecha seleccionada: ${picked.toLocal().toString().split(' ')[0]}'
                : 'Selected date: ${picked.toLocal().toString().split(' ')[0]}',
          ),
        ),
      );
    }
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> apt,
    AppLocalizations l10n,
  ) {
    final isConfirmed = apt['status'] == 'CONFIRMED';
    final isCheckedIn = apt['checkedIn'] as bool;
    final statusLabel = isConfirmed
        ? (l10n.languageCode == 'es' ? 'CONFIRMADA' : 'CONFIRMED')
        : (l10n.languageCode == 'es' ? 'PENDIENTE' : 'PENDING');

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
                      statusLabel,
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
                                      l10n.languageCode == 'es'
                                          ? '${apt['clientName']} llegó.'
                                          : '${apt['clientName']} checked in.',
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
                        label: Text(
                          isCheckedIn
                              ? (l10n.languageCode == 'es'
                                    ? 'Llegó'
                                    : 'Checked In')
                              : (l10n.languageCode == 'es'
                                    ? 'Marcar Llegada'
                                    : 'Check In'),
                        ),
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
                                l10n.languageCode == 'es'
                                    ? '¡Cita de ${apt['clientName']} confirmada!'
                                    : 'Appointment for ${apt['clientName']} confirmed!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 16,
                          color: AppColors.onSecondary,
                        ),
                        label: Text(
                          l10n.languageCode == 'es' ? 'Confirmar' : 'Confirm',
                        ),
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
                      _showAppointmentActionMenu(apt, l10n);
                    } else {
                      _cancelAppointmentDialog(apt, l10n);
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

  Widget _buildAvailableSlotCard(String time, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddBookingDialog(l10n, timeSlot: time),
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
                  l10n.languageCode == 'es'
                      ? '$time - Espacio Disponible'
                      : '$time - Available Slot',
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

  void _showAppointmentActionMenu(
    Map<String, dynamic> apt,
    AppLocalizations l10n,
  ) {
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
              title: Text(
                l10n.languageCode == 'es'
                    ? 'Iniciar Sesión Ahora'
                    : 'Start Session Now',
                style: AppTextStyles.labelMd,
              ),
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
              title: Text(
                l10n.languageCode == 'es'
                    ? 'Reprogramar Sesión'
                    : 'Reschedule Session',
                style: AppTextStyles.labelMd,
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.languageCode == 'es'
                          ? 'Selecciona un nuevo horario para reprogramar.'
                          : 'Select a new slot to reschedule.',
                    ),
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
                l10n.languageCode == 'es'
                    ? 'Cancelar Cita'
                    : 'Cancel Appointment',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _cancelAppointmentDialog(apt, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cancelAppointmentDialog(
    Map<String, dynamic> apt,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.languageCode == 'es' ? '¿Cancelar Cita?' : 'Cancel Appointment?',
        ),
        content: Text(
          l10n.languageCode == 'es'
              ? '¿Estás seguro de que deseas cancelar la cita de ${apt['clientName']}?'
              : 'Are you sure you want to cancel the appointment for ${apt['clientName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.languageCode == 'es' ? 'NO' : 'NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _appointments.remove(apt);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.languageCode == 'es'
                        ? 'Cita eliminada.'
                        : 'Appointment removed.',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              l10n.languageCode == 'es' ? 'SÍ, CANCELAR' : 'YES, CANCEL',
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBookingDialog(AppLocalizations l10n, {String? timeSlot}) {
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
          l10n.languageCode == 'es'
              ? 'RESERVAR NUEVO CLIENTE'
              : 'BOOK NEW CLIENT',
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
              decoration: InputDecoration(
                labelText: l10n.languageCode == 'es'
                    ? 'Nombre del Cliente'
                    : 'Client Name',
                hintText: l10n.languageCode == 'es'
                    ? 'p. ej. Liam Neeson'
                    : 'e.g. Liam Neeson',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: serviceController,
              decoration: InputDecoration(
                labelText: l10n.languageCode == 'es'
                    ? 'Nombre del Servicio'
                    : 'Service Name',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: l10n.languageCode == 'es' ? 'Horario' : 'Time Slot',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.get('cancel')),
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
                SnackBar(
                  content: Text(
                    l10n.languageCode == 'es'
                        ? 'Cliente reservado con éxito.'
                        : 'Client booked successfully.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            child: Text(
              l10n.languageCode == 'es' ? 'RESERVAR CITA' : 'BOOK APPOINTMENT',
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1 SUB-PAGE: Active Appointment Detail Screen (Image 1) ─────────────
  Widget _buildActiveAppointmentDetailScreen(
    Map<String, dynamic> appt,
    AppLocalizations l10n,
    AppConfigState config,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _selectedActiveAppointment = null;
            });
          },
        ),
        title: Text(
          l10n.languageCode == 'es'
              ? 'Detalles de la Cita'
              : 'Appointment Details',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gold Chip Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  color: AppColors.secondary,
                  child: Text(
                    l10n.languageCode == 'es'
                        ? 'CITA ACTIVA'
                        : 'ACTIVE APPOINTMENT',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  appt['id'] ?? '#APPT-8821',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Service Title
            Text(
              'The Signature Cut',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Service details tags (duration, price)
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.languageCode == 'es' ? '45 Minutos' : '45 Minutes',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${config.currencySymbol}65.00',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Client Info Card
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
                  // Client avatar with star overlay
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
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: AppColors.onSecondary,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Client Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appt['clientName'],
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.languageCode == 'es'
                              ? 'Miembro de Lealtad • 12 Visitas'
                              : 'Loyalty Member • 12 Visits',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Phone and Mail Buttons
                  Row(
                    children: [
                      _buildContactButton(Icons.phone_outlined, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.languageCode == 'es'
                                  ? 'Llamando a ${appt['clientName']}...'
                                  : 'Calling ${appt['clientName']}...',
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      _buildContactButton(Icons.mail_outline_rounded, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.languageCode == 'es'
                                  ? 'Enviando mensaje a ${appt['clientName']}...'
                                  : 'Messaging ${appt['clientName']}...',
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Past Visit Notes Title & Clock Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.languageCode == 'es'
                      ? 'NOTAS DE VISITAS PASADAS'
                      : 'PAST VISIT NOTES',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.history,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => _showAddNoteDialog(l10n),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Notes list
            Column(
              children: _pastVisitNotes.map((noteMap) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.secondary, width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '"${noteMap['note']}"',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.onSurface,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        noteMap['date']!,
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xl * 1.5),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isServiceStarted
                        ? null
                        : () {
                            setState(() {
                              _isServiceStarted = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.languageCode == 'es'
                                      ? 'Servicio Iniciado.'
                                      : 'Service Started.',
                                ),
                              ),
                            );
                          },
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: 20,
                      color: _isServiceStarted ? Colors.grey : Colors.white,
                    ),
                    label: Text(
                      _isServiceStarted
                          ? (l10n.languageCode == 'es'
                                ? 'En Progreso'
                                : 'In Progress')
                          : (l10n.languageCode == 'es'
                                ? 'Iniciar Servicio'
                                : 'Start Service'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedActiveAppointment = null;
                        _isServiceStarted = false;

                        // Increment Stats
                        _dailyEarnings += 80.00;
                        _servicesEarnings += 65.00;
                        _tipsEarnings += 15.00;
                        _completedServices += 1;

                        // Remove active appointment from schedule
                        _appointments.removeWhere(
                          (apt) => apt['clientName'] == appt['clientName'],
                        );
                        if (_activeSession != null &&
                            _activeSession!['clientName'] ==
                                appt['clientName']) {
                          _activeSession = null;
                        }

                        // Insert to recent activity
                        _recentActivity.insert(0, {
                          'service': appt['service'],
                          'client': appt['clientName'],
                          'time': l10n.languageCode == 'es'
                              ? 'Ahora Mismo'
                              : 'Just Now',
                          'price': 65.00,
                          'tip': 15.00,
                          'icon': Icons.content_cut_rounded,
                        });
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.languageCode == 'es'
                                ? 'Servicio Completado. Pago procesado con éxito.'
                                : 'Service Completed. Payment processed successfully.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      l10n.languageCode == 'es'
                          ? 'Completar y Cobrar'
                          : 'Complete & Charge',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
      ),
    );
  }

  void _showAddNoteDialog(AppLocalizations l10n) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          l10n.languageCode == 'es'
              ? 'Agregar Nota de Visita'
              : 'Add Visit Note',
        ),
        content: TextField(
          controller: noteController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.languageCode == 'es'
                ? 'Ingresa notas de la visita...'
                : 'Enter visit notes...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                setState(() {
                  _pastVisitNotes.insert(0, {
                    'note': noteController.text,
                    'date': 'Oct 27, 2026',
                  });
                });
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            child: Text(
              l10n.languageCode == 'es' ? 'GUARDAR NOTA' : 'SAVE NOTE',
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: Clients Registry List ──────────────────────────────────────────
  Widget _buildClientsTab(AppLocalizations l10n) {
    final filteredClients = _clients.where((client) {
      return client['name'].toLowerCase().contains(
        _clientSearchQuery.toLowerCase(),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.languageCode == 'es'
                ? 'Registro de Clientes'
                : 'Client Registry',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.languageCode == 'es'
                ? 'Busca lealtad, historial de visitas y datos de contacto.'
                : 'Search loyalty, visit history, and contact details.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Search Bar
          TextField(
            onChanged: (val) {
              setState(() {
                _clientSearchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: l10n.languageCode == 'es'
                  ? 'Buscar clientela...'
                  : 'Search clientele...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.onSurfaceVariant,
              ),
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Clients list
          if (filteredClients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                l10n.languageCode == 'es'
                    ? 'No se encontraron clientes que coincidan con la búsqueda.'
                    : 'No clients found matching search.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          else
            ...filteredClients.map(
              (client) => Container(
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
                      radius: 24,
                      backgroundImage: AssetImage(client['avatar']),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client['name'],
                            style: AppTextStyles.bodyLg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${client['status']} • ${client['visits']}',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.languageCode == 'es'
                                      ? 'Llamando a ${client['name']}...'
                                      : 'Calling ${client['name']}...',
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                          onPressed: () {
                            // Route to schedule detail simulation for this client
                            setState(() {
                              _selectedActiveAppointment = {
                                'clientName': client['name'],
                                'service': 'Signature Cut & Beard Grooming',
                                'time': l10n.languageCode == 'es'
                                    ? 'Perfil de Lealtad'
                                    : 'Loyalty Profile',
                                'status': 'CONFIRMED',
                                'id': 'APPT-8821',
                              };
                              _currentTabIndex = 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── TAB 3: Earnings & Performance Dashboard (Image 0) ──────────────────────
  Widget _buildEarningsPerformanceTab(
    AppLocalizations l10n,
    AppConfigState config,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subheader Performance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es' ? 'Rendimiento' : 'Performance',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Filter Toggle: Today / Weekly
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildFilterToggleOption(
                      'Today',
                      l10n.languageCode == 'es' ? 'Hoy' : 'Today',
                    ),
                    _buildFilterToggleOption(
                      'Weekly',
                      l10n.languageCode == 'es' ? 'Semanal' : 'Weekly',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Total Earnings Card
          _buildTotalEarningsCard(l10n, config),

          const SizedBox(height: AppSpacing.md),

          // Breakdown Cards: Services and Tips
          Row(
            children: [
              Expanded(
                child: _buildBreakdownProgressCard(
                  title: l10n.languageCode == 'es' ? 'SERVICIOS' : 'SERVICES',
                  value:
                      '${config.currencySymbol}${_servicesEarnings.toStringAsFixed(2)}',
                  progressValue:
                      _servicesEarnings / 500.0, // scale to $500 target
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildBreakdownProgressCard(
                  title: l10n.languageCode == 'es' ? 'PROPINAS' : 'TIPS',
                  value:
                      '${config.currencySymbol}${_tipsEarnings.toStringAsFixed(2)}',
                  progressValue: _tipsEarnings / 150.0, // scale to $150 target
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Daily Appointments graph card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es'
                    ? 'Citas Diarias'
                    : 'Daily Appointments',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                l10n.languageCode == 'es'
                    ? '$_completedServices de $_totalServices Completados'
                    : '$_completedServices of $_totalServices Completed',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAppointmentsGraphCard(),

          const SizedBox(height: AppSpacing.xl),

          // Recent Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('recent_activity'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.languageCode == 'es'
                            ? 'Viendo todas las transacciones.'
                            : 'Viewing all transactions.',
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      l10n.languageCode == 'es' ? 'Ver Todo' : 'View All',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.secondary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRecentActivityList(l10n, config),

          const SizedBox(height: AppSpacing.xl),

          // Weekly Goal Card
          _buildWeeklyGoalCard(l10n, config),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildFilterToggleOption(String label, String displayLabel) {
    final isSelected = _earningsFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _earningsFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: Text(
          displayLabel,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected
                ? AppColors.onSecondary
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard(AppLocalizations l10n, AppConfigState config) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.languageCode == 'es'
                    ? 'INGRESOS TOTALES'
                    : 'TOTAL EARNINGS',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${config.currencySymbol}${_dailyEarnings.toStringAsFixed(2)}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.languageCode == 'es'
                        ? '12% más que ayer'
                        : '12% from yesterday',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: AppRadius.borderRadiusMd,
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: AppColors.secondary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownProgressCard({
    required String title,
    required String value,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
          Text(
            title,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 1,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: AppColors.secondary,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsGraphCard() {
    // Custom graphical grid representing scheduling load
    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGraphBar(0.4, false),
                _buildGraphBar(0.8, true), // 11a highlighted
                _buildGraphBar(0.5, false),
                _buildGraphBar(0.3, false),
                _buildGraphBar(0.6, false),
                _buildGraphBar(0.2, false),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGraphLabel('9a', false),
              _buildGraphLabel('11a', true), // Highlighted
              _buildGraphLabel('1p', false),
              _buildGraphLabel('3p', false),
              _buildGraphLabel('5p', false),
              _buildGraphLabel('7p', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphBar(double heightFactor, bool isHighlighted) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 110 * heightFactor,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.secondary
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGraphLabel(String label, bool isHighlighted) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted
                ? AppColors.secondary
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(
    AppLocalizations l10n,
    AppConfigState config,
  ) {
    return Column(
      children: _recentActivity.map((activity) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['service'],
                      style: AppTextStyles.bodyLg.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${activity['client']} • ${activity['time']}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${config.currencySymbol}${(activity['price'] as double).toStringAsFixed(2)}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${config.currencySymbol}${(activity['tip'] as double).toStringAsFixed(2)} ${l10n.languageCode == 'es' ? 'Propina' : 'Tip'}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyGoalCard(AppLocalizations l10n, AppConfigState config) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageCode == 'es' ? 'Meta Semanal' : 'Weekly Goal',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.languageCode == 'es'
                      ? 'Estás a solo 4 citas de alcanzar tu meta semanal de ${config.currencySymbol}2,500.'
                      : 'You\'re only 4 appointments away from reaching your ${config.currencySymbol}2,500 weekly target.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    value: 0.84,
                    backgroundColor: Colors.white12,
                    color: AppColors.secondary,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.05),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.star_outline_rounded,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 4 Settings / Profile view ──────────────────────────────────────────
  Widget _buildSettingsTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.languageCode == 'es' ? 'Perfil Maestro' : 'Master Profile',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.languageCode == 'es'
                ? 'Configura tu presencia profesional y disponibilidad.'
                : 'Configure your professional presence and availability.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

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
                        l10n.languageCode == 'es'
                            ? 'Gerente Ejecutivo y Estilista Senior'
                            : 'Executive Manager & Senior Stylist',
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
                            l10n.languageCode == 'es'
                                ? '4.9 (128 reseñas)'
                                : '4.9 (128 reviews)',
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

          Text(
            l10n.languageCode == 'es'
                ? 'BIOGRAFÍA PROFESIONAL'
                : 'PROFESSIONAL BIOGRAPHY',
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es' ? 'Especialidades' : 'Specialties',
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
                onTap: () => _showAddSpecialtyDialog(l10n),
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
                        l10n.get('add_new'),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es' ? 'Idiomas' : 'Languages',
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
                    Text(
                      l10n.languageCode == 'es' ? 'Inglés' : 'English',
                      style: AppTextStyles.bodyMd,
                    ),
                    Text(
                      l10n.languageCode == 'es' ? 'NATIVO' : 'NATIVE',
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
                    Text(
                      l10n.languageCode == 'es' ? 'Italiano' : 'Italian',
                      style: AppTextStyles.bodyMd,
                    ),
                    Text(
                      l10n.languageCode == 'es' ? 'FLUIDO' : 'FLUENT',
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.languageCode == 'es' ? 'Disponibilidad' : 'Availability',
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
                _buildAvailabilityRow(
                  l10n.languageCode == 'es' ? 'Lun' : 'Mon',
                  true,
                  '09:00 AM - 06:00 PM',
                ),
                const Divider(height: 16),
                _buildAvailabilityRow(
                  l10n.languageCode == 'es' ? 'Mar' : 'Tue',
                  true,
                  '09:00 AM - 06:00 PM',
                ),
                const Divider(height: 16),
                _buildAvailabilityRow(
                  l10n.languageCode == 'es' ? 'Dom' : 'Sun',
                  false,
                  l10n.languageCode == 'es' ? 'Cerrado' : 'Closed',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            l10n.get('notifications'),
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
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.languageCode == 'es'
                          ? 'Notificaciones Push'
                          : 'Push Notifications',
                      style: AppTextStyles.bodyLg.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      l10n.languageCode == 'es'
                          ? 'Nuevas reservas y recordatorios'
                          : 'New bookings and reminders',
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
                ),
                const Divider(height: 16),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.languageCode == 'es'
                          ? 'Actualizaciones por Correo'
                          : 'Email Updates',
                      style: AppTextStyles.bodyLg.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      l10n.languageCode == 'es'
                          ? 'Horario diario e informes de ingresos'
                          : 'Daily schedule & revenue reports',
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
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl * 1.5),

          ElevatedButton(
            onPressed: () => _saveProfileChanges(l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
              minimumSize: const Size(double.infinity, 54),
            ),
            child: Text(
              l10n.languageCode == 'es' ? 'GUARDAR CAMBIOS' : 'SAVE CHANGES',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          OutlinedButton(
            onPressed: () => _handleLogout(l10n),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: AppColors.outlineVariant,
                width: 1.2,
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
            child: Text(
              l10n.languageCode == 'es' ? 'CERRAR SESIÓN' : 'LOGOUT',
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

  void _showAddSpecialtyDialog(AppLocalizations l10n) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(
          l10n.languageCode == 'es' ? 'Agregar Especialidad' : 'Add Specialty',
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.languageCode == 'es'
                ? 'Nombre de la Especialidad'
                : 'Specialty Name',
            hintText: l10n.languageCode == 'es'
                ? 'p. ej. Corte al Rape'
                : 'e.g. Buzz Cut',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.get('cancel')),
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
            child: Text(l10n.languageCode == 'es' ? 'AGREGAR' : 'ADD'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(AppLocalizations l10n) {
    ref.read(authProvider.notifier).logout();
    context.go('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.languageCode == 'es'
              ? 'Sesión cerrada del Portal del Personal.'
              : 'Logged out of Staff Portal.',
        ),
      ),
    );
  }
}

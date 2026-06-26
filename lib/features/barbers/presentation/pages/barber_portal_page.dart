import 'dart:async';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _selectedDay = 'FRI 27';
  String _earningsFilter = 'Today'; // 'Today' or 'Weekly'
  String _clientSearchQuery = '';
  String _barberNameFromDb = '';
  String _specialtyFromDb = '';

  // Total services booked today; derived live from this barber's Firestore bookings.
  int get _totalServices =>
      _appointments.where((apt) => _isOnDate(apt['date'], DateTime.now())).length;

  // Yesterday's completed earnings, used to compute the real day-over-day trend.
  double get _yesterdayEarnings {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _appointments
        .where(
          (apt) =>
              _isOnDate(apt['date'], yesterday) &&
              _isCompletedStatus(apt['status'] as String?),
        )
        .fold<double>(
          0.0,
          (acc, apt) => acc + (apt['price'] as double) + (apt['tip'] as double),
        );
  }

  // This week's completed earnings/services, used by the Earnings tab's "Weekly" filter.
  double get _weeklyServicesEarnings => _appointments
      .where(
        (apt) =>
            _isThisWeek(apt['date']) &&
            _isCompletedStatus(apt['status'] as String?),
      )
      .fold<double>(0.0, (acc, apt) => acc + (apt['price'] as double));

  double get _weeklyTipsEarnings => _appointments
      .where(
        (apt) =>
            _isThisWeek(apt['date']) &&
            _isCompletedStatus(apt['status'] as String?),
      )
      .fold<double>(0.0, (acc, apt) => acc + (apt['tip'] as double));

  int get _weeklyCompletedServices => _appointments
      .where(
        (apt) =>
            _isThisWeek(apt['date']) &&
            _isCompletedStatus(apt['status'] as String?),
      )
      .length;

  int get _weeklyTotalServices =>
      _appointments.where((apt) => _isThisWeek(apt['date'])).length;

  // Active Session / Selected Active Appointment Details State
  Map<String, dynamic>? _selectedActiveAppointment;
  bool _isServiceStarted = false;

  // The booking currently being serviced, derived live from Firestore status == 'LIVE'.
  Map<String, dynamic>? get _activeSession {
    for (final apt in _appointments) {
      if (apt['status'] == 'LIVE') return apt;
    }
    return null;
  }

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

  // Appointments still pending/confirmed/in-progress; completed ones move to the revenue screen.
  List<Map<String, dynamic>> get _activeAppointments => _appointments
      .where(
        (apt) =>
            apt['status'] != 'COMPLETED' && apt['status'] != 'FINISHED',
      )
      .toList();

  // Next in Queue list: real upcoming bookings for this barber that haven't
  // started or finished yet, sorted by time. Items share the same Map
  // references held in `_appointments`, so editing a queue item (delay,
  // check-in) also updates the underlying appointment.
  List<Map<String, dynamic>> get _queue {
    final list = _appointments
        .where(
          (apt) =>
              apt['status'] != 'LIVE' &&
              apt['status'] != 'COMPLETED' &&
              apt['status'] != 'FINISHED' &&
              apt['status'] != 'CANCELLED',
        )
        .toList();
    list.sort(
      (a, b) => (a['time'] as String).compareTo(b['time'] as String),
    );
    return list;
  }

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

  // Recent Activity Transactions: derived from completed bookings in Firestore.
  List<Map<String, dynamic>> get _recentActivity => _appointments
      .where(
        (apt) => apt['status'] == 'COMPLETED' || apt['status'] == 'FINISHED',
      )
      .map(
        (apt) => {
          'service': apt['service'],
          'client': apt['clientName'],
          'time': apt['time'],
          'price': apt['price'] as double,
          'tip': apt['tip'] as double,
          'icon': apt['icon'],
        },
      )
      .toList()
      .reversed
      .toList();

  // Client Registry List — derived live from this barber's actual bookings in Firestore,
  // grouped by client so repeat bookers show an accurate visit count and loyalty tier.
  List<Map<String, dynamic>> get _clients {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final apt in _appointments) {
      final name = (apt['clientName'] as String?)?.trim();
      if (name == null || name.isEmpty || name == 'No Name') continue;
      final email = (apt['clientEmail'] as String?) ?? '';
      final phone = (apt['clientPhone'] as String?) ?? '';
      final key = email.isNotEmpty ? email.toLowerCase() : name.toLowerCase();

      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = {
          'name': name,
          'visitCount': 1,
          'phone': phone,
          'email': email,
        };
      } else {
        existing['visitCount'] = (existing['visitCount'] as int) + 1;
        if (phone.isNotEmpty) existing['phone'] = phone;
        if (email.isNotEmpty) existing['email'] = email;
      }
    }

    return grouped.values.map((client) {
      final visitCount = client['visitCount'] as int;
      final status = visitCount >= 20
          ? 'VIP Client'
          : visitCount >= 10
          ? 'Loyalty Member'
          : 'Regular Client';
      return {
        'name': client['name'],
        'status': status,
        'visits': '$visitCount Visit${visitCount == 1 ? '' : 's'}',
        'phone': client['phone'],
        'email': client['email'],
      };
    }).toList()..sort((a, b) => a['name'].compareTo(b['name']));
  }

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

  // Which days this barber is available; defaults to Mon-Fri until loaded
  // from (or saved to) the 'availability' field on their Firestore user doc.
  final Map<String, bool> _availability = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
    'Sun': false,
  };
  static const List<String> _weekdayOrder = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final List<String> _days = [
    'MON 23',
    'TUE 24',
    'WED 25',
    'THU 26',
    'FRI 27',
    'SAT 28',
  ];

  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  int _unreadNotificationsCount = 0;
  final DateTime _pageOpenTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFirebaseListeners();
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _bookingsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _initFirebaseListeners() {
    final authState = ref.read(authProvider);
    final barberName = authState.displayName ?? 'Julian Vance';
    final currentBarberUid = FirebaseAuth.instance.currentUser?.uid;

    // Listen to current barber user document for live settings details
    if (currentBarberUid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentBarberUid)
          .snapshots()
          .listen((docSnapshot) {
            if (docSnapshot.exists && mounted) {
              final data = docSnapshot.data();
              if (data != null) {
                setState(() {
                  _barberNameFromDb =
                      data['name'] ?? authState.displayName ?? 'Julian Vance';
                  _bio = data['bio'] ?? _bio;
                  _specialtyFromDb =
                      data['specialty'] ?? 'Executive Manager & Senior Stylist';
                  if (data['specialties'] != null) {
                    _specialties.clear();
                    _specialties.addAll(List<String>.from(data['specialties']));
                  }
                  final availabilityData = data['availability'];
                  if (availabilityData is Map) {
                    for (final day in _weekdayOrder) {
                      if (availabilityData[day] is bool) {
                        _availability[day] = availabilityData[day] as bool;
                      }
                    }
                  }
                });
              }
            }
          });
    }

    // 1. Listen to bookings
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .snapshots()
        .listen((snapshot) {
          final List<Map<String, dynamic>> firestoreBookings = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String docBarberName = data['barberName'] ?? '';
            final String docBarberId = data['barberId'] ?? '';

            if (docBarberId == currentBarberUid ||
                docBarberName.toLowerCase() == barberName.toLowerCase() ||
                docBarberId == authState.email) {
              firestoreBookings.add({
                'id': doc.id,
                'clientName': data['clientName'] ?? 'No Name',
                'clientEmail': data['clientEmail'] ?? '',
                'clientPhone': data['clientPhone'] ?? '',
                'service': data['service'] ?? 'Premium Cut',
                'time': data['time'] ?? '10:00 AM',
                'status': data['status'] ?? 'PENDING',
                'checkedIn': data['checkedIn'] as bool? ?? false,
                'icon': Icons.content_cut_rounded,
                'price': (data['price'] as num?)?.toDouble() ?? 50.0,
                'tip': (data['tip'] as num?)?.toDouble() ?? 0.0,
                'date': data['date'],
                'serviceStartedAt': data['serviceStartedAt'],
              });
            }
          }

          if (mounted) {
            setState(() {
              _appointments.clear();
              _appointments.addAll(firestoreBookings);
              // Recalculate today's performance earnings from completed appointments dated today.
              final today = DateTime.now();
              double servicesEarnings = 0.0;
              double tipsEarnings = 0.0;
              int completed = 0;
              for (var apt in _appointments) {
                if (_isOnDate(apt['date'], today) &&
                    _isCompletedStatus(apt['status'] as String?)) {
                  servicesEarnings += apt['price'] as double;
                  tipsEarnings += apt['tip'] as double;
                  completed++;
                }
              }
              _servicesEarnings = servicesEarnings;
              _tipsEarnings = tipsEarnings;
              _dailyEarnings = servicesEarnings + tipsEarnings;
              _completedServices = completed;
            });
          }
        });

    // 2. Listen to notifications count
    FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String docBarberName = data['barberName'] ?? '';
            final String docBarberId = data['barberId'] ?? '';
            if (docBarberName.toLowerCase() == barberName.toLowerCase() ||
                docBarberId == authState.email) {
              count++;
            }
          }
          if (mounted) {
            setState(() {
              _unreadNotificationsCount = count;
            });
          }
        });

    // 3. Listen to new notifications for in-app alert SnackBars
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (!mounted || snapshot.docs.isEmpty) return;

          final doc = snapshot.docs.first;
          final data = doc.data();
          final String docBarberName = data['barberName'] ?? '';
          final String docBarberId = data['barberId'] ?? '';

          if (docBarberName.toLowerCase() == barberName.toLowerCase() ||
              docBarberId == authState.email) {
            final createdAtVal = data['createdAt'];
            if (createdAtVal is Timestamp) {
              final createdAt = createdAtVal.toDate();
              if (createdAt.isAfter(_pageOpenTime)) {
                final String title =
                    data['title'] ??
                    (ref.read(l10nProvider).languageCode == 'es'
                        ? 'Nueva Cita'
                        : 'New Appointment');
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
          }
        });
  }

  // Ticks every second purely to redraw the elapsed-time label, which is
  // computed live from the booking's real 'serviceStartedAt' Firestore timestamp.
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _activeSession != null) {
        setState(() {});
      }
    });
  }

  Future<void> _startLiveSession(String? bookingId) async {
    if (bookingId == null) return;
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'LIVE',
      'checkedIn': true,
      'serviceStartedAt': FieldValue.serverTimestamp(),
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Bookings store time as "09:00 AM" (see booking_page.dart's time slots), so
  // parsing must handle the AM/PM suffix rather than assuming 24-hour "HH:MM".
  ({int hour, int minute}) _parseTime(String timeStr) {
    final cleaned = timeStr.trim().toUpperCase();
    final isPM = cleaned.contains('PM');
    final isAM = cleaned.contains('AM');
    final numericPart = cleaned.replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = numericPart.split(':');
    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPM && hour != 12) hour += 12;
    if (isAM && hour == 12) hour = 0;
    return (hour: hour, minute: minute);
  }

  String _formatNoteDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime12h(int hour24, int minute) {
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatScheduleHeaderDate(DateTime date, AppLocalizations l10n) {
    const weekdaysEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const weekdaysEs = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const monthsEs = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final isSpanish = l10n.languageCode == 'es';
    final weekday = (isSpanish ? weekdaysEs : weekdaysEn)[date.weekday - 1];
    final month = (isSpanish ? monthsEs : monthsEn)[date.month - 1];
    return isSpanish
        ? '$weekday, ${date.day} de $month'
        : '$weekday, $month ${date.day}';
  }

  bool _isOnDate(dynamic dateValue, DateTime day) {
    if (dateValue is! Timestamp) return false;
    final d = dateValue.toDate();
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }

  bool _isThisWeek(dynamic dateValue) {
    if (dateValue is! Timestamp) return false;
    final d = dateValue.toDate();
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return !d.isBefore(startOfWeek) && d.isBefore(endOfWeek);
  }

  bool _isCompletedStatus(String? status) =>
      status == 'COMPLETED' || status == 'FINISHED';

  // Maps internal status values (used for logic comparisons) to a localized
  // display label without altering the underlying status string itself.
  String _localizedStatusLabel(String status, AppLocalizations l10n) {
    final isSpanish = l10n.languageCode == 'es';
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return isSpanish ? 'CONFIRMADA' : 'CONFIRMED';
      case 'PENDING':
        return isSpanish ? 'PENDIENTE' : 'PENDING';
      case 'COMPLETED':
      case 'FINISHED':
        return isSpanish ? 'COMPLETADA' : 'COMPLETED';
      case 'LIVE':
        return isSpanish ? 'EN VIVO' : 'LIVE';
      default:
        return status;
    }
  }

  Future<void> _updateBookingStatus(String? bookingId, String newStatus) async {
    if (bookingId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking status: $e')),
        );
      }
    }
  }

  void _saveProfileChanges(AppLocalizations l10n) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
              'bio': _bio,
              'specialties': _specialties,
              'availability': _availability,
            })
            .then((_) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.secondary,
                  content: Text(
                    l10n.languageCode == 'es'
                        ? 'CAMBIOS DE PERFIL GUARDADOS EXITOSAMENTE'
                        : 'PROFILE CHANGES SAVED SUCCESSFULLY',
                    style: GoogleFonts.hankenGrotesk(
                      color: AppColors.onSecondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              );
            })
            .catchError((e) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.error,
                  content: Text(
                    l10n.languageCode == 'es'
                        ? 'ERROR AL GUARDAR CAMBIOS: $e'
                        : 'ERROR SAVING CHANGES: $e',
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
    final config = ref.watch(appConfigProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, l10n),
      body: _buildBody(config, l10n),
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
            child: CircleAvatar(
              backgroundColor: AppColors.surfaceContainerHigh,
              child: _barberNameFromDb.isNotEmpty
                  ? Text(
                      _barberNameFromDb[0].toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.person, color: AppColors.secondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _barberNameFromDb.isNotEmpty
                ? _barberNameFromDb.toUpperCase()
                : 'PRO CUTS',
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
  Widget _buildBody(AppConfigState config, AppLocalizations l10n) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab(config, l10n);
      case 1:
        return _buildScheduleRouterTab(config, l10n);
      case 2:
        return _buildClientsTab(l10n);
      case 3:
        return _buildEarningsPerformanceTab(config, l10n);
      case 4:
        return _buildSettingsTab(l10n); // settings tab via avatar click
      default:
        return _buildDashboardTab(config, l10n);
    }
  }

  Widget _buildFAB(AppLocalizations l10n) {
    return FloatingActionButton(
      onPressed: () => _showAddBookingDialog(l10n: l10n),
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
  Widget _buildDashboardTab(AppConfigState config, AppLocalizations l10n) {
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
                  label: l10n.languageCode == 'es' ? 'GANANCIAS' : 'EARNINGS',
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
            l10n.languageCode == 'es' ? 'Cronología Completa' : 'Full Timeline',
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

    final startedAtTimestamp = _activeSession!['serviceStartedAt'];
    final startedAt = startedAtTimestamp is Timestamp
        ? startedAtTimestamp.toDate()
        : DateTime.now();
    final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
    final durationText = _formatDuration(
      elapsedSeconds < 0 ? 0 : elapsedSeconds,
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
                      _selectedActiveAppointment = _activeSession;
                      _isServiceStarted = true;
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
              final bookingId = _activeSession?['id'] as String?;
              if (bookingId != null) {
                FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({
                      'status': 'CONFIRMED',
                      'serviceStartedAt': FieldValue.delete(),
                    });
              }
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
    final queue = _queue;
    if (index >= queue.length) return;
    _startLiveSession(queue[index]['id'] as String?);
    _startSessionTimer();
  }

  Widget _buildQueueList(AppLocalizations l10n) {
    if (_queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          l10n.languageCode == 'es'
              ? 'No hay turnos en fila próximamente.'
              : 'No upcoming queue slots.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: _queue.map((item) {
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
                onPressed: () => _showQueueItemMenu(context, item, l10n),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showQueueItemMenu(
    BuildContext context,
    Map<String, dynamic> item,
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
                _startLiveSession(item['id'] as String?);
                _startSessionTimer();
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
                final parsed = _parseTime(item['time'] as String);
                int hour = parsed.hour;
                int min = parsed.minute + 10;
                if (min >= 60) {
                  hour = (hour + 1) % 24;
                  min -= 60;
                }
                final newTime = _formatTime12h(hour, min);
                setState(() {
                  item['time'] = newTime;
                });
                FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(item['id'])
                    .update({'time': newTime});
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
              onTap: () async {
                Navigator.of(context).pop();
                final bookingId = item['id'];
                if (bookingId != null) {
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(bookingId)
                      .delete();
                }
                if (!mounted) return;
                setState(() {
                  _appointments.removeWhere((a) => a['id'] == bookingId);
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
      constraints: const BoxConstraints(minHeight: 200),
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
  Widget _buildScheduleRouterTab(AppConfigState config, AppLocalizations l10n) {
    if (_selectedActiveAppointment != null) {
      return _buildActiveAppointmentDetailScreen(
        _selectedActiveAppointment!,
        config,
        l10n,
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
              Expanded(
                child: Column(
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
                      _formatScheduleHeaderDate(DateTime.now(), l10n),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                    ? 'CITAS (${_activeAppointments.length + 1})'
                    : 'APPOINTMENTS (${_activeAppointments.length + 1})',
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
                            ? 'Configuración de filtros abierta.'
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
              ..._activeAppointments.map(
                (apt) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActiveAppointment = {
                        'clientName': apt['clientName'],
                        'service': apt['service'],
                        'time': apt['time'],
                        'status': apt['status'],
                        'id': apt['id'],
                        'price': apt['price'],
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
                      _localizedStatusLabel(apt['status'], l10n),
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
                                FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(apt['id'])
                                    .update({'checkedIn': true});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.languageCode == 'es'
                                          ? '${apt['clientName']} ha llegado.'
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
                          _updateBookingStatus(apt['id'], 'CONFIRMED');
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
          onTap: () => _showAddBookingDialog(timeSlot: time, l10n: l10n),
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
                      ? '$time - Turno Disponible'
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
                _startLiveSession(apt['id'] as String?);
                _startSessionTimer();
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
                          ? 'Selecciona un nuevo turno para reprogramar.'
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
            onPressed: () async {
              Navigator.of(context).pop();
              final bookingId = apt['id'];
              if (bookingId != null) {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .delete();
              }
              if (!mounted) return;
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

  void _showAddBookingDialog({
    required AppLocalizations l10n,
    String? timeSlot,
  }) {
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
                    ? 'ej. Liam Neeson'
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
            child: Text(l10n.languageCode == 'es' ? 'CANCELAR' : 'CANCEL'),
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
                        ? 'Cliente reservado exitosamente.'
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
    AppConfigState config,
    AppLocalizations l10n,
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
              (appt['service'] as String?) ?? 'Premium Cut',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Service details tags (time slot, price)
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
                      (appt['time'] as String?) ?? '--:--',
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
                      '${config.currencySymbol}${((appt['price'] as double?) ?? 50.0).toStringAsFixed(2)}',
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

            // Client Info Card: status/visits looked up from this client's real booking history.
            Builder(
              builder: (context) {
                final clientName = (appt['clientName'] as String?) ?? '';
                final matchedClient = _clients.firstWhere(
                  (c) =>
                      (c['name'] as String).toLowerCase() ==
                      clientName.toLowerCase(),
                  orElse: () => <String, dynamic>{},
                );
                final clientStatus =
                    (matchedClient['status'] as String?) ?? 'Regular Client';
                final clientVisits =
                    (matchedClient['visits'] as String?) ?? '1 Visit';
                final isVip = clientStatus != 'Regular Client';

                return Container(
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
                      // Client avatar with VIP/Loyalty star overlay
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              clientName.isNotEmpty
                                  ? clientName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          if (isVip)
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
                              clientName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_localizedClientStatus(clientStatus, l10n)} • $clientVisits',
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
                                  ? 'Mensajeando a ${appt['clientName']}...'
                                  : 'Messaging ${appt['clientName']}...',
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                    ],
                  ),
                );
              },
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
                            _startLiveSession(appt['id'] as String?);
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
                      _updateBookingStatus(appt['id'], 'COMPLETED');
                      setState(() {
                        for (var a in _appointments) {
                          if (a['id'] == appt['id']) {
                            a['status'] = 'COMPLETED';
                            break;
                          }
                        }
                        _selectedActiveAppointment = null;
                        _isServiceStarted = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.languageCode == 'es'
                                ? 'Servicio Completado. Pago procesado exitosamente.'
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
            child: Text(l10n.languageCode == 'es' ? 'CANCELAR' : 'CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                setState(() {
                  _pastVisitNotes.insert(0, {
                    'note': noteController.text,
                    'date': _formatNoteDate(DateTime.now()),
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
  String _localizedClientStatus(String status, AppLocalizations l10n) {
    if (l10n.languageCode != 'es') return status;
    switch (status) {
      case 'Loyalty Member':
        return 'Miembro Leal';
      case 'Regular Client':
        return 'Cliente Habitual';
      case 'VIP Client':
        return 'Cliente VIP';
      default:
        return status;
    }
  }

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
                _clientSearchQuery.isEmpty
                    ? (l10n.languageCode == 'es'
                          ? 'Aún no tienes clientes con citas reservadas.'
                          : 'No clients with booked appointments yet.')
                    : (l10n.languageCode == 'es'
                          ? 'No se encontraron clientes que coincidan con la búsqueda.'
                          : 'No clients found matching search.'),
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
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        (client['name'] as String).isNotEmpty
                            ? (client['name'] as String)[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
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
                            '${_localizedClientStatus(client['status'], l10n)} • ${client['visits']}',
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
                            // Open this client's most relevant real booking, if any.
                            final clientName = client['name'] as String;
                            Map<String, dynamic>? match;
                            for (final apt in _appointments) {
                              if ((apt['clientName'] as String).toLowerCase() ==
                                  clientName.toLowerCase()) {
                                match = apt;
                                if (apt['status'] != 'COMPLETED' &&
                                    apt['status'] != 'FINISHED') {
                                  break;
                                }
                              }
                            }
                            if (match != null) {
                              setState(() {
                                _selectedActiveAppointment = match;
                                _currentTabIndex = 1;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.languageCode == 'es'
                                        ? 'No hay citas registradas para ${client['name']}.'
                                        : 'No bookings on record for ${client['name']}.',
                                  ),
                                ),
                              );
                            }
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
    AppConfigState config,
    AppLocalizations l10n,
  ) {
    final isWeekly = _earningsFilter == 'Weekly';
    final displayedServicesEarnings = isWeekly
        ? _weeklyServicesEarnings
        : _servicesEarnings;
    final displayedTipsEarnings = isWeekly ? _weeklyTipsEarnings : _tipsEarnings;
    final displayedTotal = displayedServicesEarnings + displayedTipsEarnings;
    final displayedCompleted = isWeekly
        ? _weeklyCompletedServices
        : _completedServices;
    final displayedTotalServices = isWeekly
        ? _weeklyTotalServices
        : _totalServices;
    // Daily targets scaled up to a weekly target when the "Weekly" filter is active.
    final servicesTarget = isWeekly ? 500.0 * 7 : 500.0;
    final tipsTarget = isWeekly ? 150.0 * 7 : 150.0;

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
          _buildTotalEarningsCard(config, l10n, displayedTotal, isWeekly),

          const SizedBox(height: AppSpacing.md),

          // Breakdown Cards: Services and Tips
          Row(
            children: [
              Expanded(
                child: _buildBreakdownProgressCard(
                  title: l10n.languageCode == 'es' ? 'SERVICIOS' : 'SERVICES',
                  value:
                      '${config.currencySymbol}${displayedServicesEarnings.toStringAsFixed(2)}',
                  progressValue: displayedServicesEarnings / servicesTarget,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildBreakdownProgressCard(
                  title: l10n.languageCode == 'es' ? 'PROPINAS' : 'TIPS',
                  value:
                      '${config.currencySymbol}${displayedTipsEarnings.toStringAsFixed(2)}',
                  progressValue: displayedTipsEarnings / tipsTarget,
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
                    ? '$displayedCompleted de $displayedTotalServices Completadas'
                    : '$displayedCompleted of $displayedTotalServices Completed',
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
          _buildRecentActivityList(config, l10n),

          const SizedBox(height: AppSpacing.xl),

          // Weekly Goal Card
          _buildWeeklyGoalCard(config, l10n),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildFilterToggleOption(String filterKey, String label) {
    final isSelected = _earningsFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _earningsFilter = filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: AppRadius.borderRadiusMd,
        ),
        child: Text(
          label,
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

  Widget _buildTotalEarningsCard(
    AppConfigState config,
    AppLocalizations l10n,
    double total,
    bool isWeekly,
  ) {
    // Real day-over-day trend vs yesterday's completed earnings; the Weekly
    // filter has no prior-period comparison available, so it's omitted there.
    String? trendText;
    IconData trendIcon = Icons.trending_flat_rounded;
    Color trendColor = AppColors.onSurfaceVariant;
    final isSpanish = l10n.languageCode == 'es';

    if (!isWeekly) {
      final yesterday = _yesterdayEarnings;
      if (yesterday > 0) {
        final percentChange = ((total - yesterday) / yesterday) * 100;
        final isUp = percentChange >= 0;
        trendIcon = isUp
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;
        trendColor = isUp ? Colors.greenAccent : Colors.redAccent;
        final pctLabel = '${percentChange.abs().toStringAsFixed(0)}%';
        trendText = isUp
            ? (isSpanish ? '$pctLabel más que ayer' : '$pctLabel from yesterday')
            : (isSpanish
                  ? '$pctLabel menos que ayer'
                  : '$pctLabel down from yesterday');
      } else if (total > 0) {
        trendIcon = Icons.trending_up_rounded;
        trendColor = Colors.greenAccent;
        trendText = isSpanish ? 'Sin ganancias ayer' : 'No earnings yesterday';
      }
    }

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
                isWeekly
                    ? (isSpanish ? 'GANANCIAS SEMANALES' : 'WEEKLY EARNINGS')
                    : (isSpanish ? 'GANANCIAS DE HOY' : 'TODAY\'S EARNINGS'),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${config.currencySymbol}${total.toStringAsFixed(2)}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              if (trendText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(trendIcon, color: trendColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: trendColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
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
    // Buckets today's real bookings into 2-hour windows to show scheduling load.
    const labels = ['9a', '11a', '1p', '3p', '5p', '7p'];
    final bucketCounts = List<int>.filled(6, 0);
    final today = DateTime.now();
    for (final apt in _appointments) {
      if (!_isOnDate(apt['date'], today)) continue;
      final timeStr = apt['time'] as String?;
      if (timeStr == null) continue;
      final hour = _parseTime(timeStr).hour;
      final bucketIndex = ((hour - 9) ~/ 2).clamp(0, 5);
      bucketCounts[bucketIndex]++;
    }
    final maxCount = bucketCounts.reduce((a, b) => a > b ? a : b);
    final highlightIndex = maxCount > 0 ? bucketCounts.indexOf(maxCount) : -1;
    final heights = bucketCounts
        .map((c) => maxCount > 0 ? (c / maxCount).clamp(0.1, 1.0) : 0.05)
        .toList();

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
              children: List.generate(
                6,
                (i) => _buildGraphBar(heights[i], i == highlightIndex),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (i) => _buildGraphLabel(labels[i], i == highlightIndex),
            ),
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
    AppConfigState config,
    AppLocalizations l10n,
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

  // Fixed weekly revenue target; there's no per-barber goal field in Firestore
  // yet, so this constant is the basis for the real progress shown below.
  static const double _weeklyGoalTarget = 2500.0;

  Widget _buildWeeklyGoalCard(AppConfigState config, AppLocalizations l10n) {
    final weeklyTotal = _weeklyServicesEarnings + _weeklyTipsEarnings;
    final remaining = _weeklyGoalTarget - weeklyTotal;
    final avgServiceValue = _weeklyCompletedServices > 0
        ? weeklyTotal / _weeklyCompletedServices
        : 50.0;
    final progress = (weeklyTotal / _weeklyGoalTarget).clamp(0.0, 1.0);
    final isSpanish = l10n.languageCode == 'es';
    final goalMessage = remaining <= 0
        ? (isSpanish
              ? '¡Meta semanal de ${config.currencySymbol}${_weeklyGoalTarget.toStringAsFixed(0)} alcanzada!'
              : 'You\'ve reached your ${config.currencySymbol}${_weeklyGoalTarget.toStringAsFixed(0)} weekly goal!')
        : (() {
            final appointmentsAway = (remaining / avgServiceValue).ceil();
            return isSpanish
                ? 'Solo te faltan $appointmentsAway citas para alcanzar tu meta semanal de ${config.currencySymbol}${_weeklyGoalTarget.toStringAsFixed(0)}.'
                : 'You\'re only $appointmentsAway appointments away from reaching your ${config.currencySymbol}${_weeklyGoalTarget.toStringAsFixed(0)} weekly target.';
          })();

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
                  goalMessage,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
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
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      child: _barberNameFromDb.isNotEmpty
                          ? Text(
                              _barberNameFromDb[0].toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: AppColors.secondary,
                              size: 28,
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
                        _barberNameFromDb.isNotEmpty
                            ? _barberNameFromDb
                            : 'Julian Vance',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        _specialtyFromDb.isNotEmpty
                            ? _specialtyFromDb
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
                for (final day in _weekdayOrder) ...[
                  _buildAvailabilityRow(day, l10n),
                  if (day != _weekdayOrder.last) const Divider(height: 16),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            l10n.languageCode == 'es' ? 'Notificaciones' : 'Notifications',
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
                          ? 'Informes diarios de horario e ingresos'
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

  String _localizedDayAbbrev(String dayKey, AppLocalizations l10n) {
    if (l10n.languageCode != 'es') return dayKey;
    const spanish = {
      'Mon': 'Lun',
      'Tue': 'Mar',
      'Wed': 'Mié',
      'Thu': 'Jue',
      'Fri': 'Vie',
      'Sat': 'Sáb',
      'Sun': 'Dom',
    };
    return spanish[dayKey] ?? dayKey;
  }

  Widget _buildAvailabilityRow(String dayKey, AppLocalizations l10n) {
    final active = _availability[dayKey] ?? false;
    final isSpanish = l10n.languageCode == 'es';
    return Row(
      children: [
        Checkbox(
          value: active,
          activeColor: AppColors.secondary,
          checkColor: AppColors.onSecondary,
          onChanged: (val) {
            setState(() {
              _availability[dayKey] = val ?? false;
            });
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _localizedDayAbbrev(dayKey, l10n),
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          active
              ? '09:00 AM - 06:00 PM'
              : (isSpanish ? 'Cerrado' : 'Closed'),
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
                ? 'ej. Corte a Máquina'
                : 'e.g. Buzz Cut',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.languageCode == 'es' ? 'CANCELAR' : 'CANCEL'),
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

  void _showNotificationsDialog(BuildContext context, AppLocalizations l10n) {
    final authState = ref.read(authProvider);
    final barberName = authState.displayName ?? 'Julian Vance';

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
                    l10n.languageCode == 'es'
                        ? 'NOTIFICACIONES'
                        : 'NOTIFICATIONS',
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
                    final barberDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String docBarberName = data['barberName'] ?? '';
                      final String docBarberId = data['barberId'] ?? '';
                      return docBarberName.toLowerCase() ==
                              barberName.toLowerCase() ||
                          docBarberId == authState.email;
                    }).toList();

                    if (barberDocs.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.languageCode == 'es'
                              ? 'No hay notificaciones para ti.'
                              : 'No notifications for you.',
                          style: GoogleFonts.hankenGrotesk(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: barberDocs.length,
                      itemBuilder: (context, index) {
                        final doc = barberDocs[index];
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
            ],
          ),
        ),
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
              ? 'Sesión cerrada del Portal de Personal.'
              : 'Logged out of Staff Portal.',
        ),
      ),
    );
  }
}

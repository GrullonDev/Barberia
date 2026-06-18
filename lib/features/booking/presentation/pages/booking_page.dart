import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/features/home/presentation/widgets/home_footer.dart';
import 'package:barberia/features/home/presentation/widgets/home_nav_bar.dart';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:barberia/core/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  // Booking Flow State
  int _currentStep = 0; // 0: Barber, 1: Agenda, 2: Resumen, 3: Success
  String? _selectedBarberId;
  Map<String, dynamic>? _selectedBarber;

  String? _selectedService;
  double _selectedServicePrice = 0.0;
  String? _selectedServiceDuration;

  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Controllers for client info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingBarbers = true;
  List<Map<String, dynamic>> _firestoreBarbers = [];

  // Static barbers list as fallback
  final List<Map<String, dynamic>> _fallbackBarbers = [
    {
      'id': 'julian',
      'name': 'Julian Vance',
      'specialty': 'Especialista en Navaja',
      'tag': 'MASTER',
      'image': 'assets/images/barber_julian_vance.png',
      'rating': '4.9',
      'reviews': '124 reseñas',
    },
    {
      'id': 'marcus',
      'name': 'Marcus Reed',
      'specialty': 'Cortes Clásicos',
      'tag': 'SENIOR',
      'image': 'assets/images/barber_marcus_reed.png',
      'rating': '5.0',
      'reviews': '98 reseñas',
    },
    {
      'id': 'dorian',
      'name': 'Dorian Grey',
      'specialty': 'Barba y Cuidado Facial',
      'tag': 'ELITE',
      'image': 'assets/images/barber_dorian_grey.png',
      'rating': '4.8',
      'reviews': '215 reseñas',
    },
  ];

  List<Map<String, dynamic>> _getLocalizedServices(AppLocalizations l10n) {
    return [
      {
        'name': l10n.get('booking_service1_name'),
        'price': 65.0,
        'duration': '45 min',
        'description': l10n.get('booking_service1_desc'),
      },
      {
        'name': l10n.get('booking_service2_name'),
        'price': 85.0,
        'duration': '60 min',
        'description': l10n.get('booking_service2_desc'),
      },
      {
        'name': l10n.get('booking_service3_name'),
        'price': 45.0,
        'duration': '30 min',
        'description': l10n.get('booking_service3_desc'),
      },
      {
        'name': l10n.get('booking_service4_name'),
        'price': 55.0,
        'duration': '40 min',
        'description': l10n.get('booking_service4_desc'),
      },
    ];
  }

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBarbers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchBarbers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'barber')
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _firestoreBarbers = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Barber',
              'specialty': data['specialty'] ?? 'Estilo & Corte',
              'tag': data['isAvailable'] == false ? 'IN SESSION' : 'ELITE',
              'image': data['image'] ?? 'assets/images/barber_julian_vance.png',
              'rating': '4.9',
              'reviews': '100+ reseñas',
            };
          }).toList();
          _isLoadingBarbers = false;
        });
      } else {
        setState(() {
          _firestoreBarbers = _fallbackBarbers;
          _isLoadingBarbers = false;
        });
      }
    } catch (e) {
      setState(() {
        _firestoreBarbers = _fallbackBarbers;
        _isLoadingBarbers = false;
      });
    }
  }

  List<DateTime> _getDates() {
    final today = DateTime.now();
    return List.generate(7, (index) => today.add(Duration(days: index)));
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final months = l10n.languageCode == 'es'
        ? [
            'Enero',
            'Febrero',
            'Marzo',
            'Abril',
            'Mayo',
            'Junio',
            'Julio',
            'Agosto',
            'Septiembre',
            'Octubre',
            'Noviembre',
            'Diciembre',
          ]
        : [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
    if (l10n.languageCode == 'es') {
      return '${date.day} de ${months[date.month - 1]}, ${date.year}';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Future<void> _submitBooking(AppLocalizations l10n) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add({
            'clientName': _nameController.text.trim(),
            'clientEmail': _emailController.text.trim(),
            'clientPhone': _phoneController.text.trim(),
            'service': _selectedService,
            'price': _selectedServicePrice,
            'time': _selectedTimeSlot,
            'barberId': _selectedBarber?['id'] ?? _selectedBarberId,
            'barberName': _selectedBarber?['name'] ?? 'Unassigned',
            'status': 'PENDING',
            'date': Timestamp.fromDate(_selectedDate ?? DateTime.now()),
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Write notification
      final isSpanish = l10n.languageCode == 'es';
      final notificationTitle = isSpanish
          ? 'Nueva Cita Solicitada'
          : 'New Appointment Requested';
      final notificationMessage = isSpanish
          ? '${_nameController.text.trim()} ha agendado $_selectedService con ${_selectedBarber?['name']} para el ${_formatDate(_selectedDate!, l10n)} a las $_selectedTimeSlot.'
          : '${_nameController.text.trim()} has scheduled $_selectedService with ${_selectedBarber?['name']} for ${_formatDate(_selectedDate!, l10n)} at $_selectedTimeSlot.';

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': notificationTitle,
        'message': notificationMessage,
        'barberId': _selectedBarber?['id'] ?? _selectedBarberId,
        'barberName': _selectedBarber?['name'] ?? 'Unassigned',
        'clientName': _nameController.text.trim(),
        'service': _selectedService,
        'time': _selectedTimeSlot,
        'bookingId': bookingRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      setState(() {
        _isSaving = false;
        _currentStep = 3; // Go to Success
      });
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageCode == 'es'
                ? 'Error al procesar reserva: $e'
                : 'Error processing booking: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const _BookingDrawer(),
      body: Column(
        children: [
          HomeNavBar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            activePage: 'Booking',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSection(l10n),
                  if (_currentStep < 3) _buildStepperSection(l10n),
                  _buildActiveStepSection(l10n, config),
                  const HomeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header Section ─────────────────────────────────────────────────────────
  Widget _buildHeaderSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.gutter,
      ),
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Text(
                _currentStep == 3
                    ? l10n.get('booking_success')
                    : (l10n.languageCode == 'es'
                          ? 'Reserva tu Experiencia'
                          : 'Book Your Experience'),
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLg().copyWith(
                  color: const Color(0xFFE2E2E2),
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _currentStep == 3
                    ? l10n.get('appointment_scheduled')
                    : (l10n.languageCode == 'es'
                          ? 'Precisión, tradición y el estilo que mereces. Sigue los pasos para agendar tu cita en Luxe & Blade.'
                          : 'Precision, tradition and the style you deserve. Follow the steps to schedule your appointment at Luxe & Blade.'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stepper Section ────────────────────────────────────────────────────────
  Widget _buildStepperSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStep(
                number: '1',
                label: l10n.get('barber').toUpperCase(),
                isActive: _currentStep >= 0,
              ),
              _buildStepDivider(),
              _buildStep(
                number: '2',
                label: l10n.languageCode == 'es' ? 'AGENDA' : 'SCHEDULE',
                isActive: _currentStep >= 1,
              ),
              _buildStepDivider(),
              _buildStep(
                number: '3',
                label: l10n.languageCode == 'es' ? 'RESUMEN' : 'SUMMARY',
                isActive: _currentStep >= 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.secondary : AppColors.outlineVariant,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.labelMd.copyWith(
                color: isActive
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? AppColors.secondary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08 * 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 64,
      height: 1,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ).copyWith(bottom: 20),
      color: AppColors.outlineVariant,
    );
  }

  // ─── Body Routing ──────────────────────────────────────────────────
  Widget _buildActiveStepSection(AppLocalizations l10n, AppConfigState config) {
    switch (_currentStep) {
      case 0:
        return _buildBarberSelectionSection(l10n);
      case 1:
        return _buildAgendaSelectionSection(l10n, config);
      case 2:
        return _buildSummarySection(l10n, config);
      case 3:
        return _buildSuccessSection(l10n);
      default:
        return _buildBarberSelectionSection(l10n);
    }
  }

  // ─── Step 1: Barber Selection Grid ──────────────────────────────────────────
  Widget _buildBarberSelectionSection(AppLocalizations l10n) {
    if (_isLoadingBarbers) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          color: AppColors.background,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.get('select_barber'),
                    style: AppTextStyles.headlineMd.copyWith(
                      color: const Color(0xFFE2E2E2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.get('expert_style'),
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  isMobile
                      ? _buildBarberListMobile(l10n)
                      : _buildBarberGridDesktop(l10n),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_selectedBarberId != null)
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final barber = _firestoreBarbers.firstWhere(
                            (b) => b['id'] == _selectedBarberId,
                          );
                          setState(() {
                            _selectedBarber = barber;
                            _currentStep = 1;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.onSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(
                          l10n.get('continue_btn'),
                          style: AppTextStyles.labelMd.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl + 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarberGridDesktop(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _firestoreBarbers.map((barber) {
        final isSelected = _selectedBarberId == barber['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: _buildBarberCard(barber, isSelected, l10n),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarberListMobile(AppLocalizations l10n) {
    return Column(
      children: _firestoreBarbers.map((barber) {
        final isSelected = _selectedBarberId == barber['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: _buildBarberCard(barber, isSelected, l10n),
        );
      }).toList(),
    );
  }

  Widget _buildBarberCard(
    Map<String, dynamic> barber,
    bool isSelected,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedBarberId = barber['id']),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary
                  : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.asset(
                      barber['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.onSurfaceVariant,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      color: AppColors.secondary,
                      child: Text(
                        barber['tag'],
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.08 * 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barber['name'],
                            style: AppTextStyles.headlineSm.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE2E2E2),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            barber['specialty'],
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_border,
                              color: AppColors.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              barber['rating'],
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.languageCode == 'es'
                              ? '${barber['reviews'].replaceAll(RegExp(r'[^0-9\+]'), '')} reseñas'
                              : '${barber['reviews'].replaceAll(RegExp(r'[^0-9\+]'), '')} reviews',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
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
      ),
    );
  }

  // ─── Step 2: Service & Agenda Selection ─────────────────────────────────────
  Widget _buildAgendaSelectionSection(
    AppLocalizations l10n,
    AppConfigState config,
  ) {
    final dates = _getDates();
    final localizedServices = _getLocalizedServices(l10n);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.marginMobile
                : AppSpacing.marginDesktop,
            vertical: AppSpacing.xl,
          ),
          color: AppColors.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.containerMax,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Service Selection
                    Text(
                      l10n.get('select_service'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Column(
                      children: localizedServices.map((service) {
                        final isSelected = _selectedService == service['name'];
                        return Card(
                          color: AppColors.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedService = service['name'];
                                _selectedServicePrice = service['price'];
                                _selectedServiceDuration = service['duration'];
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: service['name'],
                                    groupValue: _selectedService,
                                    activeColor: AppColors.secondary,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedService = val;
                                        _selectedServicePrice =
                                            service['price'];
                                        _selectedServiceDuration =
                                            service['duration'];
                                      });
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service['name'],
                                          style: AppTextStyles.headlineSm
                                              .copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          service['description'],
                                          style: AppTextStyles.bodyMd.copyWith(
                                            fontSize: 13,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${config.currencySymbol}${service['price'].toStringAsFixed(0)}',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      Text(
                                        service['duration'],
                                        style: AppTextStyles.labelSm.copyWith(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Date Selection
                    Text(
                      l10n.get('select_date'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        itemBuilder: (context, index) {
                          final date = dates[index];
                          final isSelected =
                              _selectedDate != null &&
                              _selectedDate!.year == date.year &&
                              _selectedDate!.month == date.month &&
                              _selectedDate!.day == date.day;

                          final dayOfWeek = _getDayOfWeekName(
                            date.weekday,
                            l10n,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.md,
                            ),
                            child: InkWell(
                              onTap: () => setState(() => _selectedDate = date),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 70,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.surfaceContainerLow,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.secondary
                                        : AppColors.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayOfWeek,
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: isSelected
                                            ? AppColors.onSecondary
                                            : AppColors.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      date.day.toString(),
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.onSecondary
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Time Slot Selection
                    Text(
                      l10n.get('select_time'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 3 : 5,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _timeSlots[index];
                        final isSelected = _selectedTimeSlot == slot;
                        return InkWell(
                          onTap: () => setState(() => _selectedTimeSlot = slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.surfaceContainerLow,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.outlineVariant,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                slot,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: isSelected
                                      ? AppColors.onSecondary
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Client Information Form
                    Text(
                      l10n.get('client_details'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      color: AppColors.surfaceContainerLow,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.get('full_name'),
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? l10n.get('enter_name')
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.get('email_address'),
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return l10n.get('enter_email');
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(val.trim())) {
                                return l10n.get('valid_email');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: l10n.get('phone_whatsapp'),
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? l10n.get('enter_phone')
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 0),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(l10n.get('back_btn')),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedService == null ||
                                _selectedDate == null ||
                                _selectedTimeSlot == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.languageCode == 'es'
                                        ? 'Por favor selecciona servicio, fecha y hora.'
                                        : 'Please select service, date and time.',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (_formKey.currentState!.validate()) {
                              setState(() => _currentStep = 2);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.onSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(l10n.get('continue_btn')),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl + 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDayOfWeekName(int weekday, AppLocalizations l10n) {
    final isSpanish = l10n.languageCode == 'es';
    switch (weekday) {
      case 1:
        return isSpanish ? 'LUN' : 'MON';
      case 2:
        return isSpanish ? 'MAR' : 'TUE';
      case 3:
        return isSpanish ? 'MIE' : 'WED';
      case 4:
        return isSpanish ? 'JUE' : 'THU';
      case 5:
        return isSpanish ? 'VIE' : 'FRI';
      case 6:
        return isSpanish ? 'SAB' : 'SAT';
      case 7:
        return isSpanish ? 'DOM' : 'SUN';
      default:
        return '';
    }
  }

  // ─── Step 3: Summary ────────────────────────────────────────────────────────
  Widget _buildSummarySection(AppLocalizations l10n, AppConfigState config) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.xl,
      ),
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.get('booking_summary'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      '${l10n.get('barber')}:',
                      _selectedBarber?['name'] ?? '',
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildSummaryRow(
                      '${l10n.get('service')}:',
                      _selectedService ?? '',
                    ),
                    _buildSummaryRow(
                      '${l10n.get('duration')}:',
                      _selectedServiceDuration ?? '',
                    ),
                    _buildSummaryRow(
                      '${l10n.get('price')}:',
                      '${config.currencySymbol}${_selectedServicePrice.toStringAsFixed(0)}',
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildSummaryRow(
                      '${l10n.get('date')}:',
                      _formatDate(_selectedDate!, l10n),
                    ),
                    _buildSummaryRow(
                      '${l10n.get('time')}:',
                      _selectedTimeSlot ?? '',
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildSummaryRow(
                      l10n.languageCode == 'es' ? 'Cliente:' : 'Client:',
                      _nameController.text.trim(),
                    ),
                    _buildSummaryRow('Email:', _emailController.text.trim()),
                    _buildSummaryRow(
                      l10n.languageCode == 'es' ? 'Teléfono:' : 'Phone:',
                      _phoneController.text.trim(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_isSaving)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 16,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(l10n.get('back_btn')),
                    ),
                    ElevatedButton(
                      onPressed: () => _submitBooking(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 16,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(l10n.get('confirm_booking')),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xxl + 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyLg.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Success State ──────────────────────────────────────────────────
  Widget _buildSuccessSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.xl,
      ),
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 3),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.secondary,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.get('booking_success'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.get('appointment_scheduled'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                color: AppColors.surfaceContainerLow,
                child: Column(
                  children: [
                    _buildSummaryRow(
                      '${l10n.get('barber')}:',
                      _selectedBarber?['name'] ?? '',
                    ),
                    _buildSummaryRow(
                      '${l10n.get('date')}:',
                      _formatDate(_selectedDate!, l10n),
                    ),
                    _buildSummaryRow(
                      '${l10n.get('time')}:',
                      _selectedTimeSlot ?? '',
                    ),
                    _buildSummaryRow(
                      '${l10n.get('service')}:',
                      _selectedService ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _selectedBarberId = null;
                    _selectedBarber = null;
                    _selectedService = null;
                    _selectedDate = null;
                    _selectedTimeSlot = null;
                    _nameController.clear();
                    _emailController.clear();
                    _phoneController.clear();
                  });
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                  l10n.languageCode == 'es'
                      ? 'VOLVER AL INICIO'
                      : 'BACK TO HOME',
                ),
              ),
              const SizedBox(height: AppSpacing.xxl + 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDrawer extends ConsumerWidget {
  const _BookingDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);

    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THE GENTLEMAN', style: AppTextStyles.headlineSm),
              const SizedBox(height: 40),
              ...HomeNavBar.navItems.map((item) {
                final label = l10n.get(item.toLowerCase());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final route = HomeNavBar.navRoutes[item];
                      if (route != null) {
                        context.go(route);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(label, style: AppTextStyles.bodyLg),
                  ),
                );
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                ),
                child: Text(
                  l10n.get('book_appointment'),
                  style: AppTextStyles.labelMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

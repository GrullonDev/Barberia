import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/core/theme/app_theme.dart';
import 'package:barberia/core/utils/responsive.dart';
import 'package:barberia/features/booking/data/booking_repository.dart';
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

  // Servicio real de Firestore (id, name, price/priceCents, durationMinutes,
  // description, isActive). Ya no hay catálogo hardcodeado: `reserveSlot`
  // necesita un `serviceId` que exista de verdad en la colección `services`.
  Map<String, dynamic>? _selectedServiceData;
  List<Map<String, dynamic>> _services = [];
  bool _isLoadingServices = true;

  DateTime? _selectedDate;

  // Slot elegido, en UTC, calculado server-side por `getAvailability`. Ya no
  // es un string fijo como "09:00 AM": viene de la disponibilidad real del
  // barbero contra bookings y schedule_blocks existentes.
  DateTime? _selectedSlotUtc;
  List<DateTime> _availableSlots = [];
  bool _isLoadingSlots = false;

  // Controllers for client info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  static const List<Map<String, Object>> _countryDialCodes = [
    {'code': 'GT', 'dialCode': '+502', 'digits': 8},
    {'code': 'US', 'dialCode': '+1', 'digits': 10},
    {'code': 'MX', 'dialCode': '+52', 'digits': 10},
    {'code': 'SV', 'dialCode': '+503', 'digits': 8},
    {'code': 'HN', 'dialCode': '+504', 'digits': 8},
  ];
  String _selectedCountryCode = 'GT';

  bool _isSaving = false;
  bool _isLoadingBarbers = true;
  List<Map<String, dynamic>> _firestoreBarbers = [];

  bool _barbersLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchBarbers();
    _fetchServices();
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
          _firestoreBarbers = [];
          _isLoadingBarbers = false;
        });
      }
    } catch (e) {
      setState(() {
        _firestoreBarbers = [];
        _isLoadingBarbers = false;
        _barbersLoadFailed = true;
      });
    }
  }

  Future<void> _fetchServices() async {
    try {
      final services = await ref
          .read(bookingRepositoryProvider)
          .fetchActiveServices();
      setState(() {
        _services = services;
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() {
        _services = [];
        _isLoadingServices = false;
      });
    }
  }

  /// Pide a la Cloud Function `getAvailability` los slots libres reales
  /// para el barbero/fecha/servicio elegidos. Se dispara en cuanto las tres
  /// selecciones están completas; si cambia cualquiera, se reconsulta.
  Future<void> _fetchAvailableSlots() async {
    final barberId = _selectedBarber?['id'] ?? _selectedBarberId;
    final serviceId = _selectedServiceData?['id'] as String?;
    if (barberId == null || serviceId == null || _selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedSlotUtc = null;
    });

    try {
      final slots = await ref
          .read(bookingRepositoryProvider)
          .fetchAvailability(
            barberId: barberId,
            date: _selectedDate!,
            serviceId: serviceId,
          );
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    } on BookingException catch (_) {
      setState(() {
        _availableSlots = [];
        _isLoadingSlots = false;
      });
    } catch (_) {
      setState(() {
        _availableSlots = [];
        _isLoadingSlots = false;
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

  /// Hora local del negocio para un instante UTC, según
  /// `config/barberia.timezoneOffsetHours` (ver config_provider.dart).
  String _formatLocalTime(DateTime utc, int tzOffsetHours) {
    final local = utc.add(Duration(hours: tzOffsetHours));
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatDuration(AppLocalizations l10n) {
    final minutes =
        (_selectedServiceData?['durationMinutes'] as num?)?.toInt() ?? 0;
    return l10n.languageCode == 'es' ? '$minutes min' : '$minutes min';
  }

  Map<String, Object> get _selectedCountry => _countryDialCodes.firstWhere(
    (country) => country['code'] == _selectedCountryCode,
    orElse: () => _countryDialCodes.first,
  );

  int get _selectedPhoneDigits => _selectedCountry['digits'] as int;

  String get _selectedDialCode => _selectedCountry['dialCode'] as String;

  String get _formattedCustomerPhone {
    final digits = _phoneController.text.trim();
    return '$_selectedDialCode$digits';
  }

  double _selectedServicePrice() {
    final data = _selectedServiceData;
    if (data == null) return 0.0;
    if (data['priceCents'] != null) {
      return (data['priceCents'] as num).toDouble() / 100;
    }
    return (data['price'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _submitBooking(AppLocalizations l10n) async {
    if (_isSaving) return;
    final barberId = _selectedBarber?['id'] ?? _selectedBarberId;
    final serviceId = _selectedServiceData?['id'] as String?;
    final slot = _selectedSlotUtc;
    if (barberId == null || serviceId == null || slot == null) return;

    setState(() => _isSaving = true);

    try {
      // Única puerta de escritura: la Cloud Function `reserveSlot` corre con
      // Admin SDK, valida solapamientos/horario/reputación en una
      // transacción, y crea el booking + la notificación al barbero. El
      // cliente nunca escribe directo a `bookings`/`notifications`
      // (firestore.rules deniega esos `create` desde el SDK de cliente).
      await ref
          .read(bookingRepositoryProvider)
          .reserveSlot(
            barberId: barberId,
            serviceId: serviceId,
            startAt: slot,
            customerName: _nameController.text.trim(),
            customerEmail: _emailController.text.trim(),
            customerPhone: _formattedCustomerPhone,
          );

      setState(() {
        _isSaving = false;
        _currentStep = 3; // Go to Success
      });
    } on BookingException catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapBookingError(e, l10n))));
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageCode == 'es'
                ? 'Error al procesar reserva. Intenta de nuevo.'
                : 'Error processing booking. Please try again.',
          ),
        ),
      );
    }
  }

  String _mapBookingError(BookingException e, AppLocalizations l10n) {
    final isSpanish = l10n.languageCode == 'es';
    switch (e.code) {
      case 'already-exists':
        return isSpanish
            ? 'Ese horario ya fue reservado por otro cliente. Elige otro.'
            : 'That slot was just booked by someone else. Please pick another.';
      case 'failed-precondition':
        return isSpanish
            ? 'El barbero ya no está disponible en ese horario.'
            : 'The barber is no longer available at that time.';
      case 'not-found':
        return isSpanish
            ? 'El barbero o servicio seleccionado ya no existe.'
            : 'The selected barber or service no longer exists.';
      default:
        return isSpanish
            ? 'No se pudo completar la reserva. Intenta de nuevo.'
            : 'Could not complete the booking. Please try again.';
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
        return _buildSuccessSection(l10n, config);
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

    if (_firestoreBarbers.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            _barbersLoadFailed
                ? l10n.get('barbers_load_error')
                : l10n.get('no_barbers_available'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
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
                    if (_isLoadingServices)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        ),
                      )
                    else if (_services.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        color: AppColors.surfaceContainerLow,
                        child: Text(
                          l10n.languageCode == 'es'
                              ? 'No hay servicios disponibles por el momento. Contacta al negocio.'
                              : 'No services available right now. Please contact the shop.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      RadioGroup<String>(
                        groupValue: _selectedServiceData?['id'] as String?,
                        onChanged: (value) {
                          if (value == null) return;
                          final selectedService = _services.firstWhere(
                            (service) => service['id'] == value,
                            orElse: () => <String, dynamic>{},
                          );
                          if (selectedService.isEmpty) return;
                          setState(
                            () => _selectedServiceData = selectedService,
                          );
                          _fetchAvailableSlots();
                        },
                        child: Column(
                          children: _services.map((service) {
                            final isSelected =
                                _selectedServiceData?['id'] == service['id'];
                            final priceValue = service['priceCents'] != null
                                ? (service['priceCents'] as num).toDouble() /
                                      100
                                : (service['price'] as num?)?.toDouble() ?? 0.0;
                            final durationMinutes =
                                (service['durationMinutes'] as num?)?.toInt() ??
                                0;
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
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(
                                    () => _selectedServiceData = service,
                                  );
                                  _fetchAvailableSlots();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: service['id'],
                                        activeColor: AppColors.secondary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              service['name'] ?? '',
                                              style: AppTextStyles.headlineSm
                                                  .copyWith(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              service['description'] ?? '',
                                              style: AppTextStyles.bodyMd
                                                  .copyWith(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${config.currencySymbol}${priceValue.toStringAsFixed(0)}',
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                          Text(
                                            '$durationMinutes min',
                                            style: AppTextStyles.labelSm
                                                .copyWith(
                                                  fontSize: 11,
                                                  color: AppColors
                                                      .onSurfaceVariant,
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
                              onTap: () {
                                setState(() => _selectedDate = date);
                                _fetchAvailableSlots();
                              },
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

                    // Time Slot Selection — calculados server-side por
                    // `getAvailability` contra bookings/schedule_blocks reales.
                    Text(
                      l10n.get('select_time'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTimeSlotGrid(l10n, config, isMobile),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 132,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCountryCode,
                                  dropdownColor: AppColors.surfaceContainerLow,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: l10n.languageCode == 'es'
                                        ? 'Pais'
                                        : 'Country',
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
                                  items: _countryDialCodes.map((country) {
                                    final code = country['code'] as String;
                                    final dialCode =
                                        country['dialCode'] as String;
                                    return DropdownMenuItem<String>(
                                      value: code,
                                      child: Text('$code $dialCode'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedCountryCode = value;
                                      final maxDigits = _selectedPhoneDigits;
                                      if (_phoneController.text.length >
                                          maxDigits) {
                                        _phoneController.text = _phoneController
                                            .text
                                            .substring(0, maxDigits);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                      _selectedPhoneDigits,
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: l10n.get('phone_whatsapp'),
                                    hintText: _selectedPhoneDigits == 8
                                        ? '12345678'
                                        : null,
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
                                    final digits = val?.trim() ?? '';
                                    if (digits.isEmpty) {
                                      return l10n.get('enter_phone');
                                    }
                                    if (digits.length != _selectedPhoneDigits) {
                                      return l10n.languageCode == 'es'
                                          ? 'Ingresa $_selectedPhoneDigits numeros.'
                                          : 'Enter $_selectedPhoneDigits digits.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
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
                            if (_selectedServiceData == null ||
                                _selectedDate == null ||
                                _selectedSlotUtc == null) {
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

  Widget _buildTimeSlotGrid(
    AppLocalizations l10n,
    AppConfigState config,
    bool isMobile,
  ) {
    if (_selectedServiceData == null || _selectedDate == null) {
      return Text(
        l10n.languageCode == 'es'
            ? 'Selecciona un servicio y una fecha para ver horarios.'
            : 'Select a service and a date to see available times.',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    if (_isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }
    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: AppColors.surfaceContainerLow,
        child: Text(
          l10n.languageCode == 'es'
              ? 'No hay horarios disponibles ese día. Elige otra fecha.'
              : 'No available times that day. Try another date.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 3 : 5,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.2,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slotUtc = _availableSlots[index];
        final isSelected = _selectedSlotUtc == slotUtc;
        return InkWell(
          onTap: () => setState(() => _selectedSlotUtc = slotUtc),
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
                _formatLocalTime(slotUtc, config.timezoneOffsetHours),
                style: AppTextStyles.labelSm.copyWith(
                  color: isSelected ? AppColors.onSecondary : Colors.white,
                  fontWeight: FontWeight.bold,
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
                      _selectedServiceData?['name'] ?? '',
                    ),
                    _buildSummaryRow(
                      '${l10n.get('duration')}:',
                      _formatDuration(l10n),
                    ),
                    _buildSummaryRow(
                      '${l10n.get('price')}:',
                      '${config.currencySymbol}${_selectedServicePrice().toStringAsFixed(0)}',
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildSummaryRow(
                      '${l10n.get('date')}:',
                      _formatDate(_selectedDate!, l10n),
                    ),
                    _buildSummaryRow(
                      '${l10n.get('time')}:',
                      _selectedSlotUtc != null
                          ? _formatLocalTime(
                              _selectedSlotUtc!,
                              config.timezoneOffsetHours,
                            )
                          : '',
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 24),
                    _buildSummaryRow(
                      l10n.languageCode == 'es' ? 'Cliente:' : 'Client:',
                      _nameController.text.trim(),
                    ),
                    _buildSummaryRow('Email:', _emailController.text.trim()),
                    _buildSummaryRow(
                      l10n.languageCode == 'es' ? 'Teléfono:' : 'Phone:',
                      _formattedCustomerPhone,
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
  Widget _buildSuccessSection(AppLocalizations l10n, AppConfigState config) {
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
                      _selectedSlotUtc != null
                          ? _formatLocalTime(
                              _selectedSlotUtc!,
                              config.timezoneOffsetHours,
                            )
                          : '',
                    ),
                    _buildSummaryRow(
                      '${l10n.get('service')}:',
                      _selectedServiceData?['name'] ?? '',
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
                    _selectedServiceData = null;
                    _selectedDate = null;
                    _selectedSlotUtc = null;
                    _availableSlots = [];
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

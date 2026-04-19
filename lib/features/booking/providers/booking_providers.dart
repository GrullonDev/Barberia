import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/barber/providers/barber_providers.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/repositories/booking_repository.dart';
import 'package:barberia/features/booking/repositories/service_repository.dart';
import 'package:barberia/features/booking/services/reserve_slot_service.dart';
import 'package:barberia/features/booking/services/slot_engine.dart';
import 'package:barberia/features/schedule/models/schedule_block.dart';
import 'package:barberia/features/schedule/providers/schedule_block_providers.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/core/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Repositories
final Provider<BookingRepository> bookingRepositoryProvider =
    Provider<BookingRepository>((Ref ref) => BookingRepository());

final Provider<ServiceRepository> serviceRepositoryProvider =
    Provider<ServiceRepository>((Ref ref) => ServiceRepository());

/// Servicio tipado sobre la Cloud Function `reserveSlot`.
final Provider<ReserveSlotService> reserveSlotServiceProvider =
    Provider<ReserveSlotService>((Ref ref) => ReserveSlotService());

/// Último booking confirmado por el CF — lo consume `confirmation_page`
/// para pintar el ticket con datos reales (id server-side, endAt, etc.)
/// en vez de fabricar uno local.
final StateProvider<Booking?> lastConfirmedBookingProvider =
    StateProvider<Booking?>((Ref ref) => null);

/// Argumentos inmutables para [availableSlotsProvider]. Al ser `==`
/// por valor, Riverpod memoiza el resultado mientras no cambie
/// barberId/day/serviceId, evitando recomputar slots en cada rebuild.
class AvailableSlotsArgs {
  final String barberId;
  final DateTime day; // se usa solo año-mes-día (truncado)
  final String serviceId;
  final int durationMinutes;
  final int slotMinutes;

  const AvailableSlotsArgs({
    required this.barberId,
    required this.day,
    required this.serviceId,
    required this.durationMinutes,
    this.slotMinutes = 30,
  });

  @override
  bool operator ==(Object other) =>
      other is AvailableSlotsArgs &&
      other.barberId == barberId &&
      other.day.year == day.year &&
      other.day.month == day.month &&
      other.day.day == day.day &&
      other.serviceId == serviceId &&
      other.durationMinutes == durationMinutes &&
      other.slotMinutes == slotMinutes;

  @override
  int get hashCode => Object.hash(
        barberId,
        day.year,
        day.month,
        day.day,
        serviceId,
        durationMinutes,
        slotMinutes,
      );
}

/// Slots libres del día dado para un barbero + servicio. Memoizado por args
/// (hashCode/==). Usa [SlotEngine.generateAvailable] para no golpear el CF
/// en cada rebuild del calendario. La autoridad final sigue siendo
/// `reserveSlot` (que corre su propia transacción anti-colisión).
final FutureProviderFamily<List<DateTime>, AvailableSlotsArgs>
    availableSlotsProvider =
    FutureProvider.family<List<DateTime>, AvailableSlotsArgs>(
  (Ref ref, AvailableSlotsArgs args) async {
    final List<Barber> barbers =
        await ref.watch(availableBarbersProvider.future);
    final Barber barber = barbers.firstWhere(
      (Barber b) => b.id == args.barberId,
      orElse: () => Barber(
        id: args.barberId,
        name: '',
        workingHours: Barber.defaultWorkingHours(),
      ),
    );

    final List<Booking> allBookings = ref.watch(bookingsProvider);
    final List<Booking> dayBookings =
        SlotEngine.bookingsForDay(allBookings, args.day);

    final List<ScheduleBlock> blocks =
        ref.watch(scheduleBlocksForBarberProvider(args.barberId)).maybeWhen(
              data: (List<ScheduleBlock> data) => data,
              orElse: () => const <ScheduleBlock>[],
            );
    final List<ScheduleBlock> dayBlocks =
        SlotEngine.blocksForDay(blocks, args.day);

    return SlotEngine.generateAvailable(
      date: args.day,
      durationMinutes: args.durationMinutes,
      slotMinutes: args.slotMinutes,
      barber: barber,
      existingBookings: dayBookings,
      blocks: dayBlocks,
    );
  },
);

// Providers
final StateNotifierProvider<BookingDraftNotifier, BookingDraft>
bookingDraftProvider =
    StateNotifierProvider<BookingDraftNotifier, BookingDraft>(
      (final Ref ref) => BookingDraftNotifier(),
    );

final StateNotifierProvider<BookingsNotifier, List<Booking>> bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>((final Ref ref) {
      final BookingRepository repo = ref.watch(bookingRepositoryProvider);
      final User? user = ref.watch(authStateProvider);
      return BookingsNotifier(repo, user);
    });

/// Async list of services from DB
final FutureProvider<List<Service>> servicesAsyncProvider =
    FutureProvider<List<Service>>((final Ref ref) async {
      return ref.watch(serviceRepositoryProvider).getServices();
    });

// Booking Draft (client-side state, persisted in SharedPreferences)
class BookingDraftNotifier extends StateNotifier<BookingDraft> {
  static const String _kDraftKey = 'booking_draft_data';

  BookingDraftNotifier() : super(BookingDraft.empty()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_kDraftKey);
      if (jsonStr != null) {
        final Map<String, dynamic> map =
            json.decode(jsonStr) as Map<String, dynamic>;

        // Handle service Reconstruction
        Service? service;
        if (map['service'] != null) {
          service = Service.fromMap(map['service'] as Map<String, dynamic>);
        }

        state = BookingDraft(
          service: service,
          barberId: map['barberId'] as String?,
          date: map['date'] != null
              ? DateTime.tryParse(map['date'] as String)
              : null,
          dateTime: map['dateTime'] != null
              ? DateTime.tryParse(map['dateTime'] as String)
              : null,
          name: map['name'] as String?,
          phone: map['phone'] as String?,
          email: map['email'] as String?,
          notes: map['notes'] as String?,
        );
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {
      'service': state.service?.toMap(),
      'barberId': state.barberId,
      'date': state.date?.toIso8601String(),
      'dateTime': state.dateTime?.toIso8601String(),
      'name': state.name,
      'phone': state.phone,
      'email': state.email,
      'notes': state.notes,
    };
    await prefs.setString(_kDraftKey, json.encode(data));
  }

  void reset() {
    state = BookingDraft.empty();
    _persist();
  }

  void setCustomerInfo({
    required final String name,
    final String? phone,
    final String? email,
    final String? notes,
  }) {
    state = state.copyWith(
      name: name,
      phone: phone,
      email: email,
      notes: notes,
    );
    _persist();
  }

  void setService(Service service) {
    state = state.copyWith(service: service);
    _persist();
  }

  void setBarberId(String barberId) {
    state = state.copyWith(barberId: barberId);
    _persist();
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
    _persist();
  }

  void setDateTime(DateTime dateTime) {
    state = state.copyWith(dateTime: dateTime);
    _persist();
  }
}

// Bookings List (Synced with DB)
class BookingsNotifier extends StateNotifier<List<Booking>> {
  final BookingRepository _repository;
  final User? _user;

  BookingsNotifier(this._repository, this._user) : super(const <Booking>[]) {
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (_user == null) return;
    try {
      final List<Booking> bookings;
      if (_user.role == UserRole.admin || _user.role == UserRole.barber) {
        bookings = await _repository.getAllBookingsAdmin();
      } else {
        bookings = await _repository.getBookings(_user.id);
      }
      state = bookings;
    } catch (e) {
      // Handle error
    }
  }

  /// Agrega un booking ya persistido server-side (vía CF `reserveSlot`).
  ///
  /// IMPORTANTE: NO crea el documento en Firestore — las reglas bloquean
  /// la escritura directa del cliente. La creación real ocurre en
  /// `ReserveSlotService.reserve()` llamado desde `details_page.submit()`.
  /// Este método solo hace el optimistic update en memoria y programa
  /// la notificación local de recordatorio.
  Future<void> add(final Booking booking) async {
    // Optimistic update: inserta el booking ya creado por el CF en el cache.
    state = <Booking>[...state, booking];

    // Schedule Notification (1 hour before)
    final DateTime scheduledTime = booking.dateTime.subtract(
      const Duration(hours: 1),
    );
    if (scheduledTime.isAfter(DateTime.now())) {
      try {
        await LocalNotificationService().scheduleNotification(
          id: booking.id.hashCode,
          title: 'Recordatorio de Cita',
          body: 'Tu cita para ${booking.serviceName} es en 1 hora.',
          scheduledDate: scheduledTime,
        );
      } catch (_) {
        // Notification failure no debe romper el flujo de reserva.
      }
    }
  }

  Future<void> cancel(String id) async {
    // Optimistic
    state = <Booking>[
      for (final Booking b in state)
        if (b.id == id)
          b.copyWith(
            status: BookingStatus.canceled,
            cancelReason: CancelReason.byCustomer,
          )
        else
          b,
    ];
    try {
      await _repository.cancelBooking(id);

      // Cancel Notification
      await LocalNotificationService().cancelNotification(id.hashCode);
    } catch (e) {
      _loadBookings();
    }
  }

  /// Verifica si un slot [start] con duración [duration] se solapa
  bool hasConflict(DateTime start, Duration duration) {
    final DateTime end = start.add(duration);
    for (final Booking b in state) {
      if (b.status == BookingStatus.canceled) {
        continue;
      }
      final bool overlap = start.isBefore(b.endTime) && end.isAfter(b.dateTime);
      if (overlap) {
        return true;
      }
    }
    return false;
  }

  Future<void> rebook(String id, DateTime newStart) async {
    state = <Booking>[
      for (final Booking b in state)
        if (b.id == id)
          b.copyWith(
            startAt: newStart,
            endAt: newStart.add(Duration(minutes: b.serviceDurationMinutes)),
          )
        else
          b,
    ];
  }
}

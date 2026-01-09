import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/repositories/booking_repository.dart';
import 'package:barberia/features/booking/repositories/service_repository.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Repositories
final Provider<BookingRepository> bookingRepositoryProvider =
    Provider<BookingRepository>((Ref ref) => BookingRepository());

final Provider<ServiceRepository> serviceRepositoryProvider =
    Provider<ServiceRepository>((Ref ref) => ServiceRepository());

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

  Future<void> add(final Booking booking) async {
    // Optimistic update
    state = <Booking>[...state, booking];
    try {
      await _repository.createBooking(booking);

      // Schedule Notification (1 hour before)
      final DateTime scheduledTime = booking.dateTime.subtract(
        const Duration(hours: 1),
      );
      if (scheduledTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: booking.id.hashCode,
          title: 'Recordatorio de Cita',
          body: 'Tu cita para ${booking.serviceName} es en 1 hora.',
          scheduledDate: scheduledTime,
        );
      }
    } catch (e) {
      _loadBookings();
    }
  }

  Future<void> cancel(String id) async {
    // Optimistic
    state = <Booking>[
      for (final Booking b in state)
        if (b.id == id)
          Booking(
            id: b.id,
            userId: b.userId,
            serviceId: b.serviceId,
            serviceName: b.serviceName,
            dateTime: b.dateTime,
            customerName: b.customerName,
            customerPhone: b.customerPhone,
            customerEmail: b.customerEmail,
            notes: b.notes,
            status: BookingStatus.canceled,
            service: b.service,
          )
        else
          b,
    ];
    try {
      await _repository.cancelBooking(id);

      // Cancel Notification
      await NotificationService().cancelNotification(id.hashCode);
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
          Booking(
            id: b.id,
            userId: b.userId,
            serviceId: b.serviceId,
            serviceName: b.serviceName,
            dateTime: newStart,
            customerName: b.customerName,
            customerPhone: b.customerPhone,
            customerEmail: b.customerEmail,
            notes: b.notes,
            status: b.status,
            service: b.service,
          )
        else
          b,
    ];
  }
}

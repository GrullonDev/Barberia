import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/repositories/booking_repository.dart';
import 'package:barberia/features/booking/repositories/service_repository.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/core/services/notification_service.dart';

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

// Booking Draft (client-side state, no DB needed until confirm)
class BookingDraftNotifier extends StateNotifier<BookingDraft> {
  BookingDraftNotifier() : super(BookingDraft.empty());

  void reset() => state = BookingDraft.empty();

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
  }

  void setService(Service service) => state = state.copyWith(service: service);
  void setDate(DateTime date) => state = state.copyWith(date: date);
  void setDateTime(DateTime dateTime) =>
      state = state.copyWith(dateTime: dateTime);
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
      final bookings = await _repository.getBookings(_user.id);
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

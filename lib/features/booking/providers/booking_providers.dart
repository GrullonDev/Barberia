import 'package:barberia/common/database_helper.dart';
import 'package:barberia/common/services/notification_service.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/repositories/booking_repository.dart';
import 'package:barberia/features/booking/repositories/service_repository.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';

// Repositories
final Provider<ServiceRepository> serviceRepositoryProvider =
    Provider<ServiceRepository>((Ref ref) => ServiceRepository());

final Provider<BookingRepository> bookingRepositoryProvider =
    Provider<BookingRepository>((Ref ref) => BookingRepository());

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
  }) => state = state.copyWith(
    name: name,
    phone: phone,
    email: email,
    notes: notes,
  );

  void reset() => state = BookingDraft.empty();
}

final StateNotifierProvider<BookingDraftNotifier, BookingDraft>
bookingDraftProvider =
    StateNotifierProvider<BookingDraftNotifier, BookingDraft>(
      (final Ref ref) => BookingDraftNotifier(),
    );

// Bookings List (Synced with DB)
class BookingsNotifier extends StateNotifier<List<Booking>> {
  BookingsNotifier(this._repository, this._user) : super(const <Booking>[]) {
    _loadBookings();
  }

  final BookingRepository _repository;
  final User? _user;

  Future<void> _loadBookings() async {
    if (_user == null) {
      state = [];
      return;
    }
    // If admin, maybe fetch all? For now, let's stick to user's bookings.
    if (_user.role == UserRole.admin) {
      final List<Booking> bookings = await _repository.getBookings(
        _user.id,
      ); // Or getAllBookingsAdmin()
      state = bookings;
    } else {
      final List<Booking> bookings = await _repository.getBookings(_user.id);
      state = bookings;
    }
  }

  Future<void> add(final Booking booking) async {
    // Optimistic update
    state = <Booking>[...state, booking];
    try {
      await _repository.createBooking(booking);
    } catch (e) {
      // Revert if failed (would need robust rollback, simplified here)
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
    } catch (e) {
      _loadBookings();
    }
  }

  Future<void> rebook(String id, DateTime newStart) async {
    // Rebook logic usually means creating a new appointment.
    // For this existing method signature, we update local state.
    // For DB, we'd probably insert a new record or update the existing one.
    // We'll skip DB persistence for rebook in this specific method for now,
    // or assume the UI calls 'add' for a new slot.

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

  /// Verifica si un slot [start] con duración [duration] se solapa
  bool hasConflict(DateTime start, Duration duration) {
    final DateTime end = start.add(duration);
    for (final Booking b in state) {
      if (b.status == BookingStatus.canceled) continue;
      final bool overlap = start.isBefore(b.endTime) && end.isAfter(b.dateTime);
      if (overlap) {
        return true;
      }
    }
    return false;
  }
}

final StateNotifierProvider<BookingsNotifier, List<Booking>> bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>((final Ref ref) {
      final repo = ref.watch(bookingRepositoryProvider);
      final user = ref.watch(authStateProvider);
      return BookingsNotifier(repo, user);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';

// Servicios mockeados.
final Provider<List<Service>> servicesProvider = Provider<List<Service>>(
  (final Ref ref) => const <Service>[
    Service(id: 'cut', name: 'Corte', durationMinutes: 30, price: 12),
    Service(
      id: 'cut-beard',
      name: 'Corte + Barba',
      durationMinutes: 45,
      price: 18,
    ),
    Service(id: 'beard', name: 'Barba', durationMinutes: 20, price: 10),
  ],
);

/// Versión asíncrona simulada para mostrar skeletons / animaciones de carga.
final FutureProvider<List<Service>> servicesAsyncProvider =
    FutureProvider<List<Service>>((final Ref ref) async {
      // Delay intencional corto para mostrar estado de carga.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return ref.read(servicesProvider);
    });

// Borrador de reserva en progreso.
class BookingDraftNotifier extends StateNotifier<BookingDraft> {
  BookingDraftNotifier() : super(BookingDraft.empty());

  void setService(final Service service) =>
      state = state.copyWith(service: service);
  void setDate(final DateTime date) => state = state.copyWith(date: date);
  void setDateTime(final DateTime dateTime) =>
      state = state.copyWith(dateTime: dateTime);
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

// Lista de reservas confirmadas.
class BookingsNotifier extends StateNotifier<List<Booking>> {
  BookingsNotifier() : super(const <Booking>[]);

  void add(final Booking booking) => state = <Booking>[...state, booking];

  bool hasConflict(DateTime start, Duration duration) {
    final DateTime end = start.add(duration);
    for (final Booking b in state) {
      final DateTime bStart = b.dateTime;
      final DateTime bEnd = bStart.add(
        Duration(minutes: b.service.durationMinutes),
      );
      final bool overlap = start.isBefore(bEnd) && end.isAfter(bStart);
      if (overlap) {
        return true;
      }
    }
    return false;
  }
}

final StateNotifierProvider<BookingsNotifier, List<Booking>> bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>(
      (final Ref ref) => BookingsNotifier(),
    );

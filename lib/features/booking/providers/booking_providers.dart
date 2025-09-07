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
    required final String phone,
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
}

final StateNotifierProvider<BookingsNotifier, List<Booking>> bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>(
      (final Ref ref) => BookingsNotifier(),
    );

import 'package:barberia/common/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';

// Servicios mockeados.
final FutureProvider<List<Service>> servicesProvider =
    FutureProvider<List<Service>>((final Ref ref) async {
  final db = await DatabaseHelper.instance.database;
  final result = await db.query('services');
  return result.map((json) => Service.fromJson(json)).toList();
});

/// Versión asíncrona simulada para mostrar skeletons / animaciones de carga.
final FutureProvider<List<Service>> servicesAsyncProvider =
    FutureProvider<List<Service>>((final Ref ref) async {
      // Delay intencional corto para mostrar estado de carga.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return ref.watch(servicesProvider.future);
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
  void cancel(String id) => state = <Booking>[
    for (final Booking b in state)
      if (b.id == id)
        Booking(
          id: b.id,
          service: b.service,
          dateTime: b.dateTime,
          customerName: b.customerName,
          customerPhone: b.customerPhone,
          customerEmail: b.customerEmail,
          notes: b.notes,
          status: BookingStatus.canceled,
        )
      else
        b,
  ];

  void rebook(String id, DateTime newStart) => state = <Booking>[
    for (final Booking b in state)
      if (b.id == id)
        Booking(
          id: b.id,
          service: b.service,
          dateTime: newStart,
          customerName: b.customerName,
          customerPhone: b.customerPhone,
          customerEmail: b.customerEmail,
          notes: b.notes,
          status: b.status,
        )
      else
        b,
  ];

  /// Verifica si un slot [start] con duración [duration] se solapa con
  /// alguna reserva existente (overlap estricto, bordes que tocan permiten).
  bool hasConflict(DateTime start, Duration duration) {
    final DateTime end = start.add(duration);
    for (final Booking b in state) {
      final bool overlap = start.isBefore(b.endTime) && end.isAfter(b.dateTime);
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

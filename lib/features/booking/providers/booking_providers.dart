import 'package:barberia/common/database_helper.dart';
import 'package:barberia/common/services/notification_service.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common/sqlite_api.dart';

final StateNotifierProvider<BookingDraftNotifier, BookingDraft>
bookingDraftProvider =
    StateNotifierProvider<BookingDraftNotifier, BookingDraft>(
      (final Ref ref) => BookingDraftNotifier(),
    );

final StateNotifierProvider<BookingsNotifier, List<Booking>> bookingsProvider =
    StateNotifierProvider<BookingsNotifier, List<Booking>>(
      (final Ref ref) => BookingsNotifier(),
    );

/// Versión asíncrona simulada para mostrar skeletons / animaciones de carga.
final FutureProvider<List<Service>> servicesAsyncProvider =
    FutureProvider<List<Service>>((final Ref ref) async {
      // Delay intencional corto para mostrar estado de carga.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return ref.watch(servicesProvider.future);
    });

// Servicios mockeados.
final FutureProvider<List<Service>> servicesProvider =
    FutureProvider<List<Service>>((final Ref ref) async {
      final Database db = await DatabaseHelper.instance.database;
      final List<Map<String, Object?>> result = await db.query('services');
      return result
          .map((Map<String, Object?> json) => Service.fromJson(json))
          .toList();
    });

// Borrador de reserva en progreso.
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
  void setDate(final DateTime date) => state = state.copyWith(date: date);
  void setDateTime(final DateTime dateTime) =>
      state = state.copyWith(dateTime: dateTime);

  void setService(final Service service) =>
      state = state.copyWith(service: service);
}

// Lista de reservas confirmadas.
class BookingsNotifier extends StateNotifier<List<Booking>> {
  BookingsNotifier() : super(const <Booking>[]) {
    _loadBookings();
  }

  Future<void> add(final Booking booking) async {
    await DatabaseHelper.instance.createBooking(booking);
    state = <Booking>[...state, booking];

    // Enviar notificaciones
    if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) {
      await NotificationService.sendWhatsApp(
        phone: booking.customerPhone!,
        message:
            'Hola ${booking.customerName}, tu reserva para ${booking.service.name} el ${booking.dateTime} ha sido confirmada.',
      );
    }

    if (booking.customerEmail != null && booking.customerEmail!.isNotEmpty) {
      await NotificationService.sendEmail(
        email: booking.customerEmail!,
        subject: 'Confirmación de Reserva - Barbería',
        body:
            'Hola ${booking.customerName},\n\nTu reserva para ${booking.service.name} ha sido confirmada para el ${booking.dateTime}.\n\nGracias por preferirnos.',
      );
    }
  }

  Future<void> cancel(String id) async {
    // Primero actualizamos el estado en memoria para reflejo inmediato (optimista)
    // o buscamos la reserva para modificarla
    final int bookingIndex = state.indexWhere((Booking b) => b.id == id);
    if (bookingIndex == -1) return;

    final Booking booking = state[bookingIndex];
    final Booking canceledBooking = Booking(
      id: booking.id,
      service: booking.service,
      dateTime: booking.dateTime,
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      customerEmail: booking.customerEmail,
      notes: booking.notes,
      status: BookingStatus.canceled,
    );

    await DatabaseHelper.instance.updateBooking(canceledBooking);

    // Recargamos o actualizamos estado local
    state = <Booking>[
      for (final Booking b in state)
        if (b.id == id) canceledBooking else b,
    ];
  }

  /// Verifica si un slot [start] con duración [duration] se solapa con
  /// alguna reserva existente (overlap estricto, bordes que tocan permiten).
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

  void rebook(String id, DateTime newStart) {
    // Implementación pendiente de persistencia si se requiere
    // Por ahora solo actualiza estado local como estaba antes,
    // idealmente debería actualizar BD también.
    state = <Booking>[
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
  }

  Future<void> _loadBookings() async {
    final List<Booking> bookings = await DatabaseHelper.instance
        .readAllBookings();
    state = bookings;
  }
}

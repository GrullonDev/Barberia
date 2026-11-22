import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resultado de una reserva exitosa vía la Cloud Function `reserveSlot`.
class ReservationResult {
  final String bookingId;
  final DateTime endAt;

  ReservationResult({required this.bookingId, required this.endAt});
}

/// Error de negocio mapeado desde Cloud Functions / Firestore, con un código
/// estable que la UI traduce a un mensaje localizado.
///
/// Códigos de `reserveSlot`/`getAvailability`: `already-exists`,
/// `failed-precondition`, `not-found`, `invalid-argument`,
/// `resource-exhausted`, `aborted` (contención: reintentar con la misma
/// clave de idempotencia). Errores de red se reportan como `unavailable`.
class BookingException implements Exception {
  final String code;
  final String message;

  BookingException(this.code, this.message);

  @override
  String toString() => message;
}

/// Transporte mínimo usado por [BookingRepository]; permite probar la lógica
/// del flujo de reservas sin Firebase.
abstract class BookingBackend {
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> data);

  /// Documentos de [collection] cuyos campos igualan [equals]; cada Map
  /// incluye su `id`.
  Future<List<Map<String, dynamic>>> query(
    String collection,
    Map<String, Object> equals,
  );
}

class FirebaseBookingBackend implements BookingBackend {
  FirebaseBookingBackend(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>> call(
    String function,
    Map<String, dynamic> data,
  ) async {
    final result = await _functions
        .httpsCallable(function)
        .call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(result.data);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String collection,
    Map<String, Object> equals,
  ) async {
    Query<Map<String, dynamic>> q = _firestore.collection(collection);
    equals.forEach((field, value) => q = q.where(field, isEqualTo: value));
    final snapshot = await q.get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }
}

/// Puerta única de escritura hacia `bookings`. El cliente NUNCA escribe
/// directo a Firestore (ver firestore.rules: `bookings.create` está
/// denegado por SDK) — todo pasa por las Cloud Functions con Admin SDK,
/// que ejecutan la transacción anti-colisión del motor de slots.
class BookingRepository {
  BookingRepository(this._backend);

  final BookingBackend _backend;

  /// Servicios activos del negocio. Cada Map incluye `id` (necesario para
  /// `reserveSlot`).
  Future<List<Map<String, dynamic>>> fetchActiveServices(String shopId) {
    return _guard(
      () => _backend.query('services', {'shopId': shopId, 'isActive': true}),
      'No se pudieron cargar los servicios.',
    );
  }

  /// Barberos públicos del negocio (vista `barber_directory`), excluyendo
  /// los marcados como no disponibles.
  Future<List<Map<String, dynamic>>> fetchBarbers(String shopId) async {
    final barbers = await _guard(
      () => _backend.query('barber_directory', {'shopId': shopId}),
      'No se pudieron cargar los barberos.',
    );
    return barbers
        .where((b) => b['shopId'] == shopId && b['isAvailable'] != false)
        .toList();
  }

  /// Slots libres (UTC) para un barbero/fecha/servicio dados, calculados
  /// server-side contra bookings y schedule_blocks reales. [date] es el día
  /// calendario del negocio (ver [bookingCalendarDay]).
  Future<List<DateTime>> fetchAvailability({
    required String shopId,
    required String barberId,
    required DateTime date,
    required String serviceId,
  }) async {
    final data = await _guard(
      () => _backend.call('getAvailability', <String, dynamic>{
        'shopId': shopId,
        'barberId': barberId,
        'dateLocal': formatBookingDate(date),
        'serviceId': serviceId,
      }),
      'No se pudo cargar la disponibilidad.',
    );
    final slots = data['slots'];
    if (slots is! List) {
      throw BookingException(
        'internal',
        'Respuesta de disponibilidad inválida.',
      );
    }
    return slots.map((s) => DateTime.parse(s as String).toUtc()).toList();
  }

  /// Reserva atómica vía la Cloud Function `reserveSlot`. Lanza
  /// [BookingException] (ver códigos en su doc). Reintentar con la misma
  /// [idempotencyKey] y el mismo payload devuelve la reserva original.
  Future<ReservationResult> reserveSlot({
    required String shopId,
    required String barberId,
    required String serviceId,
    required DateTime startAt,
    required String customerName,
    required String idempotencyKey,
    String? customerPhone,
    String? customerEmail,
    String? notes,
  }) async {
    final data = await _guard(
      () => _backend.call('reserveSlot', <String, dynamic>{
        'shopId': shopId,
        'barberId': barberId,
        'serviceId': serviceId,
        'startAtIso': startAt.toUtc().toIso8601String(),
        'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (notes != null) 'notes': notes,
        'idempotencyKey': idempotencyKey,
      }),
      'No se pudo completar la reserva.',
    );
    final bookingId = data['bookingId'];
    final endAt = data['endAtIso'];
    if (bookingId is! String || endAt is! String) {
      throw BookingException('internal', 'Respuesta de reserva inválida.');
    }
    return ReservationResult(
      bookingId: bookingId,
      endAt: DateTime.parse(endAt),
    );
  }

  /// Blocks [start, end) on a barber's agenda via `createScheduleBlock`.
  /// Fails with `failed-precondition` if an active booking overlaps it.
  Future<String> createScheduleBlock({
    required String barberId,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    final data = await _guard(
      () => _backend.call('createScheduleBlock', <String, dynamic>{
        'barberId': barberId,
        'startIso': start.toUtc().toIso8601String(),
        'endIso': end.toUtc().toIso8601String(),
        'reason': reason,
      }),
      'No se pudo crear el bloqueo.',
    );
    final blockId = data['blockId'];
    if (blockId is! String) {
      throw BookingException('internal', 'Respuesta de bloqueo inválida.');
    }
    return blockId;
  }

  Future<T> _guard<T>(Future<T> Function() run, String fallback) async {
    try {
      return await run();
    } on BookingException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw BookingException(e.code, e.message ?? fallback);
    } on FirebaseException catch (e) {
      // Firestore errors, e.g. `permission-denied` or `unavailable`.
      throw BookingException(e.code, e.message ?? fallback);
    } on TimeoutException {
      throw BookingException('unavailable', fallback);
    }
  }
}

/// `YYYY-MM-DD` of the calendar fields of [date] (no time-zone conversion).
String formatBookingDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(
    FirebaseBookingBackend(
      FirebaseFunctions.instance,
      FirebaseFirestore.instance,
    ),
  );
});

/// The business-local calendar day containing [instant], as a UTC-midnight
/// date (only its year/month/day fields are meaningful).
DateTime bookingCalendarDay(DateTime instant, int offsetHours) {
  final shopTime = instant.toUtc().add(Duration(hours: offsetHours));
  return DateTime.utc(shopTime.year, shopTime.month, shopTime.day);
}

double bookingServicePrice(Map<String, dynamic> service) {
  final cents = service['priceCents'];
  if (cents is num) return cents / 100;
  final price = service['price'];
  return price is num ? price.toDouble() : 0;
}

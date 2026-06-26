import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resultado de una reserva exitosa vía la Cloud Function `reserveSlot`.
class ReservationResult {
  final String bookingId;
  final DateTime endAt;

  ReservationResult({required this.bookingId, required this.endAt});
}

/// Error de negocio mapeado desde un [FirebaseFunctionsException], con un
/// mensaje ya listo para mostrar en un SnackBar (ES/EN se resuelve en la UI).
class BookingException implements Exception {
  final String code;
  final String message;

  BookingException(this.code, this.message);

  @override
  String toString() => message;
}

/// Puerta única de escritura hacia `bookings`. El cliente NUNCA escribe
/// directo a Firestore (ver firestore.rules: `bookings.create` está
/// denegado por SDK) — todo pasa por las Cloud Functions con Admin SDK,
/// que ejecutan la transacción anti-colisión del motor de slots.
class BookingRepository {
  BookingRepository(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  /// Servicios activos reales desde Firestore (reemplaza el catálogo
  /// hardcodeado). Cada Map incluye `id` (necesario para `reserveSlot`).
  Future<List<Map<String, dynamic>>> fetchActiveServices() async {
    final snap = await _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Slots libres (UTC) para un barbero/fecha/servicio dados, calculados
  /// server-side contra bookings y schedule_blocks reales.
  Future<List<DateTime>> fetchAvailability({
    required String barberId,
    required DateTime date,
    required String serviceId,
  }) async {
    try {
      final callable = _functions.httpsCallable('getAvailability');
      final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'barberId': barberId,
        'dateIso': date.toUtc().toIso8601String(),
        'serviceId': serviceId,
      });
      final slots = (result.data['slots'] as List).cast<String>();
      return slots.map((s) => DateTime.parse(s)).toList();
    } on FirebaseFunctionsException catch (e) {
      throw BookingException(e.code, e.message ?? 'No se pudo cargar la disponibilidad.');
    }
  }

  /// Reserva atómica vía la Cloud Function `reserveSlot`. Lanza
  /// [BookingException] con un código (`already-exists`, `failed-precondition`,
  /// `not-found`, `invalid-argument`) que la UI mapea a un mensaje localizado.
  Future<ReservationResult> reserveSlot({
    required String barberId,
    required String serviceId,
    required DateTime startAt,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? userId,
  }) async {
    try {
      final callable = _functions.httpsCallable('reserveSlot');
      final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'barberId': barberId,
        'serviceId': serviceId,
        'startAtIso': startAt.toUtc().toIso8601String(),
        'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (notes != null) 'notes': notes,
        if (userId != null) 'userId': userId,
      });
      final data = result.data;
      return ReservationResult(
        bookingId: data['bookingId'] as String,
        endAt: DateTime.parse(data['endAtIso'] as String),
      );
    } on FirebaseFunctionsException catch (e) {
      throw BookingException(e.code, e.message ?? 'No se pudo completar la reserva.');
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(FirebaseFunctions.instance, FirebaseFirestore.instance);
});

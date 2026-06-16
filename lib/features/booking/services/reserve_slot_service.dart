import 'package:cloud_functions/cloud_functions.dart';

/// Resultado exitoso de `reserveSlot`.
class ReserveSlotResult {
  final String bookingId;
  final DateTime endAt;

  const ReserveSlotResult({required this.bookingId, required this.endAt});
}

/// Errores de dominio del flujo de reserva. Se mapean desde
/// `FirebaseFunctionsException` para desacoplar la UI del SDK.
enum ReserveSlotErrorKind {
  invalidInput,
  barberUnavailable,
  serviceInactive,
  outsideWorkingHours,
  reputationBlocked,
  alreadyTaken,
  network,
  unknown,
}

class ReserveSlotException implements Exception {
  final ReserveSlotErrorKind kind;
  final String message;

  const ReserveSlotException(this.kind, this.message);

  @override
  String toString() => 'ReserveSlotException($kind): $message';
}

/// Wrapper tipado sobre la Cloud Function `reserveSlot`.
///
/// Contrato del CF (ver `backend/functions/main.py`):
///   Input:
///     barberId       String
///     serviceId      String
///     startAtIso     String (ISO 8601 UTC)
///     customerName   String
///     customerPhone  String?
///     customerEmail  String?
///     notes          String?
///     userId         String?  (default = auth.uid o 'guest')
///   Output:
///     bookingId      String
///     endAtIso       String (ISO 8601 UTC)
class ReserveSlotService {
  ReserveSlotService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<ReserveSlotResult> reserve({
    required String barberId,
    required String serviceId,
    required DateTime startAt,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? userId,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('reserveSlot');
    try {
      final HttpsCallableResult<dynamic> result = await callable
          .call<dynamic>(<String, dynamic>{
            'barberId': barberId,
            'serviceId': serviceId,
            'startAtIso': startAt.toUtc().toIso8601String(),
            'customerName': customerName,
            'customerPhone': customerPhone,
            'customerEmail': customerEmail,
            'notes': notes,
            'userId': userId,
          });
      final Map<Object?, Object?> data =
          (result.data as Map<Object?, Object?>? ?? <Object?, Object?>{});
      final String bookingId = data['bookingId'] as String? ?? '';
      final String endAtIso = data['endAtIso'] as String? ?? '';
      return ReserveSlotResult(
        bookingId: bookingId,
        endAt: DateTime.parse(endAtIso),
      );
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  /// Versión read-only que consulta disponibilidad (no reserva).
  /// Útil en el calendario para pintar slots sin lecturas masivas.
  Future<List<DateTime>> getAvailability({
    required String barberId,
    required String serviceId,
    required DateTime date,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('getAvailability');
    try {
      final HttpsCallableResult<dynamic> result = await callable
          .call<dynamic>(<String, dynamic>{
            'barberId': barberId,
            'serviceId': serviceId,
            'dateIso': date.toUtc().toIso8601String(),
          });
      final Map<Object?, Object?> data =
          (result.data as Map<Object?, Object?>? ?? <Object?, Object?>{});
      final List<dynamic> slots =
          (data['slots'] as List<dynamic>?) ?? <dynamic>[];
      return slots
          .whereType<String>()
          .map(DateTime.parse)
          .toList(growable: false);
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  ReserveSlotException _mapError(FirebaseFunctionsException e) {
    final String msg = e.message ?? '';
    switch (e.code) {
      case 'invalid-argument':
        return ReserveSlotException(ReserveSlotErrorKind.invalidInput, msg);
      case 'not-found':
        return ReserveSlotException(ReserveSlotErrorKind.invalidInput, msg);
      case 'failed-precondition':
        if (msg.contains('Barbero')) {
          return ReserveSlotException(
            ReserveSlotErrorKind.barberUnavailable,
            msg,
          );
        }
        if (msg.contains('Servicio')) {
          return ReserveSlotException(
            ReserveSlotErrorKind.serviceInactive,
            msg,
          );
        }
        if (msg.contains('Horario')) {
          return ReserveSlotException(
            ReserveSlotErrorKind.outsideWorkingHours,
            msg,
          );
        }
        if (msg.contains('Cliente bloqueado')) {
          return ReserveSlotException(
            ReserveSlotErrorKind.reputationBlocked,
            msg,
          );
        }
        return ReserveSlotException(ReserveSlotErrorKind.unknown, msg);
      case 'already-exists':
        return ReserveSlotException(ReserveSlotErrorKind.alreadyTaken, msg);
      case 'unavailable':
      case 'deadline-exceeded':
        return ReserveSlotException(ReserveSlotErrorKind.network, msg);
      default:
        return ReserveSlotException(ReserveSlotErrorKind.unknown, msg);
    }
  }
}

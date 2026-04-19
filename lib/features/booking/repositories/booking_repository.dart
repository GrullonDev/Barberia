import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/services/reserve_slot_service.dart';

/// Acceso a la colección `bookings/`.
///
/// **Creación de bookings (cliente final):** se hace por la Cloud Function
/// `reserveSlot` mediante [createBookingViaCloudFunction]. Las reglas
/// de Firestore bloquean escritura directa para clientes, así que esta es
/// la única puerta válida — la función corre una transacción contra
/// colisiones que ningún SDK directo puede replicar de forma segura.
///
/// **Creación directa (staff):** [createBookingDirect] permite que admin
/// o barbero creen a nombre de un cliente desde el panel (p. ej. walk-ins).
/// Las reglas SÍ permiten staff.create.
class BookingRepository {
  BookingRepository({
    FirebaseFirestore? db,
    ReserveSlotService? reserveSlotService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _reserveSlotService = reserveSlotService ?? ReserveSlotService();

  final FirebaseFirestore _db;
  final ReserveSlotService _reserveSlotService;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  // ---------------------------------------------------------------------------
  // Lectura
  // ---------------------------------------------------------------------------

  Future<List<Booking>> getBookings(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(Booking.fromFirestore).toList();
  }

  Future<List<Booking>> getForBarber({
    required String barberId,
    required DateTime from,
    required DateTime to,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date')
        .get();
    return snap.docs.map(Booking.fromFirestore).toList();
  }

  Stream<List<Booking>> watchForBarber({
    required String barberId,
    required DateTime from,
    required DateTime to,
  }) {
    return _col
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) =>
            snap.docs.map(Booking.fromFirestore).toList());
  }

  Future<List<Booking>> getAllBookingsAdmin() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.orderBy('date', descending: true).limit(200).get();
    return snap.docs.map(Booking.fromFirestore).toList();
  }

  // ---------------------------------------------------------------------------
  // Creación
  // ---------------------------------------------------------------------------

  /// Crea un booking invocando `reserveSlot` en Cloud Functions.
  /// Lanza [ReserveSlotException] en conflicto/validación.
  Future<ReserveSlotResult> createBookingViaCloudFunction({
    required String barberId,
    required String serviceId,
    required DateTime startAt,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    String? userId,
  }) {
    return _reserveSlotService.reserve(
      barberId: barberId,
      serviceId: serviceId,
      startAt: startAt,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      notes: notes,
      userId: userId,
    );
  }

  /// Creación directa por staff (admin/barbero). Útil para walk-ins del
  /// panel, no pasa por el CF. Las reglas Firestore requieren staff.
  Future<void> createBookingDirect(Booking booking) async {
    await _col.doc(booking.id).set(booking.toFirestore());
  }

  /// [DEPRECATED] Conservado por compatibilidad hasta que todos los
  /// callsites migren a [createBookingViaCloudFunction] (cliente) o a
  /// [createBookingDirect] (staff). Para cliente final, NO usar: las
  /// reglas bloquean la escritura y el call fallará.
  @Deprecated(
      'Usar createBookingViaCloudFunction (cliente) o createBookingDirect (staff).')
  Future<void> createBooking(Booking booking) => createBookingDirect(booking);

  // ---------------------------------------------------------------------------
  // Mutaciones de estado
  // ---------------------------------------------------------------------------

  Future<void> updateStatus({
    required String id,
    required BookingStatus status,
    CancelReason? cancelReason,
  }) async {
    await _col.doc(id).update(<String, dynamic>{
      'status': status.name,
      if (status == BookingStatus.canceled && cancelReason != null)
        'cancelReason': cancelReason.name,
      if (status == BookingStatus.confirmed)
        'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelBooking(
    String id, {
    CancelReason reason = CancelReason.byCustomer,
  }) =>
      updateStatus(id: id, status: BookingStatus.canceled, cancelReason: reason);
}

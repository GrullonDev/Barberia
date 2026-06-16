import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/features/barber/models/barber.dart';

/// Operaciones de lectura/escritura sobre la colección pública `barbers/`.
///
/// Las reglas Firestore permiten lectura pública (catálogo para el cliente)
/// pero solo `admin` puede escribir. Alta/baja de barbero se hace desde el
/// panel admin o Cloud Function.
class BarberRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('barbers');

  /// Genera un id nuevo para un barbero (alta desde el panel admin).
  String newId() => _col.doc().id;

  /// Lista de barberos disponibles, útil para que el cliente elija.
  Future<List<Barber>> getAvailable() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('isAvailable', isEqualTo: true)
        .get();
    return snap.docs.map(Barber.fromFirestore).toList();
  }

  /// Todos los barberos (staff lo usa para asignación y gestión).
  Future<List<Barber>> getAll() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col.get();
    return snap.docs.map(Barber.fromFirestore).toList();
  }

  Future<Barber?> getById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return Barber.fromFirestore(doc);
  }

  /// Stream reactivo de un barbero concreto (para la página de settings del propio barbero).
  Stream<Barber?> watchById(String id) => _col.doc(id).snapshots().map(
    (DocumentSnapshot<Map<String, dynamic>> doc) =>
        doc.exists ? Barber.fromFirestore(doc) : null,
  );

  /// Stream reactivo (para la agenda admin).
  Stream<List<Barber>> watchAll() => _col.snapshots().map(
    (QuerySnapshot<Map<String, dynamic>> snap) =>
        snap.docs.map(Barber.fromFirestore).toList(),
  );

  Future<void> upsert(Barber barber) async {
    await _col
        .doc(barber.id)
        .set(barber.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setAvailability({
    required String id,
    required bool available,
  }) async {
    await _col.doc(id).update(<String, dynamic>{'isAvailable': available});
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

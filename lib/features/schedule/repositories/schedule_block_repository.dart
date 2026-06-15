import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/features/schedule/models/schedule_block.dart';

/// CRUD de bloqueos de horario (comida, descanso, vacaciones).
///
/// La validación de colisiones (un bloque sobre una cita existente) se hace
/// en la Cloud Function `createScheduleBlock` de Fase 2+. El cliente solo
/// CRUD directo.
class ScheduleBlockRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('schedule_blocks');

  /// Bloques de un barbero que solapan con [from, to].
  /// Incluye bloques puntuales; la expansión de recurrentes se hace en el
  /// motor de slots, no aquí.
  Future<List<ScheduleBlock>> getForBarber({
    required String barberId,
    required DateTime from,
    required DateTime to,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('barberId', isEqualTo: barberId)
        .where('startTime', isLessThan: Timestamp.fromDate(to))
        .orderBy('startTime')
        .get();
    return snap.docs
        .map(ScheduleBlock.fromFirestore)
        .where((ScheduleBlock b) => b.endTime.isAfter(from))
        .toList();
  }

  /// Stream reactivo para la agenda del barbero.
  Stream<List<ScheduleBlock>> watchForBarber(String barberId) {
    return _col
        .where('barberId', isEqualTo: barberId)
        .orderBy('startTime')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) =>
              snap.docs.map(ScheduleBlock.fromFirestore).toList(),
        );
  }

  Future<String> create(ScheduleBlock block) async {
    final DocumentReference<Map<String, dynamic>> ref = await _col.add(
      block.toFirestore(),
    );
    return ref.id;
  }

  Future<void> update(ScheduleBlock block) async {
    await _col.doc(block.id).update(block.toFirestore());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

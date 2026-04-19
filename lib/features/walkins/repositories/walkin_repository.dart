import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/features/walkins/models/walkin.dart';

class WalkInRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('walkins');

  /// Cola activa (waiting + inService) ordenada por llegada.
  Stream<List<WalkIn>> watchActive() {
    return _col
        .where('status', whereIn: <String>[
          WalkInStatus.waiting.name,
          WalkInStatus.inService.name,
        ])
        .orderBy('createdAt')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) =>
            snap.docs.map(WalkIn.fromFirestore).toList());
  }

  /// Solo los que están esperando, útil para estimación de espera.
  Future<int> waitingCount() async {
    final AggregateQuerySnapshot snap = await _col
        .where('status', isEqualTo: WalkInStatus.waiting.name)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<String> create(WalkIn walkin) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _col.add(walkin.toFirestore());
    return ref.id;
  }

  Future<void> assignTo({
    required String id,
    required String barberId,
  }) async {
    await _col.doc(id).update(<String, dynamic>{
      'assignedBarberId': barberId,
      'status': WalkInStatus.inService.name,
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> complete(String id) async {
    await _col.doc(id).update(<String, dynamic>{
      'status': WalkInStatus.done.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markLeft(String id) async {
    await _col.doc(id).update(<String, dynamic>{
      'status': WalkInStatus.left.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}

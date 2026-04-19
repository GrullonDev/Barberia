import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/features/config/models/barberia_config.dart';

/// Acceso al doc único `config/barberia`.
class BarberiaConfigRepository {
  static const String _docId = 'barberia';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('config').doc(_docId);

  Future<BarberiaConfig> get() async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _doc.get();
    if (!snap.exists) return const BarberiaConfig();
    return BarberiaConfig.fromFirestore(snap);
  }

  /// Stream reactivo: la UI puede reaccionar si admin edita el horario.
  Stream<BarberiaConfig> watch() => _doc.snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> snap) => snap.exists
            ? BarberiaConfig.fromFirestore(snap)
            : const BarberiaConfig(),
      );

  Future<void> upsert(BarberiaConfig config) async {
    await _doc.set(config.toFirestore(), SetOptions(merge: true));
  }
}

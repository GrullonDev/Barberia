import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/features/reputation/models/reputation.dart';
import 'package:barberia/common/utils/phone_normalizer.dart';

/// Lectura de reputación. La ESCRITURA real la hace la Cloud Function
/// `updateReputationOnStatusChange` de forma transaccional (Fase 4).
/// Desde el cliente solo debería llamarse [setBlocked] por un admin.
class ReputationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reputation');

  /// Devuelve la reputación del teléfono (normalizado internamente).
  /// Si no existe, devuelve [Reputation.neutral].
  Future<Reputation> getByPhone(String rawPhone) async {
    final String key = normalizePhone(rawPhone);
    if (key.isEmpty) return Reputation.neutral('');
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col.doc(key).get();
    if (!doc.exists) return Reputation.neutral(key);
    return Reputation.fromFirestore(doc);
  }

  /// Lista reputaciones con algún no-show, para el panel admin.
  Future<List<Reputation>> getWithNoShows({int limit = 100}) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('noShowCount', isGreaterThan: 0)
        .orderBy('noShowCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(Reputation.fromFirestore).toList();
  }

  /// Admin puede bloquear/desbloquear manualmente.
  Future<void> setBlocked({
    required String phoneNormalized,
    required bool blocked,
    String? reason,
  }) async {
    await _col.doc(phoneNormalized).set(
      <String, dynamic>{
        'blocked': blocked,
        'blockReason': blocked ? reason : null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

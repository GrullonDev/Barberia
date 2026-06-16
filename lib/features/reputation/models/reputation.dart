import 'package:cloud_firestore/cloud_firestore.dart';

/// Reputación de un cliente para anti-no-show.
///
/// El id del documento es el teléfono normalizado (ver
/// `common/utils/phone_normalizer.dart`). De esta forma tanto clientes
/// registrados como invitados comparten el mismo histórico si usan el
/// mismo número.
///
/// Actualizado server-side por la Cloud Function `updateReputationOnStatusChange`
/// que escucha los cambios de `bookings/{id}.status` (Fase 4).
class Reputation {
  final String phoneNormalized;
  final int noShowCount;
  final int canceledLateCount;
  final int totalBookings;
  final DateTime? lastNoShowAt;
  final bool blocked;
  final String? blockReason;
  final DateTime? updatedAt;

  const Reputation({
    required this.phoneNormalized,
    this.noShowCount = 0,
    this.canceledLateCount = 0,
    this.totalBookings = 0,
    this.lastNoShowAt,
    this.blocked = false,
    this.blockReason,
    this.updatedAt,
  });

  /// Score simple para UI: 100 = perfecto, baja con no-shows y cancelaciones tardías.
  /// Usado en el panel admin para ordenar la lista.
  int get score {
    if (totalBookings == 0) {
      return 100;
    }
    final double penalty =
        (noShowCount * 25 + canceledLateCount * 10) / totalBookings;
    final int raw = (100 - penalty * 10).round();
    return raw.clamp(0, 100);
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'noShowCount': noShowCount,
    'canceledLateCount': canceledLateCount,
    'totalBookings': totalBookings,
    'lastNoShowAt': lastNoShowAt == null
        ? null
        : Timestamp.fromDate(lastNoShowAt!),
    'blocked': blocked,
    'blockReason': blockReason,
    'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
  };

  factory Reputation.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Reputation(
      phoneNormalized: doc.id,
      noShowCount: (data['noShowCount'] as num?)?.toInt() ?? 0,
      canceledLateCount: (data['canceledLateCount'] as num?)?.toInt() ?? 0,
      totalBookings: (data['totalBookings'] as num?)?.toInt() ?? 0,
      lastNoShowAt: (data['lastNoShowAt'] as Timestamp?)?.toDate(),
      blocked: data['blocked'] as bool? ?? false,
      blockReason: data['blockReason'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Reputación vacía por defecto para clientes sin histórico.
  factory Reputation.neutral(String phoneNormalized) =>
      Reputation(phoneNormalized: phoneNormalized);
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado de un walk-in (cliente que llega sin cita).
///
/// - [waiting]: en cola, esperando turno.
/// - [inService]: un barbero ya lo tomó, en atención.
/// - [done]: atendido, listo. Histórico.
/// - [left]: se fue sin ser atendido. Para métricas de dead time.
enum WalkInStatus { waiting, inService, done, left }

/// Cliente sin cita que el barbero/recepcionista registra al llegar.
///
/// No requiere auth; se identifica solo por nombre + teléfono. Al entrar en
/// servicio, se puede (opcional) convertir en Booking para que caiga en el
/// histórico de reputación como cualquier cita.
class WalkIn {
  final String id;
  final String customerName;
  final String? customerPhone;
  final String? phoneNormalized;
  final String? assignedBarberId;
  final int estimatedWaitMinutes;
  final WalkInStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;

  const WalkIn({
    required this.id,
    required this.customerName,
    required this.createdAt,
    this.customerPhone,
    this.phoneNormalized,
    this.assignedBarberId,
    this.estimatedWaitMinutes = 0,
    this.status = WalkInStatus.waiting,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  WalkIn copyWith({
    String? customerName,
    String? customerPhone,
    String? phoneNormalized,
    String? assignedBarberId,
    int? estimatedWaitMinutes,
    WalkInStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
  }) => WalkIn(
        id: id,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        phoneNormalized: phoneNormalized ?? this.phoneNormalized,
        assignedBarberId: assignedBarberId ?? this.assignedBarberId,
        estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'customerName': customerName,
        'customerPhone': customerPhone,
        'phoneNormalized': phoneNormalized,
        'assignedBarberId': assignedBarberId,
        'estimatedWaitMinutes': estimatedWaitMinutes,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'startedAt': startedAt == null ? null : Timestamp.fromDate(startedAt!),
        'completedAt':
            completedAt == null ? null : Timestamp.fromDate(completedAt!),
        'notes': notes,
      };

  factory WalkIn.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WalkIn(
      id: doc.id,
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String?,
      phoneNormalized: data['phoneNormalized'] as String?,
      assignedBarberId: data['assignedBarberId'] as String?,
      estimatedWaitMinutes: (data['estimatedWaitMinutes'] as num?)?.toInt() ?? 0,
      status: WalkInStatus.values.firstWhere(
        (WalkInStatus s) => s.name == (data['status'] as String?),
        orElse: () => WalkInStatus.waiting,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }
}

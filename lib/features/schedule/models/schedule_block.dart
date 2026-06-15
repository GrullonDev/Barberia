import 'package:cloud_firestore/cloud_firestore.dart';

/// Motivo típico del bloqueo — se usa como etiqueta en la agenda del barbero.
enum ScheduleBlockReason { lunch, breakTime, vacation, personal, custom }

/// Periodicidad del bloqueo.
///
/// - [none]: bloqueo puntual (un rango start/end).
/// - [daily]: se repite todos los días en la misma franja horaria.
/// - [weekly]: se repite cada semana el mismo día.
///
/// El motor de slots lee estas reglas y descarta los slots que caen dentro
/// del bloqueo antes de ofrecerlos al cliente.
enum ScheduleRecurrence { none, daily, weekly }

/// Bloque de horario no disponible para citas.
///
/// Cubre: comida del barbero, descansos, vacaciones, imprevistos, ausencias.
/// El bloqueo es POR BARBERO — si un barbero se bloquea, los demás siguen
/// disponibles. Un admin puede crear bloqueos para cualquier barbero; un
/// barbero solo para sí mismo (controlado por reglas Firestore).
class ScheduleBlock {
  final String id;
  final String barberId;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleBlockReason reason;
  final ScheduleRecurrence recurrence;
  final String? notes;
  final DateTime createdAt;

  const ScheduleBlock({
    required this.id,
    required this.barberId,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.reason = ScheduleBlockReason.custom,
    this.recurrence = ScheduleRecurrence.none,
    this.notes,
  });

  Duration get duration => endTime.difference(startTime);

  ScheduleBlock copyWith({
    DateTime? startTime,
    DateTime? endTime,
    ScheduleBlockReason? reason,
    ScheduleRecurrence? recurrence,
    String? notes,
  }) => ScheduleBlock(
    id: id,
    barberId: barberId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    reason: reason ?? this.reason,
    recurrence: recurrence ?? this.recurrence,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'barberId': barberId,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'reason': reason.name,
    'recurrence': recurrence.name,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory ScheduleBlock.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ScheduleBlock(
      id: doc.id,
      barberId: data['barberId'] as String? ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: ScheduleBlockReason.values.firstWhere(
        (ScheduleBlockReason r) => r.name == (data['reason'] as String?),
        orElse: () => ScheduleBlockReason.custom,
      ),
      recurrence: ScheduleRecurrence.values.firstWhere(
        (ScheduleRecurrence r) => r.name == (data['recurrence'] as String?),
        orElse: () => ScheduleRecurrence.none,
      ),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

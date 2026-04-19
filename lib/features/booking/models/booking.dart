import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/common/utils/phone_normalizer.dart';
import 'service.dart';

/// Estado del ciclo de vida de una cita.
///
/// Flujo normal: `pending → confirmed → inProgress → done`.
/// Variantes: `noShow` (no llegó), `canceled` (cancelada por cliente/staff o
/// liberada automáticamente por falta de confirmación).
///
/// Nota: el enum viejo solo tenía `active/canceled`. Para retro-compat, al leer
/// Firestore mapeamos `active → pending`. La migración a valores nuevos se
/// hace con `tool/migrate_bookings_v2.dart`.
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  done,
  noShow,
  canceled,
}

/// Motivo por el que se cancela/libera una cita.
enum CancelReason {
  byCustomer,   // canceló el cliente
  byStaff,      // canceló la barbería
  notConfirmed, // auto-liberada por no confirmar a tiempo
  other,
}

/// Cita (v2).
///
/// Cambios vs v1:
///   - `barberId`: barbero asignado ('' si todavía no hay selección).
///   - `endAt`: fin stored (no computado), necesario para motor de slots atómico.
///   - `serviceDurationMinutes` + `servicePrice`: denormalizados — si el admin
///     edita el servicio, el histórico mantiene el precio y duración reales.
///   - `phoneNormalized`: clave de join con colección `reputation`.
///   - `confirmationSentAt` / `confirmedAt`: auditoría del flujo 24h.
///   - `cancelReason`: para reporting.
///   - `createdAt` / `updatedAt`: auditoría básica.
class Booking {
  final String id;
  final String userId;
  final String barberId;
  final String serviceId;
  final String serviceName;
  final int serviceDurationMinutes;
  final double servicePrice;
  final DateTime startAt;
  final DateTime endAt;
  final BookingStatus status;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? phoneNormalized;
  final String? notes;
  final DateTime? confirmationSentAt;
  final DateTime? confirmedAt;
  final CancelReason? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Solo client-side: referencia completa al servicio si está disponible.
  /// No se persiste — siempre se reconstruye desde `serviceId` si hace falta.
  final Service? service;

  const Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.startAt,
    required this.endAt,
    required this.customerName,
    required this.createdAt,
    required this.updatedAt,
    this.barberId = '',
    this.serviceDurationMinutes = 30,
    this.servicePrice = 0,
    this.customerEmail,
    this.customerPhone,
    this.phoneNormalized,
    this.notes,
    this.status = BookingStatus.pending,
    this.confirmationSentAt,
    this.confirmedAt,
    this.cancelReason,
    this.service,
  });

  // ---------------------------------------------------------------------------
  // Back-compat getters — código viejo que usa `dateTime` / `endTime` sigue
  // funcionando sin tocarlo (p.ej. appointment_card, booking_summary, ICS).
  // ---------------------------------------------------------------------------
  DateTime get dateTime => startAt;
  DateTime get endTime => endAt;

  /// Estados que cuentan como "ocupan slot" para cómputo de disponibilidad.
  bool get occupiesSlot =>
      status == BookingStatus.pending ||
      status == BookingStatus.confirmed ||
      status == BookingStatus.inProgress;

  /// Factoría conveniente para construir la cita a partir del Service real.
  /// Calcula endAt automáticamente y denormaliza duración y precio.
  factory Booking.create({
    required String id,
    required String userId,
    required String barberId,
    required Service service,
    required DateTime startAt,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    String? notes,
  }) {
    final DateTime now = DateTime.now();
    return Booking(
      id: id,
      userId: userId,
      barberId: barberId,
      serviceId: service.id ?? '',
      serviceName: service.name,
      serviceDurationMinutes: service.durationMinutes,
      servicePrice: service.price,
      startAt: startAt,
      endAt: startAt.add(Duration(minutes: service.durationMinutes)),
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      phoneNormalized: normalizePhone(customerPhone),
      notes: notes,
      status: BookingStatus.pending,
      createdAt: now,
      updatedAt: now,
      service: service,
    );
  }

  Booking copyWith({
    String? barberId,
    DateTime? startAt,
    DateTime? endAt,
    BookingStatus? status,
    String? notes,
    DateTime? confirmationSentAt,
    DateTime? confirmedAt,
    CancelReason? cancelReason,
  }) => Booking(
        id: id,
        userId: userId,
        barberId: barberId ?? this.barberId,
        serviceId: serviceId,
        serviceName: serviceName,
        serviceDurationMinutes: serviceDurationMinutes,
        servicePrice: servicePrice,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        status: status ?? this.status,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        phoneNormalized: phoneNormalized,
        notes: notes ?? this.notes,
        confirmationSentAt: confirmationSentAt ?? this.confirmationSentAt,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        cancelReason: cancelReason ?? this.cancelReason,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        service: service,
      );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'userId': userId,
        'barberId': barberId,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'serviceDurationMinutes': serviceDurationMinutes,
        'servicePrice': servicePrice,
        // `date` se mantiene por back-compat (viejas queries usan ese nombre).
        // `startAt` es el nombre canónico nuevo.
        'date': Timestamp.fromDate(startAt),
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'status': status.name,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'phoneNormalized': phoneNormalized,
        'notes': notes,
        'confirmationSentAt': confirmationSentAt == null
            ? null
            : Timestamp.fromDate(confirmationSentAt!),
        'confirmedAt':
            confirmedAt == null ? null : Timestamp.fromDate(confirmedAt!),
        'cancelReason': cancelReason?.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Retro-compat: viejo campo `date` si no existe `startAt`.
    final DateTime startAt = (data['startAt'] as Timestamp?)?.toDate() ??
        (data['date'] as Timestamp?)?.toDate() ??
        DateTime.now();

    // Retro-compat: calcula endAt desde duración si no viene en el doc.
    final int duration =
        (data['serviceDurationMinutes'] as num?)?.toInt() ?? 30;
    final DateTime endAt = (data['endAt'] as Timestamp?)?.toDate() ??
        startAt.add(Duration(minutes: duration));

    // Retro-compat: status viejo `active` → `pending`.
    final String rawStatus = (data['status'] as String?) ?? 'pending';
    final BookingStatus status = rawStatus == 'active'
        ? BookingStatus.pending
        : BookingStatus.values.firstWhere(
            (BookingStatus s) => s.name == rawStatus,
            orElse: () => BookingStatus.pending,
          );

    final DateTime now = DateTime.now();
    return Booking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      barberId: data['barberId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? 'Servicio',
      serviceDurationMinutes: duration,
      servicePrice: (data['servicePrice'] as num?)?.toDouble() ?? 0,
      startAt: startAt,
      endAt: endAt,
      status: status,
      customerName: data['customerName'] as String? ?? '',
      customerEmail: data['customerEmail'] as String?,
      customerPhone: data['customerPhone'] as String?,
      phoneNormalized: data['phoneNormalized'] as String?,
      notes: data['notes'] as String?,
      confirmationSentAt:
          (data['confirmationSentAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      cancelReason: CancelReason.values.firstWhere(
        (CancelReason r) => r.name == (data['cancelReason'] as String?),
        orElse: () => CancelReason.other,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'barberId': barberId,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'serviceDurationMinutes': serviceDurationMinutes,
        'servicePrice': servicePrice,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'status': status.name,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'phoneNormalized': phoneNormalized,
        'notes': notes,
        'confirmationSentAt': confirmationSentAt?.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
        'cancelReason': cancelReason?.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Booking.fromMap(Map<String, dynamic> map, {Service? linkedService}) {
    final DateTime startAt = map['startAt'] != null
        ? DateTime.tryParse(map['startAt'] as String) ?? DateTime.now()
        : map['date'] != null
            ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
            : DateTime.now();
    final int duration =
        (map['serviceDurationMinutes'] as num?)?.toInt() ?? 30;
    final DateTime endAt = map['endAt'] != null
        ? DateTime.tryParse(map['endAt'] as String) ??
            startAt.add(Duration(minutes: duration))
        : startAt.add(Duration(minutes: duration));

    final String rawStatus = (map['status'] as String?) ?? 'pending';
    final BookingStatus status = rawStatus == 'active'
        ? BookingStatus.pending
        : BookingStatus.values.firstWhere(
            (BookingStatus s) => s.name == rawStatus,
            orElse: () => BookingStatus.pending,
          );

    final DateTime now = DateTime.now();
    return Booking(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? 'guest',
      barberId: map['barberId']?.toString() ?? '',
      serviceId: map['serviceId']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? 'Servicio',
      serviceDurationMinutes: duration,
      servicePrice: (map['servicePrice'] as num?)?.toDouble() ?? 0,
      startAt: startAt,
      endAt: endAt,
      status: status,
      customerName: map['customerName']?.toString() ?? '',
      customerEmail: map['customerEmail'] as String?,
      customerPhone: map['customerPhone'] as String?,
      phoneNormalized: map['phoneNormalized'] as String?,
      notes: map['notes'] as String?,
      confirmationSentAt: map['confirmationSentAt'] != null
          ? DateTime.tryParse(map['confirmationSentAt'] as String)
          : null,
      confirmedAt: map['confirmedAt'] != null
          ? DateTime.tryParse(map['confirmedAt'] as String)
          : null,
      cancelReason: map['cancelReason'] != null
          ? CancelReason.values.firstWhere(
              (CancelReason r) => r.name == map['cancelReason'],
              orElse: () => CancelReason.other,
            )
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? now
          : now,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? now
          : now,
      service: linkedService,
    );
  }

  String toIcsString() {
    final String dtStart = _formatIcsDateTime(startAt.toUtc());
    final String dtEnd = _formatIcsDateTime(endAt.toUtc());
    final String summary = '$serviceName - Barbería';
    final String uid = 'booking-$id@barberia';
    return <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Barberia//ES',
      'CALSCALE:GREGORIAN',
      'BEGIN:VEVENT',
      'UID:$uid',
      'SUMMARY:${_escapeText(summary)}',
      'DTSTART:$dtStart',
      'DTEND:$dtEnd',
      if (customerName.isNotEmpty)
        'DESCRIPTION:${_escapeText('Cliente: $customerName')}',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\n');
  }

  static String _formatIcsDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}T${two(dt.hour)}${two(dt.minute)}${two(dt.second)}Z';
  }

  static String _escapeText(String input) => input
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');
}

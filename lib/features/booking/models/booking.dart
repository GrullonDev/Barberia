import 'package:cloud_firestore/cloud_firestore.dart';
import 'service.dart';

class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName; // Denormalized for display if service deleted
  final DateTime dateTime;
  final BookingStatus status;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? notes;

  // Optional full service object if available
  final Service? service;

  const Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.dateTime,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.notes,
    this.status = BookingStatus.active,
    this.service,
  });

  DateTime get endTime {
    final duration = service?.durationMinutes ?? 30;
    return dateTime.add(Duration(minutes: duration));
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'date': Timestamp.fromDate(dateTime),
      'status': status.name,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'notes': notes,
    };
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? 'Servicio',
      dateTime: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => BookingStatus.active,
      ),
      customerName: data['customerName'] as String? ?? '',
      customerEmail: data['customerEmail'] as String?,
      customerPhone: data['customerPhone'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'date': dateTime.toIso8601String(),
      'status': status.name,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'notes': notes,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, {Service? linkedService}) {
    return Booking(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? 'guest',
      serviceId: map['serviceId']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? 'Servicio',
      dateTime: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => BookingStatus.active,
      ),
      customerName: map['customerName']?.toString() ?? '',
      customerEmail: map['customerEmail'] as String?,
      customerPhone: map['customerPhone'] as String?,
      notes: map['notes'] as String?,
      service: linkedService,
    );
  }

  String toIcsString() {
    final String dtStart = _formatIcsDateTime(dateTime.toUtc());
    final String dtEnd = _formatIcsDateTime(endTime.toUtc());
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

enum BookingStatus { active, canceled }

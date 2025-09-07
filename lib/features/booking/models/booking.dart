import 'service.dart';

class Booking {
  final String id;
  final Service service;
  final DateTime dateTime;
  final String customerName;
  final String? customerPhone; // Ahora opcional: se permite solo email.
  final String? customerEmail;
  final String? notes;

  const Booking({
    required this.id,
    required this.service,
    required this.dateTime,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.notes,
  });

  DateTime get endTime => dateTime.add(Duration(minutes: service.durationMinutes));

  String toIcsString() {
    final String dtStart = _formatIcsDateTime(dateTime.toUtc());
    final String dtEnd = _formatIcsDateTime(endTime.toUtc());
    final String summary = '${service.name} - Barbería';
    final String uid = 'booking-${id}@barberia';
    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Barberia//ES',
      'CALSCALE:GREGORIAN',
      'BEGIN:VEVENT',
      'UID:$uid',
      'SUMMARY:${_escapeText(summary)}',
      'DTSTART:$dtStart',
      'DTEND:$dtEnd',
      if (customerName.isNotEmpty) 'DESCRIPTION:${_escapeText('Cliente: $customerName')}',
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

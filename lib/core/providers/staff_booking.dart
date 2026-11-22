import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical upper-case status used by the staff portals.
///
/// Firestore holds a mix of spellings: new writes are lower-case (`pending`,
/// `live`, `noshow`), legacy rows are upper-case or camelCase (`CONFIRMED`,
/// `inProgress`, `FINISHED`). The backend slot engine compares
/// case-insensitively (see `backend/functions/slot_engine.py`).
String staffStatus(Object? raw) {
  final status = raw is String && raw.trim().isNotEmpty
      ? raw.trim().toUpperCase()
      : 'PENDING';
  return switch (status) {
    'ACTIVE' => 'PENDING',
    'INPROGRESS' || 'IN_PROGRESS' => 'LIVE',
    'FINISHED' => 'COMPLETED',
    'CANCELED' => 'CANCELLED',
    'NO_SHOW' || 'NO-SHOW' => 'NOSHOW',
    _ => status,
  };
}

/// Statuses that end an appointment and release its slot.
const staffTerminalStatuses = {'COMPLETED', 'CANCELLED', 'NOSHOW'};

/// Projects a booking document onto the display keys the portals consume.
///
/// Prefers the canonical schema (`startAt`, `customerName`, `serviceName`,
/// `servicePrice`) and falls back to legacy keys (`date`/`time`,
/// `clientName`, `service`, `price`). Times render in business-local time
/// (`offsetHours`, from `shops/{shopId}.timezoneOffsetHours`), never in the
/// device's zone.
Map<String, dynamic> staffBooking(Map<String, dynamic> data, int offsetHours) {
  final start = data['startAt'];
  final local = start is Timestamp
      ? start.toDate().toUtc().add(Duration(hours: offsetHours))
      : null;
  return {
    ...data,
    'status': staffStatus(data['status']),
    'date': start ?? data['date'],
    'time': local == null ? data['time'] ?? '—' : _clock(local),
    'clientName': data['customerName'] ?? data['clientName'] ?? '—',
    'clientEmail': data['customerEmail'] ?? data['clientEmail'] ?? '',
    'clientPhone': data['customerPhone'] ?? data['clientPhone'] ?? '',
    'service': data['serviceName'] ?? data['service'] ?? '—',
    'price': data['servicePrice'] ?? data['price'],
  };
}

String _clock(DateTime local) {
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}

String staffStatusLabel(String status, String language) {
  if (language != 'es') return status == 'NOSHOW' ? 'NO-SHOW' : status;
  return switch (status) {
    'PENDING' => 'PENDIENTE',
    'CONFIRMED' => 'CONFIRMADA',
    'LIVE' => 'EN CURSO',
    'COMPLETED' => 'COMPLETADA',
    'CANCELLED' => 'CANCELADA',
    'NOSHOW' => 'NO ASISTIÓ',
    _ => status,
  };
}

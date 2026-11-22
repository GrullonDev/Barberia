import 'package:barberia/features/booking/data/booking_repository.dart';
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
  final start = data['startAt'] is Timestamp
      ? data['startAt'] as Timestamp
      : legacyAppointmentStart(data, offsetHours);
  final local = start?.toDate().toUtc().add(Duration(hours: offsetHours));
  return {
    ...data,
    'status': staffStatus(data['status']),
    // Appointment instant (canonical startAt, or derived for legacy rows).
    'date': start ?? data['date'],
    // Legacy manual rows stored the creation time in `date`; keep it apart.
    'createdAt': data['createdAt'] ?? (start == null ? null : data['date']),
    'time': local == null ? data['time'] ?? '—' : _clock(local),
    'clientName': data['customerName'] ?? data['clientName'] ?? '—',
    'clientEmail': data['customerEmail'] ?? data['clientEmail'] ?? '',
    'clientPhone': data['customerPhone'] ?? data['clientPhone'] ?? '',
    'service': data['serviceName'] ?? data['service'] ?? '—',
    'price': data['servicePrice'] ?? data['price'],
  };
}

/// Orders projected rows by appointment instant (`date`); rows without one
/// sort last. Never sort on `time`: unpadded 12-hour labels put "9:00 AM"
/// after "4:00 PM".
int compareByStart(Map<String, dynamic> a, Map<String, dynamic> b) {
  final x = a['date'], y = b['date'];
  if (x is Timestamp && y is Timestamp) return x.compareTo(y);
  if (x is Timestamp) return -1;
  if (y is Timestamp) return 1;
  return 0;
}

/// The earliest pending/confirmed appointment starting at or after [now],
/// from rows already projected with [staffBooking]. Order-independent: the
/// portals list bookings newest-created first, which says nothing about
/// which appointment comes next.
Map<String, dynamic>? nextUpcomingBooking(
  Iterable<Map<String, dynamic>> projected,
  DateTime now,
) {
  Map<String, dynamic>? next;
  DateTime? nextStart;
  for (final row in projected) {
    if (row['status'] != 'PENDING' && row['status'] != 'CONFIRMED') continue;
    final date = row['date'];
    if (date is! Timestamp) continue;
    final start = date.toDate();
    if (start.isBefore(now)) continue;
    if (nextStart == null || start.isBefore(nextStart)) {
      next = row;
      nextStart = start;
    }
  }
  return next;
}

final _legacyTime = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$');

/// Appointment start for legacy rows without `startAt`: the shop-local day of
/// `date` at the clock time in `time` ("10:00 AM", "14:30"). Mirrors
/// `slot_engine.bookings_to_ranges` so staff see what availability enforces.
/// Returns null when `time` is missing or unparseable.
Timestamp? legacyAppointmentStart(Map<String, dynamic> data, int offsetHours) {
  final date = data['date'];
  final match = _legacyTime.firstMatch(data['time'] as String? ?? '');
  if (date is! Timestamp || match == null) return null;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final meridiem = match.group(3)?.toLowerCase();
  if (minute > 59) return null;
  if (meridiem != null) {
    if (hour < 1 || hour > 12) return null;
    hour = hour % 12 + (meridiem == 'pm' ? 12 : 0);
  } else if (hour > 23) {
    return null;
  }
  final day = bookingCalendarDay(date.toDate(), offsetHours);
  return Timestamp.fromDate(shopLocalInstant(day, hour, minute, offsetHours));
}

String _clock(DateTime local) {
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}

/// Appointments whose `date` falls on the business-local calendar [day]
/// (as produced by [bookingCalendarDay]). Rows without a timestamp are
/// excluded rather than shown on every day.
List<Map<String, dynamic>> staffAppointmentsOnDay(
  Iterable<Map<String, dynamic>> appointments,
  DateTime day,
  int offsetHours,
) {
  return appointments.where((apt) {
    final date = apt['date'];
    return date is Timestamp &&
        bookingCalendarDay(date.toDate(), offsetHours) == day;
  }).toList();
}

/// The instant at [hour]:[minute] shop-local time on the calendar date of
/// [day] (only its year/month/day are used), for a shop at UTC+[offsetHours].
DateTime shopLocalInstant(DateTime day, int hour, int minute, int offsetHours) {
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
    hour,
    minute,
  ).subtract(Duration(hours: offsetHours));
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

// import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/schedule/models/schedule_block.dart';

/// Motor de disponibilidad client-side.
///
/// Espejo ligero de `backend/functions/slot_engine.py`: sirve para pintar
/// el calendario mientras el usuario elige fecha/hora sin golpear la CF
/// en cada rebuild. La autoridad final de disponibilidad sigue siendo el
/// CF `reserveSlot` (que corre su propia transacción anti-colisión).
///
/// Uso típico:
///   final slots = SlotEngine.generateAvailable(
///     date: selectedDate,
///     durationMinutes: service.durationMinutes,
///     slotMinutes: 30,
///     barber: barber,
///     existingBookings: todayBookings,
///     blocks: todayBlocks,
///   );
class SlotEngine {
  /// Status que bloquean el slot. Coincide con `Booking.occupiesSlot` y
  /// con `OCCUPYING_STATUSES` de Python.
  static const Set<BookingStatus> occupyingStatuses = <BookingStatus>{
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.inProgress,
  };

  /// Genera los slots libres del día dado.
  static List<DateTime> generateAvailable({
    required DateTime date,
    required int durationMinutes,
    required int slotMinutes,
    required Barber barber,
    required List<Booking> existingBookings,
    required List<ScheduleBlock> blocks,
  }) {
    // DateTime.weekday: 1=Mon ... 7=Sun. Barber.workingHours usa la misma
    // convención, tanto en memoria como persistido (keys string "1".."7").
    final List<int>? wh = barber.workingHours[date.weekday];
    if (wh == null || wh.length < 2) return <DateTime>[];

    final int openH = wh[0];
    final int closeH = wh[1];

    final DateTime dayOpen = DateTime(date.year, date.month, date.day, openH);
    final DateTime dayClose = DateTime(date.year, date.month, date.day, closeH);

    final List<_Range> bookedRanges = existingBookings
        .where(
          (Booking b) =>
              b.barberId == barber.id && occupyingStatuses.contains(b.status),
        )
        .map((Booking b) => _Range(b.startAt, b.endAt))
        .toList();

    final List<_Range> blockRanges = blocks
        .where((ScheduleBlock b) => b.barberId == barber.id)
        .map((ScheduleBlock b) => _Range(b.startTime, b.endTime))
        .toList();

    final List<DateTime> out = <DateTime>[];
    DateTime cursor = dayOpen;
    final Duration step = Duration(minutes: slotMinutes);
    final Duration duration = Duration(minutes: durationMinutes);

    while (!cursor.add(duration).isAfter(dayClose)) {
      final _Range candidate = _Range(cursor, cursor.add(duration));
      final bool conflicts =
          bookedRanges.any(candidate.overlaps) ||
          blockRanges.any(candidate.overlaps);
      if (!conflicts) out.add(cursor);
      cursor = cursor.add(step);
    }

    return out;
  }

  /// Helper: filtra bookings del día dado (comparación en hora local).
  /// Útil para reducir lo que pasas a `generateAvailable`.
  static List<Booking> bookingsForDay(List<Booking> all, DateTime day) {
    return all.where((Booking b) {
      final DateTime d = b.startAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  /// Helper para filtrar blocks del día.
  static List<ScheduleBlock> blocksForDay(
    List<ScheduleBlock> all,
    DateTime day,
  ) {
    return all.where((ScheduleBlock b) {
      final DateTime d = b.startTime;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  /// Convierte una lista de slots en TimeOfDay strings "HH:mm" para UI.
  static String formatSlot(DateTime slot) {
    final String hh = slot.hour.toString().padLeft(2, '0');
    final String mm = slot.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // Versión Firestore-aware para leer directo de un QuerySnapshot.
  // Útil si quieres evitar materializar Bookings antes de proyectar.
  /*   static List<_Range> _rangesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> d = doc.data();
      final DateTime start = (d['startAt'] as Timestamp?)?.toDate() ??
          (d['date'] as Timestamp?)?.toDate() ??
          DateTime.now();
      final DateTime end = (d['endAt'] as Timestamp?)?.toDate() ??
          start.add(const Duration(minutes: 30));
      return _Range(start, end);
    }).toList();
  } */
}

/// Intervalo medio-abierto [start, end). Privado, no se expone.
class _Range {
  final DateTime start;
  final DateTime end;
  const _Range(this.start, this.end);

  bool overlaps(_Range other) =>
      start.isBefore(other.end) && other.start.isBefore(end);
}

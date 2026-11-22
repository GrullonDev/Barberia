import 'package:barberia/core/providers/staff_booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('staffStatus', () {
    test('normalizes every stored spelling', () {
      const cases = {
        'pending': 'PENDING',
        'ACTIVE': 'PENDING',
        'confirmed': 'CONFIRMED',
        'live': 'LIVE',
        'inProgress': 'LIVE',
        'FINISHED': 'COMPLETED',
        'completed': 'COMPLETED',
        'canceled': 'CANCELLED',
        'cancelled': 'CANCELLED',
        'no_show': 'NOSHOW',
        'noshow': 'NOSHOW',
      };
      cases.forEach(
        (raw, expected) => expect(staffStatus(raw), expected, reason: raw),
      );
      expect(staffStatus(null), 'PENDING');
      expect(staffStatus(''), 'PENDING');
    });

    test('terminal statuses leave the active queue', () {
      for (final s in ['completed', 'FINISHED', 'cancelled', 'noshow']) {
        expect(
          staffTerminalStatuses.contains(staffStatus(s)),
          isTrue,
          reason: s,
        );
      }
      for (final s in ['pending', 'confirmed', 'live']) {
        expect(
          staffTerminalStatuses.contains(staffStatus(s)),
          isFalse,
          reason: s,
        );
      }
    });
  });

  group('staffBooking', () {
    test('canonical booking renders in business-local time', () {
      final view = staffBooking({
        'startAt': Timestamp.fromDate(DateTime.utc(2026, 1, 5, 20, 30)),
        'status': 'confirmed',
        'customerName': 'Ana',
        'customerPhone': '+50255551234',
        'serviceName': 'Fade',
        'servicePrice': 75.0,
        // Legacy mirrors written by reserveSlot must not win.
        'clientName': 'stale',
        'service': 'stale',
        'price': 1,
      }, -6);
      expect(view['time'], '2:30 PM');
      expect(view['status'], 'CONFIRMED');
      expect(view['clientName'], 'Ana');
      expect(view['clientPhone'], '+50255551234');
      expect(view['service'], 'Fade');
      expect(view['price'], 75.0);
      expect(view['date'], isA<Timestamp>());
    });

    test('midnight and noon use 12-hour clock correctly', () {
      String timeAt(int utcHour) =>
          staffBooking({
                'startAt': Timestamp.fromDate(
                  DateTime.utc(2026, 1, 5, utcHour),
                ),
              }, -6)['time']
              as String;
      expect(timeAt(6), '12:00 AM');
      expect(timeAt(18), '12:00 PM');
    });

    test('legacy booking keeps its stored display fields', () {
      final created = Timestamp.fromDate(DateTime.utc(2026, 1, 5, 14));
      final view = staffBooking({
        'date': created,
        'time': '10:00 AM',
        'status': 'CONFIRMED',
        'clientName': 'Luis',
        'service': 'Corte',
        'price': 50,
      }, -6);
      expect(view['time'], '10:00 AM');
      // Appointment = created day (Jan 5 local) at 10:00 shop time.
      expect(
        (view['date'] as Timestamp).toDate().toUtc(),
        DateTime.utc(2026, 1, 5, 16),
      );
      expect(view['createdAt'], created);
      expect(view['clientName'], 'Luis');
      expect(view['service'], 'Corte');
      expect(view['price'], 50);
    });

    test('missing fields fall back to placeholders', () {
      final view = staffBooking({}, -6);
      expect(view['time'], '—');
      expect(view['clientName'], '—');
      expect(view['status'], 'PENDING');
    });
  });

  test('status labels are localized', () {
    expect(staffStatusLabel('NOSHOW', 'es'), 'NO ASISTIÓ');
    expect(staffStatusLabel('LIVE', 'es'), 'EN CURSO');
    expect(staffStatusLabel('NOSHOW', 'en'), 'NO-SHOW');
    expect(staffStatusLabel('CONFIRMED', 'en'), 'CONFIRMED');
  });

  test('schedule shows only appointments on the selected shop-local day', () {
    Map<String, dynamic> at(DateTime utc) => {'date': Timestamp.fromDate(utc)};
    final appointments = [
      at(DateTime.utc(2026, 1, 5, 15)), // Jan 5, 09:00 GT
      at(DateTime.utc(2026, 1, 6, 5, 30)), // Jan 5, 23:30 GT (UTC is Jan 6)
      at(DateTime.utc(2026, 1, 6, 15)), // Jan 6
      {'date': null},
    ];
    expect(
      staffAppointmentsOnDay(appointments, DateTime.utc(2026, 1, 5), -6),
      hasLength(2),
    );
    expect(
      staffAppointmentsOnDay(appointments, DateTime.utc(2026, 1, 6), -6),
      hasLength(1),
    );
  });

  group('legacy manual bookings', () {
    test('appointment differs from a late-night creation timestamp', () {
      // Created Jan 5 at 23:30 GT (Jan 6 05:30 UTC) for 9:00 AM that day.
      final created = Timestamp.fromDate(DateTime.utc(2026, 1, 6, 5, 30));
      final start = legacyAppointmentStart({
        'date': created,
        'time': '09:00 AM',
      }, -6);
      expect(start!.toDate().toUtc(), DateTime.utc(2026, 1, 5, 15));
    });

    test('unparseable or missing time keeps the stored date', () {
      final created = Timestamp.fromDate(DateTime.utc(2026, 1, 5, 14));
      for (final time in [null, 'noon', '13:00 PM', '25:00']) {
        expect(
          legacyAppointmentStart({'date': created, 'time': time}, -6),
          isNull,
          reason: '$time',
        );
        expect(
          staffBooking({'date': created, 'time': time}, -6)['date'],
          created,
        );
      }
    });

    test('canonical startAt always wins', () {
      final startAt = Timestamp.fromDate(DateTime.utc(2026, 2, 1, 18));
      final view = staffBooking({
        'startAt': startAt,
        'date': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
        'time': '09:00 AM',
      }, -6);
      expect(view['date'], startAt);
      expect(view['time'], '12:00 PM');
    });
  });

  test('shopLocalInstant ignores the device timezone', () {
    expect(
      shopLocalInstant(DateTime(2026, 1, 5), 9, 30, -6),
      DateTime.utc(2026, 1, 5, 15, 30),
    );
  });
}

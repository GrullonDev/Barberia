import 'dart:async';

import 'package:barberia/features/booking/data/booking_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_booking_backend.dart';

void main() {
  late FakeBookingBackend backend;
  late BookingRepository repository;

  setUp(() {
    backend = FakeBookingBackend();
    repository = BookingRepository(backend);
    backend.collections['barber_directory'] = [
      {'id': 'b1', 'shopId': 'shop-a', 'name': 'Ana', 'isAvailable': true},
      {'id': 'b2', 'shopId': 'shop-a', 'name': 'Off', 'isAvailable': false},
      {'id': 'b3', 'shopId': 'shop-b', 'name': 'Other'},
      {'id': 'b4', 'shopId': 'shop-a', 'name': 'Legacy'}, // no isAvailable
    ];
    backend.collections['services'] = [
      {'id': 's1', 'shopId': 'shop-a', 'isActive': true, 'price': 50},
      {'id': 's2', 'shopId': 'shop-a', 'isActive': false, 'price': 60},
      {'id': 's3', 'shopId': 'shop-b', 'isActive': true, 'price': 70},
    ];
  });

  group('catalog', () {
    test('barbers are tenant-scoped and exclude unavailable ones', () async {
      final barbers = await repository.fetchBarbers('shop-a');
      expect(barbers.map((b) => b['id']), ['b1', 'b4']);
      expect(backend.queries.single.$1, 'barber_directory');
      expect(backend.queries.single.$2, {'shopId': 'shop-a'});
    });

    test('only active services of the shop are listed', () async {
      final services = await repository.fetchActiveServices('shop-a');
      expect(services.map((s) => s['id']), ['s1']);
      expect(backend.queries.single.$2, {'shopId': 'shop-a', 'isActive': true});
    });

    test('Firestore permission errors become typed BookingExceptions', () {
      backend.queryError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      expect(
        repository.fetchBarbers('shop-a'),
        throwsA(
          isA<BookingException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
    });
  });

  group('availability', () {
    test('sends the business-local date and parses UTC slots', () async {
      backend.handlers['getAvailability'] = (_) => {
        'slots': ['2026-01-05T15:00:00Z', '2026-01-05T15:30:00Z'],
      };
      final slots = await repository.fetchAvailability(
        shopId: 'shop-a',
        barberId: 'b1',
        serviceId: 's1',
        date: DateTime.utc(2026, 1, 5),
      );
      expect(slots, [
        DateTime.utc(2026, 1, 5, 15),
        DateTime.utc(2026, 1, 5, 15, 30),
      ]);
      expect(backend.calls.single.$2, {
        'shopId': 'shop-a',
        'barberId': 'b1',
        'dateLocal': '2026-01-05',
        'serviceId': 's1',
      });
    });

    test('an empty list is a genuine "no slots", not an error', () async {
      backend.handlers['getAvailability'] = (_) => {'slots': <String>[]};
      expect(
        await repository.fetchAvailability(
          shopId: 'shop-a',
          barberId: 'b1',
          serviceId: 's1',
          date: DateTime.utc(2026, 1, 5),
        ),
        isEmpty,
      );
    });

    test('backend failures and malformed responses throw', () {
      backend.handlers['getAvailability'] = (_) =>
          throw FirebaseFunctionsException(message: 'x', code: 'unavailable');
      expect(
        repository.fetchAvailability(
          shopId: 'shop-a',
          barberId: 'b1',
          serviceId: 's1',
          date: DateTime.utc(2026, 1, 5),
        ),
        throwsA(isA<BookingException>()),
      );
      backend.handlers['getAvailability'] = (_) => {'slots': 'nope'};
      expect(
        repository.fetchAvailability(
          shopId: 'shop-a',
          barberId: 'b1',
          serviceId: 's1',
          date: DateTime.utc(2026, 1, 5),
        ),
        throwsA(
          isA<BookingException>().having((e) => e.code, 'code', 'internal'),
        ),
      );
    });
  });

  group('reserveSlot', () {
    Future<ReservationResult> reserve({String? email}) {
      return repository.reserveSlot(
        shopId: 'shop-a',
        barberId: 'b1',
        serviceId: 's1',
        startAt: DateTime.utc(2026, 1, 5, 16),
        customerName: 'Ana',
        customerPhone: '+50255551234',
        customerEmail: email,
        idempotencyKey: 'key-0123456789abcdef',
      );
    }

    test('sends a server-trusted payload (no userId/shop override)', () async {
      backend.handlers['reserveSlot'] = (_) => {
        'bookingId': 'bk1',
        'endAtIso': '2026-01-05T16:30:00Z',
      };
      final result = await reserve();
      expect(result.bookingId, 'bk1');
      expect(result.endAt, DateTime.utc(2026, 1, 5, 16, 30));
      final payload = backend.calls.single.$2;
      expect(payload['startAtIso'], '2026-01-05T16:00:00.000Z');
      expect(payload['idempotencyKey'], 'key-0123456789abcdef');
      expect(payload.containsKey('userId'), isFalse);
      expect(payload.containsKey('customerEmail'), isFalse);
    });

    for (final code in [
      'already-exists',
      'failed-precondition',
      'resource-exhausted',
      'aborted',
      'invalid-argument',
    ]) {
      test('maps backend code $code', () {
        backend.handlers['reserveSlot'] = (_) =>
            throw FirebaseFunctionsException(message: 'm', code: code);
        expect(
          reserve(),
          throwsA(isA<BookingException>().having((e) => e.code, 'code', code)),
        );
      });
    }

    test('network timeouts map to unavailable', () {
      backend.handlers['reserveSlot'] = (_) => throw TimeoutException('slow');
      expect(
        reserve(),
        throwsA(
          isA<BookingException>().having((e) => e.code, 'code', 'unavailable'),
        ),
      );
    });
  });

  group('createScheduleBlock', () {
    test('sends UTC instants and returns the block id', () async {
      backend.handlers['createScheduleBlock'] = (_) => {'blockId': 'blk1'};
      final id = await repository.createScheduleBlock(
        barberId: 'b1',
        start: DateTime.utc(2026, 1, 5, 18),
        end: DateTime.utc(2026, 1, 5, 19),
        reason: 'Almuerzo',
      );
      expect(id, 'blk1');
      expect(backend.calls.single.$2, {
        'barberId': 'b1',
        'startIso': '2026-01-05T18:00:00.000Z',
        'endIso': '2026-01-05T19:00:00.000Z',
        'reason': 'Almuerzo',
      });
    });

    test('an overlapping booking surfaces as failed-precondition', () {
      backend.handlers['createScheduleBlock'] = (_) =>
          throw FirebaseFunctionsException(
            message: 'busy',
            code: 'failed-precondition',
          );
      expect(
        repository.createScheduleBlock(
          barberId: 'b1',
          start: DateTime.utc(2026, 1, 5, 18),
          end: DateTime.utc(2026, 1, 5, 19),
          reason: 'x',
        ),
        throwsA(
          isA<BookingException>().having(
            (e) => e.code,
            'code',
            'failed-precondition',
          ),
        ),
      );
    });
  });

  group('helpers', () {
    test('bookingCalendarDay uses the business offset, not the device', () {
      // 03:00 UTC on Jan 6 is still Jan 5 in Guatemala (UTC-6).
      expect(
        bookingCalendarDay(DateTime.utc(2026, 1, 6, 3), -6),
        DateTime.utc(2026, 1, 5),
      );
      expect(
        bookingCalendarDay(DateTime.utc(2026, 1, 6, 7), -6),
        DateTime.utc(2026, 1, 6),
      );
    });

    test('formatBookingDate pads fields', () {
      expect(formatBookingDate(DateTime.utc(2026, 3, 7)), '2026-03-07');
    });

    test('bookingServicePrice prefers cents and tolerates missing price', () {
      expect(bookingServicePrice({'priceCents': 4550, 'price': 1}), 45.5);
      expect(bookingServicePrice({'price': 50}), 50);
      expect(bookingServicePrice({}), 0);
    });
  });
}

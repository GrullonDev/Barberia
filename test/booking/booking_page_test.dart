import 'dart:async';

import 'package:barberia/core/l10n/app_localizations.dart';
import 'package:barberia/core/providers/config_provider.dart';
import 'package:barberia/features/booking/data/booking_repository.dart';
import 'package:barberia/features/booking/presentation/pages/booking_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
// Same library as BookingPage (material_ui has distinct localization types).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fake_booking_backend.dart';

final es = AppLocalizations('es');

FakeBookingBackend seededBackend() {
  final backend = FakeBookingBackend();
  backend.collections['barber_directory'] = [
    {'id': 'b1', 'shopId': 'shop-a', 'name': 'Ana Barber', 'isAvailable': true},
    {'id': 'b9', 'shopId': 'shop-b', 'name': 'Other Shop Barber'},
  ];
  backend.collections['services'] = [
    {
      'id': 's1',
      'shopId': 'shop-a',
      'isActive': true,
      'name': 'Fade',
      'price': 75,
      'durationMinutes': 30,
    },
    {
      'id': 's9',
      'shopId': 'shop-b',
      'isActive': true,
      'name': 'Foreign Service',
      'price': 1,
    },
  ];
  // 15:00Z is 09:00 AM in the shop's UTC-6 business time.
  backend.handlers['getAvailability'] = (data) => {
    'slots': ['2030-01-07T15:00:00Z'],
  };
  return backend;
}

Future<void> pumpPage(WidgetTester tester, FakeBookingBackend backend) async {
  tester.view.physicalSize = const Size(1400, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const BookingPage())],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentShopIdProvider.overrideWithValue('shop-a'),
        appConfigProvider.overrideWithValue(AppConfigState.defaultConfig()),
        bookingRepositoryProvider.overrideWithValue(BookingRepository(backend)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Barber → service → first date → 09:00 slot → customer form → summary.
Future<void> fillUntilSummary(WidgetTester tester) async {
  await tapVisible(tester, find.text('Ana Barber'));
  await tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, es.get('continue_btn')),
  );
  await tapVisible(tester, find.text('Fade'));
  final dateChip = find.byWidgetPredicate(
    (w) => w is AnimatedContainer && w.constraints?.maxWidth == 70,
  );
  await tapVisible(tester, dateChip.first);
  await tapVisible(tester, find.text('09:00 AM'));
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Ana Cliente');
  await tester.enterText(fields.at(2), '55551234');
  await tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, es.get('continue_btn')),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('lists only the selected shop\'s barbers and services', (
    tester,
  ) async {
    final backend = seededBackend();
    await pumpPage(tester, backend);
    expect(find.text('Ana Barber'), findsOneWidget);
    expect(find.text('Other Shop Barber'), findsNothing);
    await tapVisible(tester, find.text('Ana Barber'));
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.get('continue_btn')),
    );
    expect(find.text('Fade'), findsOneWidget);
    expect(find.text('Foreign Service'), findsNothing);
  });

  testWidgets('catalog failure shows a retry that recovers', (tester) async {
    final backend = seededBackend()..queryError = StateError('offline');
    await pumpPage(tester, backend);
    expect(find.text(es.get('barbers_load_error')), findsOneWidget);
    backend.queryError = null;
    await tapVisible(tester, find.text(es.get('retry')));
    expect(find.text('Ana Barber'), findsOneWidget);
  });

  testWidgets('availability failure is distinct from an empty day', (
    tester,
  ) async {
    final backend = seededBackend();
    backend.handlers['getAvailability'] = (_) =>
        throw FirebaseFunctionsException(message: 'down', code: 'unavailable');
    await pumpPage(tester, backend);
    await tapVisible(tester, find.text('Ana Barber'));
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.get('continue_btn')),
    );
    await tapVisible(tester, find.text('Fade'));
    final dateChip = find.byWidgetPredicate(
      (w) => w is AnimatedContainer && w.constraints?.maxWidth == 70,
    );
    await tapVisible(tester, dateChip.first);
    expect(find.text(es.get('slots_load_error')), findsOneWidget);

    backend.handlers['getAvailability'] = (_) => {'slots': <String>[]};
    await tapVisible(tester, find.text(es.get('retry')));
    expect(find.text(es.get('slots_load_error')), findsNothing);
    expect(find.text('09:00 AM'), findsNothing);
  });

  testWidgets('invalid customer data blocks the summary step', (tester) async {
    final backend = seededBackend();
    await pumpPage(tester, backend);
    await tapVisible(tester, find.text('Ana Barber'));
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.get('continue_btn')),
    );
    await tapVisible(tester, find.text('Fade'));
    final dateChip = find.byWidgetPredicate(
      (w) => w is AnimatedContainer && w.constraints?.maxWidth == 70,
    );
    await tapVisible(tester, dateChip.first);
    await tapVisible(tester, find.text('09:00 AM'));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'A'); // too short
    await tester.enterText(fields.at(1), 'not-an-email');
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.get('continue_btn')),
    );
    expect(find.text(es.get('booking_name_length')), findsOneWidget);
    expect(find.text(es.get('valid_email')), findsOneWidget);
    expect(find.text(es.get('confirm_booking')), findsNothing);
  });

  testWidgets('submits once, shows the confirmation reference', (tester) async {
    final backend = seededBackend();
    final pending = Completer<Map<String, dynamic>>();
    backend.handlers['reserveSlot'] = (_) => pending.future;
    await pumpPage(tester, backend);
    await fillUntilSummary(tester);

    final confirm = find.widgetWithText(
      ElevatedButton,
      es.get('confirm_booking'),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.tap(confirm); // double tap while the request is in flight
    await tester.pump();
    pending.complete({
      'bookingId': 'BK-123',
      'endAtIso': '2030-01-07T15:30:00Z',
    });
    await tester.pumpAndSettle();

    final reserveCalls = backend.calls.where((c) => c.$1 == 'reserveSlot');
    expect(reserveCalls, hasLength(1));
    final payload = reserveCalls.single.$2;
    expect(payload['shopId'], 'shop-a');
    expect(payload['barberId'], 'b1');
    expect(payload['serviceId'], 's1');
    expect(payload['startAtIso'], '2030-01-07T15:00:00.000Z');
    expect(payload['customerPhone'], '+50255551234');
    expect(payload.containsKey('customerEmail'), isFalse);
    expect(find.text('BK-123'), findsOneWidget);
  });

  testWidgets('a retried request reuses the idempotency key', (tester) async {
    final backend = seededBackend();
    var attempts = 0;
    backend.handlers['reserveSlot'] = (_) {
      if (attempts++ == 0) {
        throw FirebaseFunctionsException(message: 'busy', code: 'aborted');
      }
      return {'bookingId': 'BK-2', 'endAtIso': '2030-01-07T15:30:00Z'};
    };
    await pumpPage(tester, backend);
    await fillUntilSummary(tester);
    final confirm = find.widgetWithText(
      ElevatedButton,
      es.get('confirm_booking'),
    );
    await tapVisible(tester, confirm);
    expect(find.text(es.get('booking_busy_retry')), findsOneWidget);
    await tapVisible(tester, confirm);

    final keys = backend.calls
        .where((c) => c.$1 == 'reserveSlot')
        .map((c) => c.$2['idempotencyKey'])
        .toList();
    expect(keys, hasLength(2));
    expect(keys[0], keys[1]);
    expect(find.text('BK-2'), findsOneWidget);
  });

  testWidgets('a taken slot returns to the agenda and refreshes', (
    tester,
  ) async {
    final backend = seededBackend();
    backend.handlers['reserveSlot'] = (_) => throw FirebaseFunctionsException(
      message: 'taken',
      code: 'already-exists',
    );
    await pumpPage(tester, backend);
    await fillUntilSummary(tester);
    final before = backend.calls.where((c) => c.$1 == 'getAvailability').length;
    await tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, es.get('confirm_booking')),
    );
    expect(find.text(es.get('confirm_booking')), findsNothing);
    expect(
      backend.calls.where((c) => c.$1 == 'getAvailability').length,
      before + 1,
    );
  });
}

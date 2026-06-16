import 'package:barberia/features/barber/widgets/barber_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Barber top bar renders brand and avatar fallback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BarberTopBar(name: 'Julian Vane', compact: true),
        ),
      ),
    );

    expect(find.text('THE\nGENTLEMAN'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
  });
}

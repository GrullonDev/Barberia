import 'package:flutter_test/flutter_test.dart';
import 'package:barberia/features/booking/models/service.dart';

void main() {
  group('Service category filtering', () {
    const List<Service> services = <Service>[
      Service(id: '1', name: 'Corte', durationMinutes: 30, price: 10, category: ServiceCategory.hair),
      Service(id: '2', name: 'Barba', durationMinutes: 20, price: 8, category: ServiceCategory.beard),
      Service(id: '3', name: 'Combo', durationMinutes: 45, price: 15, category: ServiceCategory.combo),
    ];

    test('Filter hair', () {
      final List<Service> filtered = services.where((s) => s.category == ServiceCategory.hair).toList();
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Corte');
    });

    test('Filter beard', () {
      final List<Service> filtered = services.where((s) => s.category == ServiceCategory.beard).toList();
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Barba');
    });

    test('Filter combo', () {
      final List<Service> filtered = services.where((s) => s.category == ServiceCategory.combo).toList();
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Combo');
    });

    test('All (no filter) returns all', () {
      expect(services.length, 3);
    });
  });
}

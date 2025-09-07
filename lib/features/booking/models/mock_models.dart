import 'dart:math';

/// Modelo simplificado de servicio para mocks UI previos a backend.
class MockService {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? description;
  const MockService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.description,
  });
}

enum MockSlotState { available, occupied, hold, disabled }

class MockSlot {
  final DateTime start;
  final DateTime end;
  final MockSlotState state;
  const MockSlot({required this.start, required this.end, required this.state});
}

class MockAppointment {
  final String id;
  final MockService service;
  final DateTime start;
  DateTime get end => start.add(Duration(minutes: service.durationMinutes));
  const MockAppointment({
    required this.id,
    required this.service,
    required this.start,
  });
}

/// Genera slots mezclando estados disponibles y ocupados para una fecha.
List<MockSlot> generateSlotsFor(DateTime day) {
  final DateTime base = DateTime(day.year, day.month, day.day, 8);
  final Random rnd = Random(day.millisecondsSinceEpoch ~/ 86400000);
  final List<MockSlot> out = <MockSlot>[];
  DateTime cursor = base;
  while (cursor.hour < 19) {
    final int step = cursor.hour >= 13 ? 45 : 30;
    final MockSlotState state;
    final int roll = rnd.nextInt(100);
    if (roll < 10) {
      state = MockSlotState.hold;
    } else if (roll < 25) {
      state = MockSlotState.occupied;
    } else {
      state = MockSlotState.available;
    }
    final DateTime end = cursor.add(Duration(minutes: step));
    out.add(MockSlot(start: cursor, end: end, state: state));
    cursor = end;
  }
  return out;
}

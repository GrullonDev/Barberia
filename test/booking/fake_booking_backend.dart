import 'dart:async';

import 'package:barberia/features/booking/data/booking_repository.dart';

/// In-memory [BookingBackend]: records calls and replays scripted responses.
class FakeBookingBackend implements BookingBackend {
  final calls = <(String, Map<String, dynamic>)>[];
  final queries = <(String, Map<String, Object>)>[];

  /// Documents per collection; [query] applies the equality filters.
  final collections = <String, List<Map<String, dynamic>>>{};

  /// Handler per callable name. Throw from it to simulate an error.
  final handlers =
      <String, FutureOr<Map<String, dynamic>> Function(Map<String, dynamic>)>{};

  Object? queryError;

  @override
  Future<Map<String, dynamic>> call(
    String function,
    Map<String, dynamic> data,
  ) async {
    calls.add((function, data));
    final handler = handlers[function];
    if (handler == null) throw StateError('no handler for $function');
    return handler(data);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String collection,
    Map<String, Object> equals,
  ) async {
    queries.add((collection, equals));
    if (queryError != null) throw queryError!;
    return (collections[collection] ?? [])
        .where((doc) => equals.entries.every((e) => doc[e.key] == e.value))
        .map(Map<String, dynamic>.from)
        .toList();
  }
}

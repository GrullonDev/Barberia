import 'service.dart';

class Booking {
  final String id;
  final Service service;
  final DateTime dateTime;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? notes;

  const Booking({
    required this.id,
    required this.service,
    required this.dateTime,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.notes,
  });
}

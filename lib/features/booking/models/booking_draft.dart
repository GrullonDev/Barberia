import 'service.dart';

class BookingDraft {
  final Service? service;
  final DateTime? date;
  final DateTime? dateTime; // date + hour combined
  final String? name;
  final String? phone;
  final String? email;
  final String? notes;

  const BookingDraft({
    this.service,
    this.date,
    this.dateTime,
    this.name,
    this.phone,
    this.email,
    this.notes,
  });

  BookingDraft copyWith({
    Service? service,
    DateTime? date,
    DateTime? dateTime,
    String? name,
    String? phone,
    String? email,
    String? notes,
  }) => BookingDraft(
    service: service ?? this.service,
    date: date ?? this.date,
    dateTime: dateTime ?? this.dateTime,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    notes: notes ?? this.notes,
  );

  static BookingDraft empty() => const BookingDraft();
}

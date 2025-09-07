class Service {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? extendedDescription; // microcopy detallada

  const Service({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.extendedDescription,
  });
}

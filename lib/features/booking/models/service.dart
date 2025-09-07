class Service {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? extendedDescription; // microcopy detallada
  final ServiceCategory category;

  const Service({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.category,
    this.extendedDescription,
  });
}

enum ServiceCategory { hair, beard, combo }

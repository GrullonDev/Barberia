class Service {
  final int? id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? extendedDescription; // microcopy detallada
  final ServiceCategory category;

  const Service({
    this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.category,
    this.extendedDescription,
  });

  Service copyWith({
    int? id,
    String? name,
    int? durationMinutes,
    double? price,
    ServiceCategory? category,
    String? extendedDescription,
  }) =>
      Service(
        id: id ?? this.id,
        name: name ?? this.name,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        price: price ?? this.price,
        category: category ?? this.category,
        extendedDescription: extendedDescription ?? this.extendedDescription,
      );

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as int?,
        name: json['name'] as String,
        durationMinutes: json['durationMinutes'] as int,
        price: json['price'] as double,
        category: ServiceCategory.values.firstWhere(
            (e) => e.toString() == 'ServiceCategory.${json['category']}'),
        extendedDescription: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'durationMinutes': durationMinutes,
        'price': price,
        'category': category.toString().split('.').last,
        'description': extendedDescription,
      };
}

enum ServiceCategory { hair, beard, combo, facial }

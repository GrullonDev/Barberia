class Service {
  final int? id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? extendedDescription;
  final ServiceCategory category;
  final bool isActive;

  const Service({
    this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.category,
    this.extendedDescription,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'price': price,
      'extendedDescription': extendedDescription,
      'category': category.name,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as String,
      name: map['name'] as String,
      durationMinutes: map['durationMinutes'] as int,
      price: (map['price'] as num).toDouble(),
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String),
        orElse: () => ServiceCategory.hair,
      ),
      extendedDescription: map['extendedDescription'] as String?,
      isActive: (map['isActive'] as int) == 1,
    );
  }
}

enum ServiceCategory { hair, beard, combo }

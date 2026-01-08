class Service {
  final int? id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? extendedDescription;
  final ServiceCategory category;
  final bool isActive;

  const Service({
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.category,
    this.id,
    this.extendedDescription,
    this.isActive = true,
  });

  Service copyWith({
    int? id,
    String? name,
    int? durationMinutes,
    double? price,
    ServiceCategory? category,
    String? extendedDescription,
    bool? isActive,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      category: category ?? this.category,
      extendedDescription: extendedDescription ?? this.extendedDescription,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
      id: map['id'] is String
          ? int.tryParse(map['id'] as String)
          : map['id'] as int?,
      name: map['name'] as String? ?? '',
      durationMinutes: map['durationMinutes'] is String
          ? (int.tryParse(map['durationMinutes'] as String) ?? 0)
          : (map['durationMinutes'] as int? ?? 0),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: ServiceCategory.values.firstWhere(
        (ServiceCategory e) => e.name == (map['category'] as String?),
        orElse: () => ServiceCategory.hair,
      ),
      extendedDescription: map['extendedDescription'] as String?,
      isActive: map['isActive'] is int
          ? (map['isActive'] as int) == 1
          : (map['isActive'] as bool? ?? true),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Service.fromJson(Map<String, dynamic> json) => Service.fromMap(json);
}

enum ServiceCategory { hair, beard, combo }

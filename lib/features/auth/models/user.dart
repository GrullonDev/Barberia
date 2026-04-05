import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, barber, client }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
    };
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] as String?),
        orElse: () => UserRole.client,
      ),
      phone: data['phone'] as String?,
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String? ?? '',
      name: (map['name'] ?? map['username']) as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] as String?),
        orElse: () => UserRole.client,
      ),
      phone: map['phone'] as String?,
    );
  }
}

enum UserRole { admin, client }

class User {
  final String id;
  final String name;
  final String email;
  final String password; // Stored locally for this demo MVP
  final UserRole role;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role.name,
      'phone': phone,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] as String),
        orElse: () => UserRole.client,
      ),
      phone: map['phone'] as String?,
    );
  }
}

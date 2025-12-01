enum UserRole { admin, client }

class User {
  final int? id;
  final String username;
  final String password;
  final UserRole role;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  User copyWith({
    int? id,
    String? username,
    String? password,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String,
      password: json['password'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.client,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.toString().split('.').last,
    };
  }
}

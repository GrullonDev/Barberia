import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/common/utils/phone_normalizer.dart';

/// Roles de usuario en el sistema.
/// - [admin]  → dueño; CRUD servicios/barberos/config.
/// - [barber] → empleado; agenda propia + citas asignadas.
/// - [client] → cliente final (web/mobile) con cuenta.
///
/// Nota: los invitados (guest) NO se modelan con [UserRole]. En web usamos
/// Firebase Anonymous Auth para tener un uid transparente; en móvil pueden
/// llegar a registrarse con email o teléfono. La reputación/hsitorial se une
/// por [phoneNormalized] (no por uid) para que el historial persista incluso
/// si el cliente migra de anónimo a cuenta con contraseña.
enum UserRole { admin, barber, client }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;

  /// Versión canónica E.164 (+502XXXXXXXX) del teléfono.
  /// Clave de join con la colección `reputation/`.
  final String? phoneNormalized;

  /// URL opcional de avatar (Google sign-in lo popula; en mobile queda null).
  final String? photoUrl;

  /// True si este uid corresponde a una sesión de Firebase Anonymous Auth
  /// (solo usada en web para que el cliente pueda navegar sin friction).
  final bool isAnonymous;

  /// Fecha de alta. Sirve para onboarding, analítica y retención.
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.phoneNormalized,
    this.photoUrl,
    this.isAnonymous = false,
    this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? phoneNormalized,
    String? photoUrl,
    bool? isAnonymous,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      phoneNormalized: phoneNormalized ?? this.phoneNormalized,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
      'phoneNormalized': phoneNormalized ?? normalizePhone(phone),
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (UserRole e) => e.name == (data['role'] as String?),
        orElse: () => UserRole.client,
      ),
      phone: data['phone'] as String?,
      phoneNormalized:
          data['phoneNormalized'] as String? ??
          normalizePhone(data['phone'] as String?),
      photoUrl: data['photoUrl'] as String?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String? ?? '',
      name: (map['name'] ?? map['username']) as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (UserRole e) => e.name == (map['role'] as String?),
        orElse: () => UserRole.client,
      ),
      phone: map['phone'] as String?,
      phoneNormalized:
          map['phoneNormalized'] as String? ??
          normalizePhone(map['phone'] as String?),
      photoUrl: map['photoUrl'] as String?,
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }
}

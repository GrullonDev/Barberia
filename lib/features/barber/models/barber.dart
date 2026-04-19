import 'package:cloud_firestore/cloud_firestore.dart';

/// Barbero como entidad pública de negocio.
///
/// Vive en la colección `barbers/{uid}` con datos públicos que el cliente
/// puede leer para elegirlo (nombre, foto, especialidad, horario laboral).
/// El documento `users/{uid}` del mismo id conserva datos privados (email,
/// teléfono, rol). Ambos comparten id para simplificar los joins.
///
/// Cuando un admin promueve a un usuario a `role: barber`, debe además
/// crear su doc en `barbers/{uid}`. Esto se hace desde el panel admin
/// (pantalla manage_barbers_page) o vía Cloud Function `promoteBarber`.
class Barber {
  final String id; // = users/{uid}
  final String name;
  final String? specialty;
  final String? photoUrl;
  final bool isAvailable;

  /// Horario laboral del barbero por día de la semana (1=lunes ... 7=domingo).
  /// `null` en un día = no trabaja ese día. `[startHour, endHour]` en formato
  /// 24h (p.ej. `[9, 19]` = 09:00 a 19:00).
  final Map<int, List<int>?> workingHours;

  const Barber({
    required this.id,
    required this.name,
    this.specialty,
    this.photoUrl,
    this.isAvailable = true,
    this.workingHours = const <int, List<int>?>{},
  });

  Barber copyWith({
    String? name,
    String? specialty,
    String? photoUrl,
    bool? isAvailable,
    Map<int, List<int>?>? workingHours,
  }) => Barber(
        id: id,
        name: name ?? this.name,
        specialty: specialty ?? this.specialty,
        photoUrl: photoUrl ?? this.photoUrl,
        isAvailable: isAvailable ?? this.isAvailable,
        workingHours: workingHours ?? this.workingHours,
      );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'name': name,
        'specialty': specialty,
        'photoUrl': photoUrl,
        'isAvailable': isAvailable,
        // Firestore no soporta keys numéricas; persistimos como string
        'workingHours': workingHours.map(
          (int day, List<int>? range) => MapEntry<String, List<int>?>(
            day.toString(),
            range,
          ),
        ),
      };

  factory Barber.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final Map<String, dynamic> rawHours =
        (data['workingHours'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
    final Map<int, List<int>?> hours = <int, List<int>?>{};
    rawHours.forEach((String key, dynamic value) {
      final int? day = int.tryParse(key);
      if (day == null) return;
      if (value == null) {
        hours[day] = null;
      } else if (value is List) {
        hours[day] = value.whereType<num>().map((num n) => n.toInt()).toList();
      }
    });
    return Barber(
      id: doc.id,
      name: data['name'] as String? ?? '',
      specialty: data['specialty'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
      workingHours: hours,
    );
  }

  /// Horario por defecto para un barbero recién creado (lunes–sábado 9–19).
  static Map<int, List<int>?> defaultWorkingHours() => <int, List<int>?>{
        1: <int>[9, 19], // lunes
        2: <int>[9, 19],
        3: <int>[9, 19],
        4: <int>[9, 19],
        5: <int>[9, 19],
        6: <int>[9, 19], // sábado
        7: null,         // domingo cerrado por defecto
      };
}

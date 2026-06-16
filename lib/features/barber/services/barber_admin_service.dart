import 'package:cloud_functions/cloud_functions.dart';

/// Servicio que encapsula las Cloud Functions de administración de barberos:
/// `inviteBarber` y `removeBarber`.
///
/// Ambas funciones requieren que el usuario autenticado tenga rol `admin`.
class BarberAdminService {
  BarberAdminService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Invita a un nuevo barbero por email.
  ///
  /// Crea la cuenta de Firebase Auth, los documentos Firestore y envía el
  /// correo con el enlace de activación. Devuelve el `barberId` asignado.
  Future<String> inviteBarber({
    required String name,
    required String email,
    String? specialty,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('inviteBarber');
    try {
      final HttpsCallableResult<dynamic> result = await callable
          .call<dynamic>(<String, dynamic>{
            'name': name,
            'email': email,
            if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
          });
      final Map<Object?, Object?> data =
          result.data as Map<Object?, Object?>? ?? <Object?, Object?>{};
      return data['barberId'] as String? ?? '';
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Error al invitar barbero');
    }
  }

  /// Elimina a un barbero: borra sus documentos Firestore y su cuenta Auth,
  /// revocando por completo su acceso a la aplicación.
  Future<void> removeBarber(String barberId) async {
    final HttpsCallable callable = _functions.httpsCallable('removeBarber');
    try {
      await callable.call<dynamic>(<String, dynamic>{'barberId': barberId});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Error al eliminar barbero');
    }
  }
}

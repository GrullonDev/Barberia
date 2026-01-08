import 'package:flutter/foundation.dart';
import 'package:barberia/core/database/database_helper.dart';
import 'package:barberia/features/auth/models/user.dart';

/// Script para listar todos los usuarios en la base de datos
/// Ejecutar desde main.dart temporalmente
Future<void> listAllUsers() async {
  try {
    final DatabaseHelper dbHelper = DatabaseHelper.instance;
    final List<Map<String, dynamic>> usersData = await dbHelper.getAllUsers();

    if (usersData.isEmpty) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('   NO HAY USUARIOS EN LA BASE DE DATOS');
      debugPrint('═══════════════════════════════════════');
      return;
    }

    debugPrint('\n═══════════════════════════════════════');
    debugPrint('   LISTA DE USUARIOS (${usersData.length} total)');
    debugPrint('═══════════════════════════════════════\n');

    for (int i = 0; i < usersData.length; i++) {
      final Map<String, dynamic> userData = usersData[i];
      final User user = User.fromMap(userData);

      debugPrint('👤 Usuario #${i + 1}');
      debugPrint('   ID: ${user.id}');
      debugPrint('   Nombre: ${user.name}');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Rol: ${user.role.name.toUpperCase()}');
      debugPrint('   Teléfono: ${user.phone ?? "No especificado"}');
      debugPrint('   Password: ${user.password}'); // Solo para debug
      debugPrint('───────────────────────────────────────\n');
    }

    debugPrint('═══════════════════════════════════════');
    debugPrint('   FIN DE LA LISTA');
    debugPrint('═══════════════════════════════════════\n');
  } catch (e, stackTrace) {
    debugPrint('❌ Error al listar usuarios: $e');
    debugPrint('StackTrace: $stackTrace');
  }
}

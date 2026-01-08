import 'package:flutter/foundation.dart';
import 'package:barberia/core/database/database_helper.dart';
import 'package:barberia/features/auth/models/user.dart';

/// Script para listar solo usuarios CLIENTES
Future<void> listClientUsers() async {
  try {
    final DatabaseHelper dbHelper = DatabaseHelper.instance;
    final List<Map<String, dynamic>> usersData = await dbHelper.getUsersByRole(
      'client',
    );

    if (usersData.isEmpty) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('   NO HAY CLIENTES REGISTRADOS');
      debugPrint('═══════════════════════════════════════');
      return;
    }

    debugPrint('\n═══════════════════════════════════════');
    debugPrint('   📋 CLIENTES REGISTRADOS (${usersData.length} total)');
    debugPrint('═══════════════════════════════════════\n');

    for (int i = 0; i < usersData.length; i++) {
      final Map<String, dynamic> userData = usersData[i];
      final User user = User.fromMap(userData);

      debugPrint('👤 Cliente #${i + 1}');
      debugPrint('   ID: ${user.id}');
      debugPrint('   Nombre: ${user.name}');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Teléfono: ${user.phone ?? "No especificado"}');
      debugPrint('   Password: ${user.password}');
      debugPrint('───────────────────────────────────────\n');
    }

    debugPrint('═══════════════════════════════════════');
    debugPrint('   Total de clientes: ${usersData.length}');
    debugPrint('═══════════════════════════════════════\n');
  } catch (e, stackTrace) {
    debugPrint('❌ Error al listar clientes: $e');
    debugPrint('StackTrace: $stackTrace');
  }
}

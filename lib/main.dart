import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/app.dart';
import 'package:barberia/core/database/database_helper.dart';
import 'package:barberia/common/utils/list_clients_script.dart';
import 'package:barberia/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize Notifications
  await NotificationService().init();
  await NotificationService().requestPermissions();

  // --- TAREA TEMPORAL: VERIFICAR USUARIOS ---
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;
  final users = await db.query('users');
  if (kDebugMode) {
    print('--- USUARIOS REGISTRADOS EN BD ---');
    for (var u in users) {
      print(
        'ID: ${u['id']}, Email: ${u['email']}, Nombre: ${u['name']}, Rol: ${u['role']}, Password: ${u['password']}',
      );
    }
    if (users.isEmpty) {
      print('No hay usuarios registrados.');
    }
    print('----------------------------------');
  }
  // --- FIN DE LA TAREA TEMPORAL ---

  // --- LISTAR USUARIOS CLIENTES ---
  // Este script lista solo los usuarios con rol 'client'
  // Ejecuta la app y revisa la consola de debug
  await listClientUsers();
  // --- FIN LISTAR CLIENTES ---

  runApp(const ProviderScope(child: MyApp()));
}

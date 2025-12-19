import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/app.dart';
import 'package:barberia/core/database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // --- TAREA TEMPORAL: ACTUALIZAR ROL DE USUARIO ---
  // Reemplaza 'correo@ejemplo.com' con el email del usuario a modificar.
  // Después de ejecutar la app UNA VEZ, BORRA este bloque de código.
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  const String emailToUpdate = 'jorgegrullon369@gmail.com';
  final int rowsAffected = await dbHelper.updateUserRole(
    emailToUpdate,
    'admin',
  );
  if (kDebugMode) {
    print('--- Actualización de Rol ---');
    if (rowsAffected > 0) {
      print('Éxito: Se actualizó el rol para el usuario $emailToUpdate.');
    } else {
      print(
        'Aviso: No se encontró ningún usuario con el email $emailToUpdate.',
      );
    }
    print('--- Fin del script ---');
  }
  // --- FIN DE LA TAREA TEMPORAL ---

  runApp(const ProviderScope(child: MyApp()));
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:barberia/features/auth/models/user.dart';

/// Script de debug: lista todos los usuarios en Firestore.
Future<void> listAllUsers() async {
  if (!kDebugMode) {
    return;
  }
  try {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    if (snapshot.docs.isEmpty) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('   NO HAY USUARIOS EN FIRESTORE');
      debugPrint('═══════════════════════════════════════');
      return;
    }
    debugPrint('\n═══════════════════════════════════════');
    debugPrint('   LISTA DE USUARIOS (${snapshot.docs.length} total)');
    debugPrint('═══════════════════════════════════════\n');
    for (int i = 0; i < snapshot.docs.length; i++) {
      final user = User.fromFirestore(snapshot.docs[i]);
      debugPrint('Usuario #${i + 1}');
      debugPrint('   ID: ${user.id}');
      debugPrint('   Nombre: ${user.name}');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Rol: ${user.role.name.toUpperCase()}');
      debugPrint('   Teléfono: ${user.phone ?? "No especificado"}');
      debugPrint('───────────────────────────────────────\n');
    }
    debugPrint('═══════════════════════════════════════\n');
  } catch (e) {
    debugPrint('Error al listar usuarios: $e');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:barberia/features/auth/models/user.dart';

/// Script de debug: lista solo los usuarios con rol cliente en Firestore.
Future<void> listClientUsers() async {
  if (!kDebugMode) {
    return;
  }
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'client')
        .get();
    if (snapshot.docs.isEmpty) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('   NO HAY CLIENTES REGISTRADOS');
      debugPrint('═══════════════════════════════════════');
      return;
    }
    debugPrint('\n═══════════════════════════════════════');
    debugPrint('   CLIENTES REGISTRADOS (${snapshot.docs.length} total)');
    debugPrint('═══════════════════════════════════════\n');
    for (int i = 0; i < snapshot.docs.length; i++) {
      final user = User.fromFirestore(snapshot.docs[i]);
      debugPrint('Cliente #${i + 1}');
      debugPrint('   ID: ${user.id}');
      debugPrint('   Nombre: ${user.name}');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Teléfono: ${user.phone ?? "No especificado"}');
      debugPrint('───────────────────────────────────────\n');
    }
    debugPrint('═══════════════════════════════════════\n');
  } catch (e) {
    debugPrint('Error al listar clientes: $e');
  }
}

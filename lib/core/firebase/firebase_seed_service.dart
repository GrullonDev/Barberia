import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seeds initial data into Firestore if collections are empty.
/// Run once on app startup.
class FirebaseSeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedIfNeeded() async {
    await _seedServices();
  }

  Future<void> _seedServices() async {
    final snapshot = await _db.collection('services').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[Seed] Services already exist, skipping.');
      }
      return;
    }

    final List<Map<String, dynamic>> services = [
      {
        'name': 'Corte Clásico',
        'price': 100.0,
        'durationMinutes': 45,
        'category': 'hair',
        'extendedDescription':
            'Corte de cabello tradicional con tijera y máquina, lavado y peinado.',
        'isActive': true,
      },
      {
        'name': 'Afeitado de Barba',
        'price': 80.0,
        'durationMinutes': 30,
        'category': 'beard',
        'extendedDescription':
            'Afeitado completo con toalla caliente, aceites esenciales y masaje facial.',
        'isActive': true,
      },
      {
        'name': 'Combo Completo',
        'price': 160.0,
        'durationMinutes': 75,
        'category': 'combo',
        'extendedDescription':
            'La experiencia completa: Corte de cabello y afeitado de barba premium.',
        'isActive': true,
      },
      {
        'name': 'Corte Degradado',
        'price': 120.0,
        'durationMinutes': 60,
        'category': 'hair',
        'extendedDescription':
            'Corte moderno fade con navaja y acabado perfecto.',
        'isActive': true,
      },
    ];

    final WriteBatch batch = _db.batch();
    for (final service in services) {
      final ref = _db.collection('services').doc();
      batch.set(ref, service);
    }
    await batch.commit();
    if (kDebugMode) {
      debugPrint('[Seed] Services seeded successfully.');
    }
  }
}

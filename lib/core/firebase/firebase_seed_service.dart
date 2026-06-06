import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seeds initial data into Firestore if collections are empty.
/// Run once on app startup.
///
/// Qué seedea:
///   - `services/`: catálogo base si la colección está vacía.
///   - `config/barberia`: documento único de configuración global si no existe.
///
/// Barberos NO se seedean automáticamente: se crean manualmente desde el
/// panel admin al promover un usuario, para evitar IDs huérfanos.
class FirebaseSeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedIfNeeded() async {
    await _seedServices();
    await _seedConfig();
  }

  Future<void> _seedServices() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _db.collection('services').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[Seed] Services already exist, skipping.');
      }
      return;
    }

    final List<Map<String, dynamic>> services = <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'Corte Clásico',
        'price': 100.0,
        'durationMinutes': 45,
        'category': 'hair',
        'extendedDescription':
            'Corte de cabello tradicional con tijera y máquina, lavado y peinado.',
        'isActive': true,
      },
      <String, dynamic>{
        'name': 'Afeitado de Barba',
        'price': 80.0,
        'durationMinutes': 30,
        'category': 'beard',
        'extendedDescription':
            'Afeitado completo con toalla caliente, aceites esenciales y masaje facial.',
        'isActive': true,
      },
      <String, dynamic>{
        'name': 'Combo Completo',
        'price': 160.0,
        'durationMinutes': 75,
        'category': 'combo',
        'extendedDescription':
            'La experiencia completa: Corte de cabello y afeitado de barba premium.',
        'isActive': true,
      },
      <String, dynamic>{
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
    for (final Map<String, dynamic> service in services) {
      final DocumentReference<Map<String, dynamic>> ref =
          _db.collection('services').doc();
      batch.set(ref, service);
    }
    await batch.commit();
    if (kDebugMode) {
      debugPrint('[Seed] Services seeded successfully.');
    }
  }

  Future<void> _seedConfig() async {
    final DocumentReference<Map<String, dynamic>> configRef =
        _db.collection('config').doc('barberia');
    final DocumentSnapshot<Map<String, dynamic>> snap = await configRef.get();
    if (snap.exists) {
      if (kDebugMode) {
        debugPrint('[Seed] Config already exists, skipping.');
      }
      return;
    }

    await configRef.set(<String, dynamic>{
      'businessName': 'Barbería',
      'openHour': 9,
      'closeHour': 19,
      'slotMinutes': 30,
      'address': '',
      'phone': null,
      'whatsappPhone': null,
      'autoReleaseHours': 4,
      'maxNoShows': 3,
      'requireConfirmation': true,
    });
    if (kDebugMode) {
      debugPrint('[Seed] Config seeded successfully.');
    }
  }
}

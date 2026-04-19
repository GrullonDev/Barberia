// ignore_for_file: avoid_print
//
// Script one-shot: migra documentos `bookings/` al esquema v2.
//
// Cambios que aplica por cada doc:
//   - Añade `barberId: ''` si no existe (pendiente de asignar).
//   - Añade `endAt = date + serviceDurationMinutes (o 30min default)` si no existe.
//   - Denormaliza `serviceDurationMinutes` y `servicePrice` leyendo el servicio.
//   - Normaliza `status`: `active → pending` (los demás se dejan igual).
//   - Añade `phoneNormalized` a partir de `customerPhone`.
//   - Añade `createdAt`/`updatedAt` = now si no existen.
//
// Es IDEMPOTENTE: si detecta que el doc ya tiene `endAt` + `barberId`, lo salta.
//
// Uso:
//   dart run tool/migrate_bookings_v2.dart
//
// Requisitos:
//   - Credencial de admin Firebase (GOOGLE_APPLICATION_CREDENTIALS apuntando
//     al service account JSON) o ejecutar desde un entorno autenticado con
//     gcloud.
//   - El paquete `firebase_admin` no existe para Dart; se recomienda ejecutar
//     esta migración equivalente como Cloud Function `migrateBookingsV2` o
//     con el SDK de Node. Este archivo DART es la referencia lógica para
//     re-implementar; ver `backend/functions/src/migrateBookingsV2.ts` cuando
//     se monte el backend (Fase 2).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:barberia/common/utils/phone_normalizer.dart';

Future<void> migrateBookingsV2() async {
  if (!kDebugMode) {
    print('Esta migración debe correrse en kDebugMode o adaptarse a Admin SDK.');
    return;
  }

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final QuerySnapshot<Map<String, dynamic>> bookings =
      await db.collection('bookings').get();

  int migrated = 0;
  int skipped = 0;
  int failed = 0;

  // Cache de servicios para no releer por cada booking
  final QuerySnapshot<Map<String, dynamic>> servicesSnap =
      await db.collection('services').get();
  final Map<String, Map<String, dynamic>> servicesById =
      <String, Map<String, dynamic>>{
    for (final QueryDocumentSnapshot<Map<String, dynamic>> d
        in servicesSnap.docs)
      d.id: d.data()
  };

  final WriteBatch batch = db.batch();
  int ops = 0;

  for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in bookings.docs) {
    try {
      final Map<String, dynamic> data = doc.data();

      // Idempotencia: si ya tiene endAt Y barberId, saltar
      if (data['endAt'] != null && data['barberId'] != null) {
        skipped++;
        continue;
      }

      final Timestamp? dateTs =
          (data['startAt'] as Timestamp?) ?? (data['date'] as Timestamp?);
      if (dateTs == null) {
        failed++;
        print('⚠️  Saltado ${doc.id}: sin date/startAt.');
        continue;
      }

      final DateTime startAt = dateTs.toDate();
      final Map<String, dynamic>? svc =
          servicesById[data['serviceId'] as String? ?? ''];
      final int duration =
          (data['serviceDurationMinutes'] as num?)?.toInt() ??
              (svc?['durationMinutes'] as num?)?.toInt() ??
              30;
      final double price = (data['servicePrice'] as num?)?.toDouble() ??
          (svc?['price'] as num?)?.toDouble() ??
          0.0;

      final DateTime endAt = startAt.add(Duration(minutes: duration));

      final String rawStatus = (data['status'] as String?) ?? 'pending';
      final String newStatus = rawStatus == 'active' ? 'pending' : rawStatus;

      final Map<String, dynamic> update = <String, dynamic>{
        'barberId': data['barberId'] ?? '',
        'serviceDurationMinutes': duration,
        'servicePrice': price,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'status': newStatus,
        'phoneNormalized':
            data['phoneNormalized'] ?? normalizePhone(data['customerPhone'] as String?),
        'createdAt': data['createdAt'] ?? Timestamp.fromDate(startAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.update(doc.reference, update);
      ops++;
      migrated++;

      // Commit cada 400 ops (limite batch Firestore: 500)
      if (ops >= 400) {
        await batch.commit();
        ops = 0;
      }
    } catch (e) {
      failed++;
      print('❌ Error migrando ${doc.id}: $e');
    }
  }

  if (ops > 0) {
    await batch.commit();
  }

  print('═══════════════════════════════════════');
  print('  Migración bookings v2 completada');
  print('═══════════════════════════════════════');
  print('  Migrados: $migrated');
  print('  Saltados (ya v2): $skipped');
  print('  Fallidos: $failed');
  print('═══════════════════════════════════════');
}

void main() async {
  // Cuando ejecutes fuera de Flutter, inicializa Firebase Admin aquí.
  // Desde un botón de debug dentro de la app, llama directamente a
  // `migrateBookingsV2()`.
  await migrateBookingsV2();
}

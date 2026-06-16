import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barberia/features/admin/models/admin_notification.dart';

class AdminNotificationRepository {
  AdminNotificationRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('admin_notifications');

  Stream<List<AdminNotification>> watchRecent({int limit = 20}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) =>
              snap.docs.map(AdminNotification.fromFirestore).toList(),
        );
  }
}

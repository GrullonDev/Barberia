import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.barberId,
    this.read = false,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? barberId;
  final bool read;

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    return AdminNotification(
      id: doc.id,
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      barberId: data['barberId'] as String?,
      read: data['read'] as bool? ?? false,
      createdAt: createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

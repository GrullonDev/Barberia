import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/features/booking/models/service.dart';

class ServiceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Service>> getServices({bool onlyActive = true}) async {
    Query<Map<String, dynamic>> query = _db.collection('services');
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(Service.fromFirestore).toList();
  }

  Future<void> addService(Service service) async {
    await _db.collection('services').add(service.toFirestore());
  }

  Future<void> updateService(Service service) async {
    if (service.id == null) {
      return;
    }
    await _db
        .collection('services')
        .doc(service.id)
        .update(service.toFirestore());
  }

  Future<void> deleteService(String id) async {
    await _db.collection('services').doc(id).delete();
  }

  Future<void> toggleServiceVisibility(String id, bool isActive) async {
    await _db.collection('services').doc(id).update({'isActive': isActive});
  }
}

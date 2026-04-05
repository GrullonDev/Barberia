import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberia/features/booking/models/booking.dart';

class BookingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Booking>> getBookings(String userId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map(Booking.fromFirestore).toList();
  }

  Future<void> createBooking(Booking booking) async {
    final docRef = _db.collection('bookings').doc(booking.id);
    await docRef.set(booking.toFirestore());
  }

  Future<void> cancelBooking(String id) async {
    await _db.collection('bookings').doc(id).update({
      'status': BookingStatus.canceled.name,
    });
  }

  Future<List<Booking>> getAllBookingsAdmin() async {
    final snapshot = await _db
        .collection('bookings')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map(Booking.fromFirestore).toList();
  }
}

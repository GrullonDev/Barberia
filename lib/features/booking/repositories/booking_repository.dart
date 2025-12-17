import 'package:sqflite/sqflite.dart';
import 'package:barberia/core/database/database_helper.dart';
import 'package:barberia/features/booking/models/booking.dart';

class BookingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Booking>> getBookings(String userId) async {
    final Database db = await _dbHelper.database;

    // We want to join with services to get full service object ideally,
    // or we rely on denormalized data. Let's try to fetch services as well.
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'userId = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'date DESC',
    );

    // For a cleaner approach, one might join tables.
    // For now, we will reconstruct Booking.
    // Ideally we also fetch the service details to populate the 'service' field properly
    // so we can get updated durations etc if they changed, though booking snapshot is safer.

    // Let's stick to the model's fromMap which uses denormalized data for main checks.
    return List.generate(maps.length, (int i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<void> createBooking(Booking booking) async {
    final Database db = await _dbHelper.database;
    await db.insert(
      'bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cancelBooking(String id) async {
    final Database db = await _dbHelper.database;
    await db.update(
      'bookings',
      <String, Object?>{'status': BookingStatus.canceled.name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Booking>> getAllBookingsAdmin() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (int i) => Booking.fromMap(maps[i]));
  }
}

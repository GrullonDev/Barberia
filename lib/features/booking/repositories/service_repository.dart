import 'package:sqflite/sqflite.dart';
import 'package:barberia/core/database/database_helper.dart';
import 'package:barberia/features/booking/models/service.dart';

class ServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Service>> getServices({bool onlyActive = true}) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'services',
      where: onlyActive ? 'isActive = ?' : null,
      whereArgs: onlyActive ? [1] : null,
    );

    return List.generate(maps.length, (i) => Service.fromMap(maps[i]));
  }

  Future<void> addService(Service service) async {
    final Database db = await _dbHelper.database;
    await db.insert(
      'services',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateService(Service service) async {
    final Database db = await _dbHelper.database;
    await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<void> deleteService(String id) async {
    final Database db = await _dbHelper.database;
    // We might want soft delete, but for now hard delete or set isActive = 0
    await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  // Toggle visibility instead of deleting
  Future<void> toggleServiceVisibility(String id, bool isActive) async {
    final Database db = await _dbHelper.database;
    await db.update(
      'services',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

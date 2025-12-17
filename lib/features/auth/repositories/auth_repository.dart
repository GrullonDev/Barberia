import 'package:sqflite/sqflite.dart';
import 'package:barberia/core/database/database_helper.dart';
import 'package:barberia/features/auth/models/user.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Simple in-memory session for this MVP
  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<User?> login(String email, String password) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      _currentUser = User.fromMap(maps.first);
      return _currentUser;
    }
    return null;
  }

  Future<User> register(User user) async {
    final Database db = await _dbHelper.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    _currentUser = user;
    return user;
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}

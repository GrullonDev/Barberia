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

    // Determine role: first user is admin, others are clients.
    final List<Map<String, dynamic>> users = await db.query('users');
    final bool isFirstUser = users.isEmpty;
    final UserRole role = isFirstUser ? UserRole.admin : UserRole.client;

    final User newUser = User(
      id: user.id,
      name: user.name,
      email: user.email,
      password: user.password,
      role: role, // Assign determined role
      phone: user.phone,
    );

    await db.insert(
      'users',
      newUser.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    _currentUser = newUser;
    return newUser;
  }

  Future<void> updatePassword(String userId, String newPassword) async {
    final Database db = await _dbHelper.database;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(password: newPassword);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}

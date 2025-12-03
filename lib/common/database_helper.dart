import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/auth/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('services.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUsersTable(db);
    }
  }

  Future _createDB(Database db, int version) async {
    await _createServicesTable(db);
    await _createUsersTable(db);
  }

  Future<void> _createServicesTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE services ( 
  id $idType, 
  name $textType,
  category $textType,
  durationMinutes $intType,
  price $doubleType,
  description $textType
  )
''');
    
    // Insertar servicios predefinidos
    await db.insert('services', {
      'name': 'Corte',
      'category': 'hair',
      'durationMinutes': 30,
      'price': 25.0,
      'description': 'Corte de cabello clasico.'
    });
    await db.insert('services', {
      'name': 'Corte y Barba',
      'category': 'combo',
      'durationMinutes': 60,
      'price': 40.0,
      'description': 'Corte de cabello y arreglo de barba.'
    });
    await db.insert('services', {
      'name': 'Barba',
      'category': 'beard',
      'durationMinutes': 20,
      'price': 15.0,
      'description': 'Arreglo y delineado de barba.'
    });
  }

  Future<void> _createUsersTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  username $textType UNIQUE,
  password $textType,
  role $textType
)
''');

    // Create admin user
    final adminPassword = sha256.convert(utf8.encode('barberia_admin')).toString();
    await db.insert('users', {
      'username': 'admin',
      'password': adminPassword,
      'role': 'admin',
    });
  }

  Future<Service> create(Service service) async {
    final db = await instance.database;
    final id = await db.insert('services', service.toJson());
    return service.copyWith(id: id);
  }

  Future<User> createUser(User user) async {
    final db = await instance.database;
    final hashedPassword = sha256.convert(utf8.encode(user.password)).toString();
    final userWithHashedPassword = user.copyWith(password: hashedPassword);
    final id = await db.insert('users', userWithHashedPassword.toJson());
    return user.copyWith(id: id);
  }

  Future<User?> readUserByUsername(String username) async {
    final db = await instance.database;

    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'password', 'role'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> authenticateUser(String username, String password) async {
    final db = await instance.database;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Service> readService(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'services',
      columns: ['id', 'name', 'category', 'durationMinutes', 'price', 'description'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Service.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Service>> readAllServices() async {
    final db = await instance.database;

    final result = await db.query('services');

    return result.map((json) => Service.fromJson(json)).toList();
  }

  Future<int> update(Service service) async {
    final db = await instance.database;

    return db.update(
      'services',
      service.toJson(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final String dbName = dotenv.env['DB_NAME'] ?? 'default_barberia.db';
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  FutureOr<void> _createDB(Database db, int version) async {
    const String idType = 'TEXT PRIMARY KEY';
    const String textType = 'TEXT NOT NULL';
    const String textNullable = 'TEXT';
    const String intType = 'INTEGER NOT NULL';
    const String realType = 'REAL NOT NULL';
    const String boolType = 'INTEGER NOT NULL'; // 0 or 1

    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType,
        password $textType, 
        role $textType,
        phone $textNullable
      )
    ''');

    // 2. Services Table
    await db.execute('''
      CREATE TABLE services (
        id $idType,
        name $textType,
        price $realType,
        durationMinutes $intType,
        category $textType,
        extendedDescription $textNullable,
        isActive $boolType
      )
    ''');

    // 3. Bookings Table
    await db.execute('''
      CREATE TABLE bookings (
        id $idType,
        userId $textType,
        serviceId $textType,
        serviceName $textType,
        date $textType,
        status $textType,
        customerName $textType,
        customerEmail $textNullable,
        customerPhone $textNullable,
        notes $textNullable,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (serviceId) REFERENCES services (id)
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Seed Admin User
    // In a real app, password should be hashed. This is for demo/MVP.
    await db.insert('users', <String, Object?>{
      'id': 'admin_01',
      'name': 'Barber Admin',
      'email': 'admin@barberia.com',
      'password': 'admin',
      'role': 'admin',
      'phone': '555-0000',
    });

    // Seed Initial Services
    final List<Map<String, dynamic>> services = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'srv_01',
        'name': 'Corte Clásico',
        'price': 100.0,
        'durationMinutes': 45,
        'category': 'hair',
        'extendedDescription':
            'Corte de cabello tradicional con tijera y máquina, lavado y peinado.',
        'isActive': 1,
      },
      <String, dynamic>{
        'id': 'srv_02',
        'name': 'Afeitado de Barba',
        'price': 80.0,
        'durationMinutes': 30,
        'category': 'beard',
        'extendedDescription':
            'Afeitado completo con toalla caliente, aceites esenciales y masaje facial.',
        'isActive': 1,
      },
      <String, dynamic>{
        'id': 'srv_03',
        'name': 'Combo Completo',
        'price': 160.0,
        'durationMinutes': 75,
        'category': 'combo',
        'extendedDescription':
            'La experiencia completa: Corte de cabello y afeitado de barba premium.',
        'isActive': 1,
      },
      <String, dynamic>{
        'id': 'srv_04',
        'name': 'Corte Degradado',
        'price': 120.0,
        'durationMinutes': 60,
        'category': 'hair',
        'extendedDescription':
            'Corte moderno fade con navaja y acabado perfecto.',
        'isActive': 1,
      },
    ];

    for (Map<String, dynamic> service in services) {
      await db.insert('services', service);
    }

    if (kDebugMode) {
      print('Database seeded with Admin user and initial Services.');
    }
  }

  Future<int> updateUserRole(String email, String newRole) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'role': newRole},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final db = await instance.database;
    final result = await db.query(
      'bookings',
      orderBy: 'date DESC',
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getBookingsByUserId(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'bookings',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result;
  }

  Future<void> close() async {
    final Database db = await instance.database;
    db.close();
  }
}

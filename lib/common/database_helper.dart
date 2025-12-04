import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/auth/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('services.db');
    return _database!;
  }

  Future<String> get dbPath async {
    final String dbPath = await getDatabasesPath();
    return join(dbPath, 'services.db');
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUsersTable(db);
    }
    if (oldVersion < 3) {
      await _createBookingsTable(db);
    }
  }

  Future _createDB(Database db, int version) async {
    await _createServicesTable(db);
    await _createUsersTable(db);
    await _createBookingsTable(db);
  }

  Future<void> _createServicesTable(Database db) async {
    const String idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const String textType = 'TEXT NOT NULL';
    const String intType = 'INTEGER NOT NULL';
    const String doubleType = 'REAL NOT NULL';

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
    await db.insert('services', <String, Object?>{
      'name': 'Corte',
      'category': 'hair',
      'durationMinutes': 30,
      'price': 25.0,
      'description': 'Corte de cabello clasico.',
    });
    await db.insert('services', <String, Object?>{
      'name': 'Corte y Barba',
      'category': 'combo',
      'durationMinutes': 60,
      'price': 40.0,
      'description': 'Corte de cabello y arreglo de barba.',
    });
    await db.insert('services', <String, Object?>{
      'name': 'Barba',
      'category': 'beard',
      'durationMinutes': 20,
      'price': 15.0,
      'description': 'Arreglo y delineado de barba.',
    });
  }

  Future<void> _createUsersTable(Database db) async {
    const String idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const String textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  username $textType UNIQUE,
  password $textType,
  role $textType
)
''');

    // Create admin user
    final String adminPassword = sha256
        .convert(utf8.encode('barberia_admin'))
        .toString();
    await db.insert('users', <String, Object?>{
      'username': 'admin',
      'password': adminPassword,
      'role': 'admin',
    });
  }

  Future<Service> create(Service service) async {
    final Database db = await instance.database;
    final int id = await db.insert('services', service.toJson());
    return service.copyWith(id: id);
  }

  Future<User> createUser(User user) async {
    final Database db = await instance.database;
    final String hashedPassword = sha256
        .convert(utf8.encode(user.password))
        .toString();
    final User userWithHashedPassword = user.copyWith(password: hashedPassword);
    final int id = await db.insert('users', userWithHashedPassword.toJson());
    return user.copyWith(id: id);
  }

  Future<User?> readUserByUsername(String username) async {
    final Database db = await instance.database;

    final List<Map<String, Object?>> maps = await db.query(
      'users',
      columns: <String>['id', 'username', 'password', 'role'],
      where: 'username = ?',
      whereArgs: <Object?>[username],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> authenticateUser(String username, String password) async {
    final Database db = await instance.database;
    final String hashedPassword = sha256
        .convert(utf8.encode(password))
        .toString();

    final List<Map<String, Object?>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: <Object?>[username, hashedPassword],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Service> readService(int id) async {
    final Database db = await instance.database;

    final List<Map<String, Object?>> maps = await db.query(
      'services',
      columns: <String>[
        'id',
        'name',
        'category',
        'durationMinutes',
        'price',
        'description',
      ],
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );

    if (maps.isNotEmpty) {
      return Service.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Service>> readAllServices() async {
    final Database db = await instance.database;

    final List<Map<String, Object?>> result = await db.query('services');

    return result
        .map((Map<String, Object?> json) => Service.fromJson(json))
        .toList();
  }

  Future<int> update(Service service) async {
    final Database db = await instance.database;

    return db.update(
      'services',
      service.toJson(),
      where: 'id = ?',
      whereArgs: <Object?>[service.id],
    );
  }

  Future<int> delete(int id) async {
    final Database db = await instance.database;

    return await db.delete(
      'services',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future close() async {
    final Database db = await instance.database;

    db.close();
  }

  Future<void> _createBookingsTable(Database db) async {
    const String textType = 'TEXT NOT NULL';
    const String intType = 'INTEGER NOT NULL';
    const String textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE bookings (
  id TEXT PRIMARY KEY,
  serviceId $intType,
  dateTime $intType,
  customerName $textType,
  customerPhone $textNullable,
  customerEmail $textNullable,
  notes $textNullable,
  status $textType,
  FOREIGN KEY (serviceId) REFERENCES services (id)
)
''');
  }

  Future<int> createBooking(Booking booking) async {
    final Database db = await instance.database;
    return await db.insert('bookings', booking.toMap());
  }

  Future<List<Booking>> readAllBookings() async {
    final Database db = await instance.database;
    // Necesitamos cargar los servicios para reconstruir el objeto Booking completo
    // Esto podría optimizarse con un JOIN, pero por simplicidad lo haremos así por ahora
    // o asumiendo que tenemos acceso a los servicios.
    // Una mejor estrategia es hacer un JOIN en la consulta.

    final List<Map<String, dynamic>> resultWithServices = await db.rawQuery('''
      SELECT b.*, s.name as serviceName, s.category as serviceCategory, 
             s.durationMinutes as serviceDuration, s.price as servicePrice, 
             s.description as serviceDescription
      FROM bookings b
      INNER JOIN services s ON b.serviceId = s.id
    ''');

    return resultWithServices.map((Map<String, dynamic> json) {
      final Service service = Service(
        id: json['serviceId'],
        name: json['serviceName'],
        durationMinutes: json['serviceDuration'],
        price: json['servicePrice'],
        category: ServiceCategory.values.firstWhere(
          (ServiceCategory e) =>
              e.toString().split('.').last == json['serviceCategory'],
          orElse: () => ServiceCategory.hair,
        ),
        extendedDescription: json['serviceDescription'],
      );
      return Booking.fromMap(json, service);
    }).toList();
  }

  Future<int> updateBooking(Booking booking) async {
    final Database db = await instance.database;
    return db.update(
      'bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[booking.id],
    );
  }

  Future<int> deleteBooking(String id) async {
    final Database db = await instance.database;
    return await db.delete(
      'bookings',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}

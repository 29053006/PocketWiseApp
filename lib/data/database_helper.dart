import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

import '../models/transaction_model.dart' as my_models;
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    developer.log('Initializing database...');
    final startTime = DateTime.now();

    _database = await _initDB();

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    developer.log('Database initialized in ${duration.inMilliseconds} ms');

    return _database!;
  }

  DatabaseHelper._internal();

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version to trigger onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL,
        date TEXT,
        type TEXT,
        category TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE user(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        avatar TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN type TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN category TEXT');
    }
  }

  Future<int> insertTransaction(my_models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<my_models.Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');

    return List.generate(maps.length, (i) {
      return my_models.Transaction(
        id: maps[i]['id'],
        description: maps[i]['description'],
        amount: maps[i]['amount'],
        date: DateTime.parse(maps[i]['date']),
        type: maps[i]['type'] ?? 'Expense', // Default value for existing data
        category: maps[i]['category'] ?? 'Other', // Default value
      );
    });
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('user', user.toMap());
  }

  Future<User?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user');

    if (maps.isNotEmpty) {
      return User(
        id: maps.first['id'],
        name: maps.first['name'],
        avatar: maps.first['avatar'],
      );
    } else {
      return null;
    }
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

import '../models/transaction_model.dart' as my_models;
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  static Future<Database>? _dbInitFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (_dbInitFuture != null) {
      return _dbInitFuture!;
    }

    developer.log('Initializing database...');
    final startTime = DateTime.now();

    _dbInitFuture = _initDB();
    _database = await _dbInitFuture;
    _dbInitFuture = null;

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    developer.log('Database initialized in ${duration.inMilliseconds} ms');

    return _database!;
  }

  DatabaseHelper._internal();

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app.db');
    final db = await openDatabase(
      path,
      version: 4, // Incremented version for notifications table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    // Cleanup any corrupted category entries from the previous bug
    await db.execute(
      "UPDATE transactions SET category = 'Other' WHERE category = 'what_was_this_for' OR category = 'where_did_this_come_from'"
    );
    return db;
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
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY,
        amount REAL
      )
    ''');
    // Insert default budget
    await db.insert('budgets', {'id': 1, 'amount': 2000.0});

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        titleKey TEXT,
        messageKey TEXT,
        timestamp TEXT,
        isRead INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN type TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN category TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('CREATE TABLE budgets(id INTEGER PRIMARY KEY, amount REAL)');
      await db.insert('budgets', {'id': 1, 'amount': 2000.0});
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          titleKey TEXT,
          messageKey TEXT,
          timestamp TEXT,
          isRead INTEGER
        )
      ''');
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

  Future<double> getMonthlyBudget() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('budgets', where: 'id = 1');
    if (maps.isNotEmpty) return maps.first['amount'] as double;
    return 2000.0;
  }

  Future<int> updateMonthlyBudget(double amount) async {
    final db = await database;
    return await db.update('budgets', {'amount': amount}, where: 'id = 1');
  }

  Future<void> insertNotification(Map<String, dynamic> map) async {
    final db = await database;
    await db.insert('notifications', map);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await database;
    return await db.query('notifications', orderBy: 'timestamp DESC');
  }

  Future<void> markAllNotificationsRead() async {
    final db = await database;
    await db.update('notifications', {'isRead': 1});
  }

  Future<void> deleteNotification(String id) async {
    final db = await database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllNotifications() async {
    final db = await database;
    await db.delete('notifications');
  }
}

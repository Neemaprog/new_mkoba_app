import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mkoba.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // GROUPS TABLE
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        meeting_frequency TEXT NOT NULL,
        monthly_contribution REAL NOT NULL,
        max_loan_amount REAL NOT NULL,
        interest_rate REAL NOT NULL,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // USERS TABLE
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone_number TEXT NOT NULL,
        password TEXT NOT NULL,
        group_id INTEGER,
        role TEXT DEFAULT 'MEMBER',
        status TEXT DEFAULT 'ACTIVE',
        created_at TEXT,
        updated_at TEXT,
        profile_picture_path TEXT,
        FOREIGN KEY (group_id) REFERENCES groups (id)
      )
    ''');

    // SAVINGS TABLE
    await db.execute('''
      CREATE TABLE savings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        contribution_date TEXT NOT NULL,
        description TEXT,
        type TEXT DEFAULT 'MONTHLY_CONTRIBUTION',
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (group_id) REFERENCES groups (id)
      )
    ''');

    // LOANS TABLE
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        interest_rate REAL,
        total_amount REAL NOT NULL,
        amount_paid REAL DEFAULT 0.0,
        remaining_balance REAL NOT NULL,
        application_date TEXT NOT NULL,
        approval_date TEXT,
        treasurer_confirmation_date TEXT,
        treasurer_confirmation_reason TEXT,
        due_date TEXT,
        completion_date TEXT,
        status TEXT DEFAULT 'PENDING',
        purpose TEXT,
        guarantor TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (group_id) REFERENCES groups (id)
      )
    ''');

    // TRANSACTIONS TABLE
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        description TEXT,
        reference_number TEXT,
        status TEXT DEFAULT 'COMPLETED',
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (group_id) REFERENCES groups (id)
      )
    ''');

    // NOTIFICATIONS TABLE
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT,
        type TEXT DEFAULT 'ANNOUNCEMENT',
        priority TEXT DEFAULT 'MEDIUM',
        created_at TEXT,
        is_read INTEGER DEFAULT 0,
        recipient_type TEXT DEFAULT 'ALL',
        recipient_id INTEGER,
        sent_via TEXT DEFAULT 'APP',
        delivery_status TEXT DEFAULT 'DELIVERED',
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Weka default group
    await db.insert('groups', {
      'name': 'Mkoba Group',
      'description': 'Default savings group',
      'meeting_frequency': 'MONTHLY',
      'monthly_contribution': 50000.0,
      'max_loan_amount': 500000.0,
      'interest_rate': 10.0,
      'active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Ongeza hii baada ya default group insert
    final String adminPassword = sha256
        .convert(utf8.encode('admin123'))
        .toString();

    await db.insert('users', {
      'first_name': 'System',
      'last_name': 'Admin',
      'email': 'admin@mkoba.com',
      'phone_number': '0700000000',
      'password': adminPassword,
      'group_id': 1,
      'role': 'ADMIN',
      'status': 'ACTIVE',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

import 'package:monthly_count/data/icons.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('monthly_count.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    // !! Comment this line for development
    // await deleteDatabase(path); // Add this for testing

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create transaction_category table
    await db.execute('''
      CREATE TABLE transaction_category (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    print('Created transaction_category table');

    // Create financial_record table
    await db.execute('''
      CREATE TABLE financial_record (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category_id TEXT NOT NULL,
        place TEXT NOT NULL,
        price REAL NOT NULL,
        date TEXT NOT NULL,
        splittedInfo TEXT,
        FOREIGN KEY (category_id) REFERENCES transaction_category (id) ON DELETE CASCADE
      )
    ''');
    print('Created financial_record table');
    _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    await db.execute('''
    INSERT INTO transaction_category (id, title, iconCodePoint, color) VALUES
      ('1', 'Food', ${availableIcons[15].codePoint}, 0xFFFF5722),  
      ('3', 'Entertainment', ${availableIcons[8].codePoint}, 0xFF2196F3),
      ('4', 'Grocery', ${availableIcons[22].codePoint}, 0xFF4CAF50),
      ('5', 'Shopping', ${availableIcons[14].codePoint}, 0xFFFFC107),
      ('6', 'Health', ${availableIcons[12].codePoint}, 0xFFE91E63),
      ('7', 'Work', ${availableIcons[4].codePoint}, 0xFF9E9E9E),
      ('8', 'Home', ${availableIcons[2].codePoint}, 0xFF795548),
      ('9', 'Other', ${availableIcons[8].codePoint}, 0xFF616161)
  ''');
    print('Inserted default categories into transaction_category table');
  }

  // Delete all records and drop the database
  Future<void> deleteAll() async {
    final db = await instance.database;

    // Delete the database file, effectively dropping all tables
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'monthly_count.db');
    await deleteDatabase(path); // This deletes the whole database

    // Reopen the database, which will recreate the tables
    _database = await _initDB('monthly_count.db');
  }

  Future<int> insert(String table, Map<String, Object> data) async {
    final db = await instance.database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, Object?>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> delete(String table, String id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(String table, Map<String, Object> data, String id) async {
    final db = await instance.database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

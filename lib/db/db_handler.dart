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
    await db.execute('''
      CREATE TABLE transaction_category (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        icon INTEGER NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    print('Created transaction_category table');
    await db.execute('''
      CREATE TABLE financial_record (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category_id TEXT NOT NULL,
        place TEXT NOT NULL,
        price REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES transaction_category (id) ON DELETE CASCADE
      )
    ''');
    print('Created transaction table');
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

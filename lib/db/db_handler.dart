import 'package:flutter/material.dart';
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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add recurrent and originalRecurrentId columns
      await db.execute('''
        ALTER TABLE financial_record ADD COLUMN recurrent INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE financial_record ADD COLUMN originalRecurrentId TEXT
      ''');
      print('Upgraded database to version 2: added recurrent fields');
    }
    if (oldVersion < 3) {
      // Create transaction_categories join table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_categories (
          transaction_id TEXT NOT NULL,
          category_id TEXT NOT NULL,
          PRIMARY KEY (transaction_id, category_id),
          FOREIGN KEY (transaction_id) REFERENCES financial_record (id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES transaction_category (id) ON DELETE CASCADE
        )
      ''');
      print('Created transaction_categories table');
      
      // Ensure Uncategorized category exists
      final uncategorizedCheck = await db.query(
        'transaction_category',
        where: 'id = ?',
        whereArgs: ['0'],
      );
      if (uncategorizedCheck.isEmpty) {
        await db.execute('''
          INSERT INTO transaction_category (id, title, iconCodePoint, color) VALUES
            ('0', 'Uncategorized', ${Icons.more_horiz.codePoint}, 0xFF9E9E9E)
        ''');
        print('Created Uncategorized category');
      }
      
      // Migrate existing category_id data to transaction_categories
      final transactions = await db.query('financial_record');
      final batch = db.batch();
      const uncategorizedId = '0';
      for (var transaction in transactions) {
        final transactionId = transaction['id'] as String;
        final categoryId = transaction['category_id'] as String?;
        if (categoryId != null && categoryId.isNotEmpty) {
          batch.insert('transaction_categories', {
            'transaction_id': transactionId,
            'category_id': categoryId,
          });
        } else {
          // Assign to Uncategorized if no category
          batch.insert('transaction_categories', {
            'transaction_id': transactionId,
            'category_id': uncategorizedId,
          });
        }
      }
      await batch.commit(noResult: true);
      print('Migrated existing category data to transaction_categories');
      
      // Remove the old category_id column from financial_record
      // SQLite doesn't support DROP COLUMN directly, so we need to recreate the table
      await db.execute('''
        CREATE TABLE financial_record_new (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          place TEXT NOT NULL,
          price REAL NOT NULL,
          date TEXT NOT NULL,
          splittedInfo TEXT,
          recurrent INTEGER NOT NULL DEFAULT 0,
          originalRecurrentId TEXT
        )
      ''');

      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO financial_record_new 
        SELECT id, title, place, price, date, splittedInfo, recurrent, originalRecurrentId
        FROM financial_record
      ''');

      // Drop old table and rename new one
      await db.execute('DROP TABLE financial_record');
      await db.execute(
          'ALTER TABLE financial_record_new RENAME TO financial_record');
      print('Removed category_id column from financial_record table');
    }
    if (oldVersion < 4) {
      // Ensure Uncategorized category exists for existing databases
      final uncategorizedCheck = await db.query(
        'transaction_category',
        where: 'id = ?',
        whereArgs: ['0'],
      );
      if (uncategorizedCheck.isEmpty) {
        await db.execute('''
          INSERT INTO transaction_category (id, title, iconCodePoint, color) VALUES
            ('0', 'Uncategorized', ${Icons.more_horiz.codePoint}, 0xFF9E9E9E)
        ''');
        print('Created Uncategorized category in migration');
      }

      // Check if category_id column still exists and remove it
      try {
        // Try to query the category_id column - if it fails, it doesn't exist
        await db.rawQuery('SELECT category_id FROM financial_record LIMIT 1');
        // If we get here, the column exists - we need to remove it
        print(
            'Removing category_id column from financial_record (migration 4)');
        await db.execute('''
          CREATE TABLE financial_record_new (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            place TEXT NOT NULL,
            price REAL NOT NULL,
            date TEXT NOT NULL,
            splittedInfo TEXT,
            recurrent INTEGER NOT NULL DEFAULT 0,
            originalRecurrentId TEXT
          )
        ''');

        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO financial_record_new 
          SELECT id, title, place, price, date, splittedInfo, recurrent, originalRecurrentId
          FROM financial_record
        ''');

        // Drop old table and rename new one
        await db.execute('DROP TABLE financial_record');
        await db.execute(
            'ALTER TABLE financial_record_new RENAME TO financial_record');
        print(
            'Removed category_id column from financial_record table (migration 4)');
      } catch (e) {
        // Column doesn't exist, which is fine
        print('category_id column already removed or never existed');
      }

      // Assign Uncategorized to transactions without categories
      final allTransactions = await db.query('financial_record');
      final allCategoryLinks = await db.query('transaction_categories');
      final transactionsWithCategories = allCategoryLinks
          .map((row) => row['transaction_id'] as String)
          .toSet();

      final batch = db.batch();
      for (var transaction in allTransactions) {
        final transactionId = transaction['id'] as String;
        if (!transactionsWithCategories.contains(transactionId)) {
          batch.insert('transaction_categories', {
            'transaction_id': transactionId,
            'category_id': '0',
          });
        }
      }
      await batch.commit(noResult: true);
      print('Assigned Uncategorized to transactions without categories');
    }
    if (oldVersion < 5) {
      // Force removal of category_id column if it still exists
      try {
        // Try to query the category_id column - if it fails, it doesn't exist
        await db.rawQuery('SELECT category_id FROM financial_record LIMIT 1');
        // If we get here, the column exists - we need to remove it
        print(
            'Removing category_id column from financial_record (migration 5)');
        await db.execute('''
          CREATE TABLE financial_record_new (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            place TEXT NOT NULL,
            price REAL NOT NULL,
            date TEXT NOT NULL,
            splittedInfo TEXT,
            recurrent INTEGER NOT NULL DEFAULT 0,
            originalRecurrentId TEXT
          )
        ''');

        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO financial_record_new 
          SELECT id, title, place, price, date, splittedInfo, recurrent, originalRecurrentId
          FROM financial_record
        ''');

        // Drop old table and rename new one
        await db.execute('DROP TABLE financial_record');
        await db.execute(
            'ALTER TABLE financial_record_new RENAME TO financial_record');
        print(
            'Removed category_id column from financial_record table (migration 5)');
      } catch (e) {
        // Column doesn't exist, which is fine
        print('category_id column already removed or never existed: $e');
      }
    }
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

    // Create financial_record table (without category_id foreign key)
    await db.execute('''
      CREATE TABLE financial_record (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        place TEXT NOT NULL,
        price REAL NOT NULL,
        date TEXT NOT NULL,
        splittedInfo TEXT,
        recurrent INTEGER NOT NULL DEFAULT 0,
        originalRecurrentId TEXT
      )
    ''');
    print('Created financial_record table');
    
    // Create transaction_categories join table
    await db.execute('''
      CREATE TABLE transaction_categories (
        transaction_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        PRIMARY KEY (transaction_id, category_id),
        FOREIGN KEY (transaction_id) REFERENCES financial_record (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES transaction_category (id) ON DELETE CASCADE
      )
    ''');
    print('Created transaction_categories table');
    
    _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    // Insert Uncategorized category first (ID '0' - special category that cannot be deleted)
    await db.execute('''
    INSERT INTO transaction_category (id, title, iconCodePoint, color) VALUES
      ('0', 'Uncategorized', ${Icons.more_horiz.codePoint}, 0xFF9E9E9E)
    ''');
    
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

  Future<int> update(String table, Map<String, Object> data) async {
    final db = await instance.database;
    return await db
        .update(table, data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // Get category IDs for a transaction
  Future<List<String>> getTransactionCategories(String transactionId) async {
    final db = await instance.database;
    final results = await db.query(
      'transaction_categories',
      columns: ['category_id'],
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return results.map((row) => row['category_id'] as String).toList();
  }

  // Set categories for a transaction (replaces existing)
  Future<void> setTransactionCategories(
      String transactionId, List<String> categoryIds) async {
    final db = await instance.database;
    final batch = db.batch();
    
    // Delete existing categories
    batch.delete('transaction_categories',
        where: 'transaction_id = ?', whereArgs: [transactionId]);
    
    // Insert new categories
    for (var categoryId in categoryIds) {
      batch.insert('transaction_categories', {
        'transaction_id': transactionId,
        'category_id': categoryId,
      });
    }
    
    await batch.commit(noResult: true);
  }

  // Delete all categories for a transaction
  Future<void> deleteTransactionCategories(String transactionId) async {
    final db = await instance.database;
    await db.delete('transaction_categories',
        where: 'transaction_id = ?', whereArgs: [transactionId]);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/db/db_handler.dart';

class CategoriesNotifier extends StateNotifier<List<TransactionCategory>> {
  // init with initial data
  CategoriesNotifier() : super([]) {
    _initializeCategories();
  }

  final _dbHelper = DatabaseHelper.instance;

  /// Initialize categories from the database
  Future<void> _initializeCategories() async {
    try {
      final categoryData = await _dbHelper.queryAll('transaction_category');
      if (categoryData.isEmpty) {
        print("No categories found in the database");
      }
      final categories =
          categoryData.map((e) => TransactionCategory.fromMap(e)).toList();
      state = categories;
    } catch (e) {
      print("Error retrieving categories: $e");
    }
  }


  void addCategory(TransactionCategory category) async {
    // Insert into the database
    await _dbHelper.insert('transaction_category', category.toMap());

    state = [...state, category];
  }

  void updateCategory(TransactionCategory category) async {
    // Prevent editing of Uncategorized category
    if (category.id == '0') {
      print('Cannot edit Uncategorized category');
      return;
    }

    // Update in the database
    await _dbHelper.update('transaction_category', category.toMap());

    state =
        state.map((item) => item.id == category.id ? category : item).toList();
  }

  void removeCategory(TransactionCategory category) async {
    // Prevent deletion of Uncategorized category
    if (category.id == '0') {
      print('Cannot delete Uncategorized category');
      return;
    }

    final db = await _dbHelper.database;
    final uncategorizedId = '0';

    // Find all transactions that have this category
    final transactionsWithCategory = await db.query(
      'transaction_categories',
      columns: ['transaction_id'],
      where: 'category_id = ?',
      whereArgs: [category.id],
    );

    // Replace the deleted category with Uncategorized for all affected transactions
    for (var row in transactionsWithCategory) {
      final transactionId = row['transaction_id'] as String;

      // Get all current categories for this transaction
      final currentCategories =
          await _dbHelper.getTransactionCategories(transactionId);

      // Remove the deleted category and add Uncategorized if not already present
      final updatedCategories =
          currentCategories.where((catId) => catId != category.id).toList();

      // If transaction would have no categories, add Uncategorized
      if (updatedCategories.isEmpty ||
          !updatedCategories.contains(uncategorizedId)) {
        updatedCategories.add(uncategorizedId);
      }

      // Update transaction categories
      await _dbHelper.setTransactionCategories(
          transactionId, updatedCategories);
    }

    // Now remove the category from the database
    await _dbHelper.delete('transaction_category', category.id);

    state = state.where((element) => element.id != category.id).toList();
  }

  // Refresh (reload) the categories from db (case de-sync with db)
  Future<void> refreshCategories() async {
    await _initializeCategories();
    state = state;
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<TransactionCategory>>((ref) {
  return CategoriesNotifier();
});

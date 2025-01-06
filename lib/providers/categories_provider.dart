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

  void removeCategory(TransactionCategory category) async {
    // Remove from the database
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

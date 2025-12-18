import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/db/db_handler.dart';


class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier() : super([]) {
    _initializeTransactions();
  }

  final _dbHelper = DatabaseHelper.instance;

  /// Initialize transactions from the database
  Future<void> _initializeTransactions() async {
    try {
      final transactionData = await _dbHelper.queryAll('financial_record');
      final transactions = <Transaction>[];
      const uncategorizedId = '0';
      
      for (var transactionMap in transactionData) {
        final transaction = Transaction.fromMap(transactionMap);
        // Load categories from join table
        var categoryIds =
            await _dbHelper.getTransactionCategories(transaction.id);

        // If transaction has no categories, assign to Uncategorized
        if (categoryIds.isEmpty) {
          categoryIds = [uncategorizedId];
          await _dbHelper.setTransactionCategories(transaction.id, categoryIds);
        }
        
        transaction.category_ids = categoryIds;
        transactions.add(transaction);
      }
      
      state = transactions;
      // Check and create recurrent transactions
      _checkAndCreateRecurrentTransactions(transactions);
    } catch (e) {
      print("Error retrieving transactions: $e");
    }
  }

  /// Check and create recurrent transactions that should have occurred
  void _checkAndCreateRecurrentTransactions(
      List<Transaction> allTransactions) async {
    final now = DateTime.now();
    final recurrentTransactions = allTransactions
        .where((t) => t.recurrent && t.originalRecurrentId == t.id)
        .toList();

    for (var recurrentTx in recurrentTransactions) {
      final originalDate = recurrentTx.date;
      var currentDate = DateTime(now.year, now.month, originalDate.day);

      // If today is the day or past the day, create the transaction if it doesn't exist
      if (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
        // Check if this month's recurrent transaction already exists
        final exists = allTransactions.any((t) =>
            t.originalRecurrentId == recurrentTx.id &&
            t.date.year == currentDate.year &&
            t.date.month == currentDate.month &&
            !t.id.contains('_preview_'));

        if (!exists) {
          // Create the actual transaction for this month
          final newTx = Transaction(
            id: '${recurrentTx.id}_${currentDate.millisecondsSinceEpoch}',
            title: recurrentTx.title,
            category_ids: List.from(recurrentTx.category_ids),
            place: recurrentTx.place,
            price: recurrentTx.price,
            date: currentDate,
            splitInfo: recurrentTx.splitInfo,
            recurrent: true,
            originalRecurrentId: recurrentTx.id,
          );
          await _dbHelper.insert('financial_record', newTx.toMap());
          await _dbHelper.setTransactionCategories(newTx.id, newTx.category_ids);
          state = [...state, newTx];
        }
      }
    }
  }

  /// Filter out future recurrent transactions (previews) from calculations
  static List<Transaction> filterValidTransactions(
      List<Transaction> transactions) {
    final now = DateTime.now();
    return transactions.where((t) {
      // Exclude preview transactions (future recurrent)
      if (t.recurrent &&
          t.originalRecurrentId != null &&
          t.id.contains('_preview_')) {
        return false;
      }
      // Exclude future recurrent transactions that haven't occurred yet
      if (t.recurrent && t.originalRecurrentId != null && t.date.isAfter(now)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Add a new transaction
  void addTransaction(Transaction transaction) async {
    // Insert into the database
    await _dbHelper.insert('financial_record', transaction.toMap());
    // Insert categories into join table
    await _dbHelper.setTransactionCategories(transaction.id, transaction.category_ids);
    state = [...state, transaction];
    // Check if we need to create recurrent transactions
    _checkAndCreateRecurrentTransactions(state);
  }

  // Remove a transaction
  void removeTransaction(Transaction transaction) async {
    // Remove from the database (cascade will delete from transaction_categories)
    await _dbHelper.delete('financial_record', transaction.id);
    state = state.where((element) => element.id != transaction.id).toList();
  }

  // Update an existing transaction
  void updateTransaction(Transaction transaction) async {
    // Update the transaction in the database
    await _dbHelper.update('financial_record', transaction.toMap());
    // Update categories in join table
    await _dbHelper.setTransactionCategories(transaction.id, transaction.category_ids);
    // Update the transaction in the state
    state = state.map((item) => item.id == transaction.id ? transaction : item).toList();
  }

  void rebuildItem(Transaction transaction) {
    // Re-add the item to the state
    state = [...state, transaction];
  }

  // Refresh (reload) the categories from db (case de-sync with db)
  Future<void> refreshTransactions() async {
    await _initializeTransactions();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier();
});

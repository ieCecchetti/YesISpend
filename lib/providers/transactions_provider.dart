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
      final transactions =
          transactionData.map((e) => Transaction.fromMap(e)).toList();
      state = transactions;
    } catch (e) {
      print("Error retrieving transactions: $e");
    }
  }

  // Add a new transaction
  void addTransaction(Transaction transaction) async {
    // Insert into the database
    await _dbHelper.insert('financial_record', transaction.toMap());
    state = [...state, transaction];
  }

  // Remove a transaction
  void removeTransaction(Transaction transaction) async {
    // Remove from the database
    await _dbHelper.delete('financial_record', transaction.id);
    state = state.where((element) => element.id != transaction.id).toList();
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

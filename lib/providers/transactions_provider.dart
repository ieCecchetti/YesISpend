import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/db/db_handler.dart';
import 'package:monthly_count/services/image_service.dart';


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
        
        // Filter out non-existent image paths
        if (transaction.imagePaths.isNotEmpty) {
          transaction.imagePaths = await ImageService.filterValidImagePaths(transaction.imagePaths);
          // Update database if paths were filtered
          if (transaction.imagePaths.length != transactionMap['imagePaths'].toString().split(',').length) {
            await _dbHelper.update('financial_record', transaction.toMap());
          }
        }
        
        transactions.add(transaction);
      }
      
      state = transactions;
      // Check and create recurrent transactions
      _checkAndCreateRecurrentTransactions(transactions);
    } catch (e) {
      print("Error retrieving transactions: $e");
    }
  }

  /// Check and create recurrent transactions that should have occurred.
  /// Backfills from the original's month up to current month (respects endDate).
  void _checkAndCreateRecurrentTransactions(
      List<Transaction> allTransactions) async {
    final now = DateTime.now();
    final recurrentTransactions = allTransactions
        .where((t) => t.recurrent && t.originalRecurrentId == t.id)
        .toList();

    for (var recurrentTx in recurrentTransactions) {
      final originalDate = recurrentTx.date;
      // Backfill from original month up to and including current month (respect endDate)
      var monthToCreate = DateTime(recurrentTx.date.year, recurrentTx.date.month, originalDate.day);
      final currentMonthDate = DateTime(now.year, now.month, originalDate.day);
      final endLimit = recurrentTx.endDate != null &&
              recurrentTx.endDate!.isBefore(currentMonthDate)
          ? recurrentTx.endDate!
          : currentMonthDate;

      while (!monthToCreate.isAfter(endLimit)) {
        // Only create for past and current month, never future
        if (monthToCreate.year > now.year ||
            (monthToCreate.year == now.year && monthToCreate.month > now.month)) {
          break;
        }
        if (recurrentTx.endDate != null && monthToCreate.isAfter(recurrentTx.endDate!)) {
          break;
        }

        final exists = allTransactions.any((t) =>
            t.originalRecurrentId == recurrentTx.id &&
            t.date.year == monthToCreate.year &&
            t.date.month == monthToCreate.month &&
            !t.id.contains('_preview_'));

        if (!exists) {
          final newTx = Transaction(
            id: '${recurrentTx.id}_${monthToCreate.millisecondsSinceEpoch}',
            title: recurrentTx.title,
            category_ids: List.from(recurrentTx.category_ids),
            place: recurrentTx.place,
            price: recurrentTx.price,
            date: monthToCreate,
            splitInfo: recurrentTx.splitInfo,
            recurrent: true,
            originalRecurrentId: recurrentTx.id,
          );
          await _dbHelper.insert('financial_record', newTx.toMap());
          await _dbHelper.setTransactionCategories(newTx.id, newTx.category_ids);
          state = [...state, newTx];
          allTransactions.add(newTx); // so next iteration sees it
        }

        // Next month (same day)
        if (monthToCreate.month == 12) {
          monthToCreate = DateTime(monthToCreate.year + 1, 1, originalDate.day);
        } else {
          monthToCreate = DateTime(monthToCreate.year, monthToCreate.month + 1, originalDate.day);
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

  /// Removes a single transaction (instance or non-recurrent). For recurrence
  /// series actions use [cancelRecurrenceAndMaintains] or [cancelAllRecurrences].
  Future<void> removeTransaction(Transaction transaction) async {
    await _dbHelper.delete('financial_record', transaction.id);
    state = state.where((element) => element.id != transaction.id).toList();
  }

  /// Keeps past months by setting endDate on the original
  /// to the last day of previous month.
  Future<void> cancelRecurrenceAndMaintains(String originalId) async {
    final originalList = state.where((t) => t.id == originalId).toList();
    if (originalList.isEmpty) return;
    final original = originalList.first;
    final now = DateTime.now();
    final lastDayPrevMonth =
        DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
    final updated = Transaction(
      id: original.id,
      title: original.title,
      category_ids: original.category_ids,
      place: original.place,
      price: original.price,
      date: original.date,
      splitInfo: original.splitInfo,
      recurrent: original.recurrent,
      originalRecurrentId: original.originalRecurrentId,
      endDate: lastDayPrevMonth,
      imagePaths: original.imagePaths,
    );
    await _dbHelper.update('financial_record', updated.toMap());
    state = state.map((t) => t.id == original.id ? updated : t).toList();
  }

  /// Deletes the original and all recurrence instances.
  Future<void> cancelAllRecurrences(String originalId) async {
    await _dbHelper.deleteRecurrenceChain(originalId);
    state = state
        .where((t) => t.id != originalId && t.originalRecurrentId != originalId)
        .toList();
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

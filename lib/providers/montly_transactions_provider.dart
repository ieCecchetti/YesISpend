import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/models/transaction.dart';

class MonthlyTransactionsNotifier extends StateNotifier<List<Transaction>> {
  MonthlyTransactionsNotifier(this.ref)
      : _selectedMonth = DateTime.now(),
        super([]) {
    _getByCurrentMonth();
  }

  final Ref ref;
  DateTime _selectedMonth;

  DateTime get selectedMonth => _selectedMonth;

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    _getByCurrentMonth();
  }

  void _getByCurrentMonth() {
    final allTransactions = ref.watch(transactionsProvider);
    state = allTransactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month;
    }).toList();
  }
}

final monthlyTransactionsProvider =
    StateNotifierProvider<MonthlyTransactionsNotifier, List<Transaction>>((ref) {
  return MonthlyTransactionsNotifier(ref);
});

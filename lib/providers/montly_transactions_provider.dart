import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/models/transaction.dart';

// Provider for selected month
final selectedMonthProvider =
    StateNotifierProvider<SelectedMonthNotifier, DateTime>((ref) {
  return SelectedMonthNotifier();
});

class SelectedMonthNotifier extends StateNotifier<DateTime> {
  SelectedMonthNotifier() : super(DateTime.now());

  void setSelectedMonth(DateTime month) {
    state = month;
  }
}

class MonthlyTransactionsNotifier extends StateNotifier<List<Transaction>> {
  MonthlyTransactionsNotifier(this.ref) : super([]) {
    _getByCurrentMonth();
  }

  final Ref ref;

  void _getByCurrentMonth() {
    final allTransactions = ref.watch(transactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    state = allTransactions.where((transaction) {
      return transaction.date.year == selectedMonth.year &&
          transaction.date.month == selectedMonth.month;
    }).toList();
  }
}

final monthlyTransactionsProvider =
    StateNotifierProvider<MonthlyTransactionsNotifier, List<Transaction>>((ref) {
  return MonthlyTransactionsNotifier(ref);
});

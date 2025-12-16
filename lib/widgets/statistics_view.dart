import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/providers/categories_provider.dart';

import 'package:monthly_count/widgets/animations/scrolling_text.dart';

enum PeriodType { month, quarter, year }

class StatisticsView extends ConsumerStatefulWidget {
  final Color? backgroundColor;
  final PeriodType? period;

  const StatisticsView({
    super.key,
    this.backgroundColor,
    this.period,
  });

  @override
  ConsumerState<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends ConsumerState<StatisticsView> {
  PeriodType get _selectedPeriod => widget.period ?? PeriodType.month;

  List<Transaction> _filterTransactionsByPeriod(
      List<Transaction> allTransactions, PeriodType period) {
    final now = DateTime.now();
    final validTransactions =
        TransactionsNotifier.filterValidTransactions(allTransactions);

    switch (period) {
      case PeriodType.month:
        return validTransactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
      case PeriodType.quarter:
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStartMonth = (currentQuarter - 1) * 3 + 1;
        return validTransactions.where((t) {
          return t.date.year == now.year &&
              t.date.month >= quarterStartMonth &&
              t.date.month < quarterStartMonth + 3;
        }).toList();
      case PeriodType.year:
        return validTransactions.where((t) {
          return t.date.year == now.year;
        }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider);
    final validTransactions =
        _filterTransactionsByPeriod(allTransactions, _selectedPeriod);
    final monthlyObjective =
        ref.watch(settingsProvider)[Settings.expenseObjective] as double;
    final categories = ref.watch(categoriesProvider);

    // Calculate statistics
    double totalExpenses = 0.0;
    double totalIncome = 0.0;
    double largestExpense = 10000;
    double largestIncome = double.negativeInfinity;
    Transaction? largestExpenseTransaction;
    Transaction? largestIncomeTransaction;
    
    // Additional statistics
    double fixedExpenses = 0.0;
    double sharedExpenses = 0.0;
    int expenseCount = 0;
    int incomeCount = 0;
    double totalExpenseAmount = 0.0;
    double totalIncomeAmount = 0.0;
    Set<int> daysWithExpenses = {};
    Set<int> daysWithTransactions = {};

    // Aggregate daily expenses
    for (var transaction in validTransactions) {
      if (transaction.price < 0) {
        final expenseAmount = transaction.price.abs();
        totalExpenses += transaction.price;
        totalExpenseAmount += expenseAmount;
        expenseCount++;
        daysWithExpenses.add(transaction.date.day);
        daysWithTransactions.add(transaction.date.day);

        // Fixed expenses (recurrent)
        if (transaction.recurrent && transaction.originalRecurrentId != null) {
          fixedExpenses += expenseAmount;
        }

        // Shared expenses
        if (transaction.splitInfo != null) {
          sharedExpenses += expenseAmount;
        }
        
        if (transaction.price < largestExpense) {
          largestExpense = transaction.price;
          largestExpenseTransaction = transaction;
        }
      } else {
        totalIncome += transaction.price;
        totalIncomeAmount += transaction.price;
        incomeCount++;
        daysWithTransactions.add(transaction.date.day);
        
        if (transaction.price > largestIncome) {
          largestIncome = transaction.price;
          largestIncomeTransaction = transaction;
        }
      }
    }
    
    final balance = totalIncome - totalExpenses;
    final averageExpense =
        expenseCount > 0 ? totalExpenseAmount / expenseCount : 0.0;
    final averageIncome =
        incomeCount > 0 ? totalIncomeAmount / incomeCount : 0.0;
    final savingsRate = totalIncome > 0 ? ((balance / totalIncome) * 100) : 0.0;
    final daysWithExpensesCount = daysWithExpenses.length;
    final activeDaysCount = daysWithTransactions.length;

    // Calculate period-specific metrics
    final now = DateTime.now();
    int daysInPeriod = 0;
    int daysPassed = 0;

    switch (_selectedPeriod) {
      case PeriodType.month:
        daysInPeriod = DateTime(now.year, now.month + 1, 0).day;
        daysPassed = now.day;
        break;
      case PeriodType.quarter:
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStartMonth = (currentQuarter - 1) * 3 + 1;
        final quarterStart = DateTime(now.year, quarterStartMonth, 1);
        final quarterEnd = DateTime(now.year, quarterStartMonth + 3, 0);
        daysInPeriod = quarterEnd.difference(quarterStart).inDays + 1;
        daysPassed = now.difference(quarterStart).inDays + 1;
        break;
      case PeriodType.year:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        daysInPeriod = yearEnd.difference(yearStart).inDays + 1;
        daysPassed = now.difference(yearStart).inDays + 1;
        break;
    }
    
    // Average daily expense
    final double averageDailyExpense =
        daysPassed > 0 ? totalExpenses / daysPassed : 0.0;

    // Projected total expense for the period
    final double projectedTotalExpense = averageDailyExpense * daysInPeriod;

    // Budget calculation (multiply by period factor)
    double periodBudget = monthlyObjective;
    if (_selectedPeriod == PeriodType.quarter) {
      periodBudget = monthlyObjective * 3;
    } else if (_selectedPeriod == PeriodType.year) {
      periodBudget = monthlyObjective * 12;
    }

    // Calculate most expensive category
    final Map<String, double> categoryExpenses = {};
    for (var transaction in validTransactions) {
      if (transaction.price < 0) {
        categoryExpenses[transaction.category_id] =
            (categoryExpenses[transaction.category_id] ?? 0.0) +
                transaction.price.abs();
      }
    }
    String? mostExpensiveCategoryId;
    double maxCategoryExpense = 0.0;
    categoryExpenses.forEach((categoryId, amount) {
      if (amount > maxCategoryExpense) {
        maxCategoryExpense = amount;
        mostExpensiveCategoryId = categoryId;
      }
    });
    TransactionCategory? mostExpensiveCategory;
    if (mostExpensiveCategoryId != null) {
      try {
        mostExpensiveCategory = categories.firstWhere(
          (cat) => cat.id == mostExpensiveCategoryId,
        );
      } catch (_) {
        mostExpensiveCategory = null;
      }
    }

    // Calculate ratios
    final recurringRatio = totalExpenseAmount > 0
        ? (fixedExpenses / totalExpenseAmount) * 100
        : 0.0;
    final sharedRatio = totalExpenseAmount > 0
        ? (sharedExpenses / totalExpenseAmount) * 100
        : 0.0;
    final expenseToIncomeRatio = totalIncome > 0
        ? (totalExpenseAmount / totalIncome) * 100
        : (totalExpenseAmount > 0 ? 100.0 : 0.0);

    // Days remaining and projected balance
    final daysRemaining = daysInPeriod - daysPassed;
    final projectedBalance = balance - (averageDailyExpense * daysRemaining);

    // Budget remaining
    final budgetRemaining =
        periodBudget > 0 ? periodBudget - totalExpenseAmount : 0.0;

    // Calculate percentage of budget used if a budget is defined
    final double budgetUsedPercentage =
        periodBudget > 0 ? (totalExpenses.abs() / periodBudget) * 100 : 0.0;

    // Number of transactions
    final int transactionCount = validTransactions.length;

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildStatisticCard(
                  context,
                  'Total Expenses',
                  '€${totalExpenses.toStringAsFixed(2)}',
                  Icons.money_off,
                  Colors.redAccent,
                ),
                _buildStatisticCard(
                  context,
                  'Total Income',
                  '€${totalIncome.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.greenAccent,
                ),
                if (_selectedPeriod == PeriodType.month)
                  _buildStatisticCard(
                    context,
                    'Average Daily Expense',
                    '€${averageDailyExpense.toStringAsFixed(2)}',
                    Icons.bar_chart,
                    Colors.orangeAccent,
                  ),
                if (_selectedPeriod == PeriodType.month)
                  _buildStatisticCard(
                    context,
                    'Projected Total Expense',
                    '€${projectedTotalExpense.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.purpleAccent,
                  ),
                if (largestExpenseTransaction != null)
                  _buildStatisticCard(
                    context,
                    'Largest Expense',
                    '€${largestExpense.toStringAsFixed(2)} (${largestExpenseTransaction.title})',
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                if (largestIncomeTransaction != null)
                  _buildStatisticCard(
                    context,
                    'Largest Income',
                    '€${largestIncome.toStringAsFixed(2)} (${largestIncomeTransaction.title})',
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                _buildStatisticCard(
                  context,
                  'Number of Transactions',
                  transactionCount.toString(),
                  Icons.receipt_long,
                  Colors.blueAccent,
                ),
                _buildStatisticCard(
                  context,
                  'Balance',
                  '€${balance.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  balance >= 0 ? Colors.green : Colors.red,
                ),
                if (fixedExpenses > 0)
                  _buildStatisticCard(
                    context,
                    'Fixed Expenses',
                    '€${fixedExpenses.toStringAsFixed(2)}',
                    Icons.repeat,
                    Colors.deepPurpleAccent,
                  ),
                if (sharedExpenses > 0)
                  _buildStatisticCard(
                    context,
                    'Shared Expenses',
                    '€${sharedExpenses.toStringAsFixed(2)}',
                    Icons.people,
                    Colors.tealAccent,
                  ),
                if (expenseCount > 0)
                  _buildStatisticCard(
                    context,
                    'Average Expense',
                    '€${averageExpense.toStringAsFixed(2)}',
                    Icons.calculate,
                    Colors.orangeAccent,
                  ),
                if (incomeCount > 0)
                  _buildStatisticCard(
                    context,
                    'Average Income',
                    '€${averageIncome.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.lightGreenAccent,
                  ),
                if (totalIncome > 0)
                  _buildStatisticCard(
                    context,
                    'Savings Rate',
                    '${savingsRate.toStringAsFixed(1)}%',
                    Icons.savings,
                    savingsRate >= 0 ? Colors.green : Colors.red,
                  ),
                _buildStatisticCard(
                  context,
                  'Active Days',
                  '$activeDaysCount days',
                  Icons.calendar_today,
                  Colors.indigoAccent,
                ),
                if (daysWithExpensesCount > 0)
                  _buildStatisticCard(
                    context,
                    'Days with Expenses',
                    '$daysWithExpensesCount days',
                    Icons.event_busy,
                    Colors.redAccent,
                  ),
                if (mostExpensiveCategory != null)
                  _buildStatisticCard(
                    context,
                    'Most Expensive Category',
                    '${mostExpensiveCategory.title} (€${maxCategoryExpense.toStringAsFixed(2)})',
                    IconData(mostExpensiveCategory.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    mostExpensiveCategory.color,
                  ),
                _buildStatisticCard(
                  context,
                  'Expense-to-Income Ratio',
                  '${expenseToIncomeRatio.toStringAsFixed(1)}%',
                  Icons.compare_arrows,
                  expenseToIncomeRatio > 100 ? Colors.red : Colors.orangeAccent,
                ),
                if (recurringRatio > 0)
                  _buildStatisticCard(
                    context,
                    'Recurring Expenses',
                    '${recurringRatio.toStringAsFixed(1)}% of total',
                    Icons.repeat,
                    Colors.deepPurpleAccent,
                  ),
                if (sharedRatio > 0)
                  _buildStatisticCard(
                    context,
                    'Shared Expenses',
                    '${sharedRatio.toStringAsFixed(1)}% of total',
                    Icons.people,
                    Colors.tealAccent,
                  ),
                if (_selectedPeriod == PeriodType.month)
                  _buildStatisticCard(
                    context,
                    'Days Remaining',
                    '$daysRemaining days',
                    Icons.calendar_today,
                    Colors.indigoAccent,
                  ),
                if (_selectedPeriod == PeriodType.month)
                  _buildStatisticCard(
                    context,
                    'Projected Balance',
                    '€${projectedBalance.toStringAsFixed(2)}',
                    Icons.trending_down,
                    projectedBalance >= 0 ? Colors.green : Colors.red,
                  ),
                if (monthlyObjective > 0)
                  _buildStatisticCard(
                    context,
                    'Budget Remaining',
                    '€${budgetRemaining.toStringAsFixed(2)}',
                    Icons.account_balance,
                    budgetRemaining >= 0 ? Colors.green : Colors.red,
                  ),
                if (monthlyObjective > 0)
                  _buildBudgetCard(
                    context,
                    'Budget Used',
                    budgetUsedPercentage,
                    periodBudget,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildStatisticCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 28.0,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              flex: 3, // 60% of the space
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2, // 40% of the space
              child: HorizontalScrollText(
                value: value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
      BuildContext context, String title, double percentage, double budget) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12.0),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              color: percentage > 100
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.secondary,
              minHeight: 10.0,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8.0),
            Text(
              '${percentage.toStringAsFixed(1)}% of €${budget.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

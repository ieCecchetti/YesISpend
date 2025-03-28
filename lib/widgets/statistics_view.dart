import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/widgets/information_title.dart';

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(monthlyTransactionsProvider);
    final monthlyObjective =
        ref.watch(settingsProvider)[Settings.expenseObjective] as double;

    // Calculate statistics
    double totalExpenses = 0.0;
    double totalIncome = 0.0;
    double largestExpense = 10000;
    double largestIncome = double.negativeInfinity;
    Transaction? largestExpenseTransaction;
    Transaction? largestIncomeTransaction;

    // Aggregate daily expenses
    for (var transaction in transactions) {
      if (transaction.price < 0) {
        totalExpenses += transaction.price;
        if (transaction.price < largestExpense) {
          largestExpense = transaction.price;
          largestExpenseTransaction = transaction;
        }
      } else {
        totalIncome += transaction.price;
        if (transaction.price > largestIncome) {
          largestIncome = transaction.price;
          largestIncomeTransaction = transaction;
        }
      }
    }

    // Average daily expense
    final int daysPassed = DateTime.now().day;
    final double averageDailyExpense = totalExpenses / daysPassed;

    // Projected total expense for the month
    final int daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    final double projectedTotalExpense = averageDailyExpense * daysInMonth;

    // Calculate percentage of budget used if a budget is defined
    final double budgetUsedPercentage =
        monthlyObjective > 0 ? (totalExpenses.abs() / monthlyObjective) * 100 : 0.0;

    // Number of transactions
    final int transactionCount = transactions.length;

    return Container(
      color: Colors.blueGrey[900],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InformationTitle(
            title: 'Statistics',
            description:
                 'This panel shows the key statistics of your financial status. '
                'You can see your total expenses, income, average daily expense, '
                'projected total expense, largest expense, largest income, '
                'number of transactions, and budget used percentage.',
          ),
          const SizedBox(height: 8.0),
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
                _buildStatisticCard(
                  context,
                  'Average Daily Expense',
                  '€${averageDailyExpense.toStringAsFixed(2)}',
                  Icons.bar_chart,
                  Colors.orangeAccent,
                ),
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
                if (monthlyObjective > 0)
                  _buildBudgetCard(
                    context,
                    'Budget Used',
                    budgetUsedPercentage,
                    monthlyObjective,
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
      color: Colors.blueGrey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
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
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
              textAlign: TextAlign.right,
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
      color: Colors.blueGrey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8.0),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.blueGrey[700],
              color: percentage > 100 ? Colors.red : Colors.green,
              minHeight: 8.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              '${percentage.toStringAsFixed(1)}% of €${budget.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

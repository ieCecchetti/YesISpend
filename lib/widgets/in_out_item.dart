import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';

class IncomeOutcomeWidget extends ConsumerWidget {
  final Color? backgroundColor;

  const IncomeOutcomeWidget({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(monthlyTransactionsProvider);
    final validTransactions =
        TransactionsNotifier.filterValidTransactions(transactions);
    final totalIncome = validTransactions
        .where((t) => t.price > 0)
        .fold(0.0, (sum, t) => sum + t.price);
    final totalExpenses = validTransactions
        .where((t) => t.price < 0)
        .fold(0.0, (sum, t) => sum + t.price.abs());
    
    // Calculate fixed expenses (recurrent)
    final fixedExpenses = validTransactions
        .where(
            (t) => t.price < 0 && t.recurrent && t.originalRecurrentId != null)
        .fold(0.0, (sum, t) => sum + t.price.abs());

    // Calculate shared expenses (with splitInfo)
    final sharedExpenses = validTransactions
        .where((t) => t.price < 0 && t.splitInfo != null)
        .fold(0.0, (sum, t) => sum + t.price.abs());
    
    final balance = totalIncome - totalExpenses;
    // Calculate percentage: if income is 0 but expenses exist, show 100%+
    final expensePercentage = totalIncome > 0
        ? (totalExpenses / totalIncome) * 100
        : (totalExpenses > 0 ? 100.0 : 0.0);

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ??
              Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: Column(
                children: [
                  Text('Total Balance',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${balance.toStringAsFixed(2)}€',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoCard(
                    'Income',
                    totalIncome,
                    Theme.of(context).colorScheme.secondary,
                    Icons.arrow_upward),
                const SizedBox(width: 12),
                _infoCard('Expenses', totalExpenses,
                    Theme.of(context).colorScheme.error,
                    Icons.arrow_downward),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoCard('Fixed Expenses', fixedExpenses,
                    Theme.of(context).colorScheme.tertiary, Icons.repeat),
                const SizedBox(width: 12),
                _infoCard('Shared Expenses', sharedExpenses,
                    Theme.of(context).colorScheme.primary, Icons.people),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalIncome > 0
                      ? 'Expenses (% of Income)'
                      : 'Expenses (No Income)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: totalIncome > 0
                          ? (expensePercentage >= 100
                              ? double.infinity
                              : expensePercentage == 0
                                  ? 0
                                  : (expensePercentage / 100) *
                                      (MediaQuery.of(context).size.width - 72))
                          : double.infinity, // Show full bar when no income
                      decoration: BoxDecoration(
                        color: totalIncome > 0
                            ? (expensePercentage >= 100
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary)
                            : Theme.of(context)
                                .colorScheme
                                .error, // Red when no income
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalIncome > 0
                          ? '${expensePercentage.toStringAsFixed(1)}% of income'
                          : '€${totalExpenses.toStringAsFixed(2)} spent (no income)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: totalIncome == 0
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                    ),
                    if (totalIncome > 0 && expensePercentage >= 100)
                      Text(
                        'Over budget',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ));
  }
}

Widget _infoCard(String title, double amount, Color color, IconData icon) {
  return Builder(
    builder: (context) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(2)}€',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

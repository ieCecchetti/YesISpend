import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';

class IncomeOutcomeWidget extends ConsumerWidget {

  const IncomeOutcomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(monthlyTransactionsProvider);
    final totalIncome = transactions
        .where((t) => t.price > 0)
        .fold(0.0, (sum, t) => sum + t.price);
    final totalExpenses = transactions
        .where((t) => t.price < 0)
        .fold(0.0, (sum, t) => sum + t.price.abs());
    final balance = totalIncome - totalExpenses;
    final expensePercentage =
        totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0;

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0075FF).withOpacity(0.4),
              const Color(0xFF0075FF).withOpacity(0.25),
            ],
          ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses (% of Income)',
                    style: Theme.of(context).textTheme.bodyMedium),
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
                      width: expensePercentage > 100
                          ? double.infinity
                          : expensePercentage == 0
                              ? 0
                              : (expensePercentage / 100) *
                                  (MediaQuery.of(context).size.width - 72),
                      decoration: BoxDecoration(
                        color: expensePercentage > 100
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${expensePercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.right,
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

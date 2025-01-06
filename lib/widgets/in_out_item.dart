import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/widgets/information_title.dart';

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
        padding: const EdgeInsets.all(16),
        color: Colors.blueGrey[900],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InformationTitle(
              title: 'Income & Expenses',
              description:
                  'This panel provides an overview of your financial status. '
                  'You can see your total balance, income, and expenses. '
                  'The bar below shows the percentage of your income that has been spent.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Total Balance',
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                  Text(
                    '${balance.toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoCard('Income', totalIncome, Colors.greenAccent,
                    Icons.arrow_upward),
                const SizedBox(width: 8),
                _infoCard('Expenses', totalExpenses, Colors.redAccent,
                    Icons.arrow_downward),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expenses (% of Income)',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      height: 12,
                      width: expensePercentage > 100
                          ? double.infinity
                          : expensePercentage == 0
                              ? 0
                              : (expensePercentage / 100) *
                                  MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${expensePercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ));
  }
}

Widget _infoCard(String title, double amount, Color color, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text('${amount.toStringAsFixed(2)}€',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    ),
  );
}

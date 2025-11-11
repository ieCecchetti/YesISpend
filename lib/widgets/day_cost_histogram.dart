import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/models/transaction_category.dart';

class DayCostHistogram extends ConsumerWidget {
  const DayCostHistogram({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(monthlyTransactionsProvider);
    final validTransactions =
        TransactionsNotifier.filterValidTransactions(transactions);
    final categories = ref.watch(categoriesProvider);

    if (validTransactions.isEmpty || categories.isEmpty) {
      return Container(
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
        child: Center(
          child: Text(
            "No transactions or categories found.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Build category map for quick lookup
    final Map<String, TransactionCategory> categoryMap = {
      for (final cat in categories) cat.id: cat,
    };

    // Group expenses by day and category_id
    final Map<int, Map<String, double>> dailyCategoryExpenses = {};

    for (final transaction in validTransactions) {
      if (transaction.price >= 0) continue; // Only expenses

      final day = transaction.date.day;
      final categoryId = transaction.category_id;
      final amount = transaction.price.abs();

      dailyCategoryExpenses.putIfAbsent(day, () => {});
      dailyCategoryExpenses[day]![categoryId] =
          (dailyCategoryExpenses[day]![categoryId] ?? 0) + amount;
    }

    // Prepare chart data
    final List<BarChartGroupData> barGroups = [];

    for (int day = 1; day <= 31; day++) {
      final expensesByCategory = dailyCategoryExpenses[day];
      if (expensesByCategory == null || expensesByCategory.isEmpty) {
        continue;
      }

      double fromY = 0;
      final List<BarChartRodStackItem> stackItems = [];

      for (final entry in expensesByCategory.entries) {
        final categoryId = entry.key;
        final amount = entry.value;
        final category = categoryMap[categoryId];

        if (category == null) continue; // Skip if not found (just in case)

        final toY = fromY + amount;
        stackItems.add(
          BarChartRodStackItem(fromY, toY, category.color),
        );
        fromY = toY;
      }

      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: fromY,
              rodStackItems: stackItems,
              width: 12,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    // Compute maxY
    final maxY = dailyCategoryExpenses.values
        .map((e) => e.values.fold(0.0, (a, b) => a + b))
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.12),
            const Color(0xFF0075FF).withOpacity(0.08),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}€',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameSize: 16, // optional
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        // if (value % 3 == 0) {
                        //   return Text(
                        //     value.toInt().toString(),
                        //     style: const TextStyle(
                        //       color: Colors.white70,
                        //       fontSize: 10,
                        //     ),
                        //   );
                        // }
                        // return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),

                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.3),
                    ),
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.3),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = group.x;
                      final categoryAmounts = dailyCategoryExpenses[day] ?? {};

                      return BarTooltipItem(
                        'Day $day\n',
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ) ??
                            const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: categoryAmounts.entries.map((entry) {
                          final categoryId = entry.key;
                          final amount = entry.value;
                          final category = categoryMap[categoryId];
                          return TextSpan(
                            text:
                                '${category?.title ?? "Unknown"}: ${amount.toStringAsFixed(2)}€\n',
                            style: TextStyle(
                              color: category?.color ?? Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                maxY: maxY + 50, // Add some space for better visuals
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categories.where((category) {
              return transactions.any((transaction) => transaction.category_id == category.id);
            }).map((category) {
              return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.color,
                ),
                ),
                Text(
                category.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                ),
              ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

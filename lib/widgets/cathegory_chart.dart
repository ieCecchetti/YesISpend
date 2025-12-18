import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction_category.dart';

import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';


class CategoryPieChart extends ConsumerWidget {
  final Color? backgroundColor;

  const CategoryPieChart({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);
    final validTransactions =
        TransactionsNotifier.filterValidTransactions(transactions);

    // Aggregate expenses by category
    final Map<TransactionCategory, double> categoryTotals = {};
    for (var transaction in validTransactions) {
      if (transaction.price < 0) {
        // Distribute expense across all categories
        final amountPerCategory = transaction.price.abs() / transaction.category_ids.length;
        for (var categoryId in transaction.category_ids) {
          try {
            final category = categories.firstWhere((c) => c.id == categoryId);
      categoryTotals.update(
              category,
              (value) => value + amountPerCategory,
              ifAbsent: () => amountPerCategory,
      );
          } catch (_) {
            // Category not found, skip
          }
        }
      }
    }
    // Add categories that do not exist in transactions with a total of 0
    for (var category in categories) {
      categoryTotals.putIfAbsent(category, () => 0.0);
    }
    // Sort categoryTotals by total amount in descending order
    final sortedCategoryTotals = Map.fromEntries(
      categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    // Prepare data for the PieChart
    final List<PieChartSectionData> sections = [];
    final totalExpenses = categoryTotals.values.fold(0.0, (a, b) => a + b);

    categoryTotals.forEach((category, total) {
      final percentage = (total / totalExpenses) * 100;
      sections.add(
        PieChartSectionData(
          value: total,
          // title: '${percentage.toStringAsFixed(1)}%',
          title: '',
          color: category.color.withOpacity(0.8),
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: backgroundColor ??
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16.0),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // Legend Section
          Expanded(
            child: ListView.builder(
              itemCount: sortedCategoryTotals.keys.length,
              itemBuilder: (context, index) {
                final category = sortedCategoryTotals.keys.elementAt(index);
                final total = sortedCategoryTotals[category]!;
                final percentage = (total / totalExpenses) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: total != 0
                      ? Row(
                          children: [
                            // Color indicator
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // Category name
                            Expanded(
                              child: Text(
                                category.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Total expense and percentage
                            Text(
                              '€${total.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

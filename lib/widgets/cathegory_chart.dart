import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction_category.dart';

import 'package:monthly_count/widgets/information_title.dart';

import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/montly_transactions_provider.dart';


class CategoryPieChart extends ConsumerWidget {

  const CategoryPieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(monthlyTransactionsProvider);

    // Aggregate expenses by category
    final Map<TransactionCategory, double> categoryTotals = {};
    for (var transaction in transactions) {
      if (transaction.price < 0) {
      categoryTotals.update(
        categories.firstWhere((c) => c.id == transaction.category_id),
        (value) => value + transaction.price.abs(),
        ifAbsent: () => transaction.price.abs(),
      );
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
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
      ),
      child: Column(
        children: [
          const InformationTitle(
            title: "Category Chart",
            description: 'This panel shows the distribution of expenses by category. '
                'Each category is represented by a slice of the pie chart. '
                'The legend below shows the total amount and percentage of expenses for each category.',
          ),
          const SizedBox(height: 32.0),
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
                  child: Row(
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
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Total expense and percentage
                      Text(
                        '€${total.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

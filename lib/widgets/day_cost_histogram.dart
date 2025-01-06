import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/widgets/information_title.dart';

class DayCostHistogram extends ConsumerWidget {
  const DayCostHistogram({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(monthlyTransactionsProvider);

    if (transactions.isEmpty) {
      return Container(
        color: Colors.blueGrey[900],
        child: const Center(
          child: Text(
            "No transactions found.",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    transactions.sort((a, b) => a.date.compareTo(b.date));

    final Map<int, double> dailyExpenses = {};
    for (final transaction in transactions.where((t) => t.price < 0)) {
      final day = transaction.date.day;
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + transaction.price.abs();
    }

    final List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= 31; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyExpenses[i] ?? 0,
              color: Colors.redAccent,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
      ),
      child: Column(
        children: [
          const InformationTitle(
                title: "Daily Histogram",
                description: 'This panel shows the daily expenses histogram. '
                            'Each bar represents the total amount spent on that day. '
                            'You can see the exact amount by tapping on the bar.',
                
              ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}€',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value % 5 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
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
                  border: const Border(
                    left: BorderSide(color: Colors.white70),
                    bottom: BorderSide(color: Colors.white70),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        Colors.blueGrey.withOpacity(0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Day ${group.x}: ',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toStringAsFixed(2)}€',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                maxY: dailyExpenses.values.isNotEmpty
                    ? dailyExpenses.values.reduce((a, b) => a > b ? a : b) + 100
                    : 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

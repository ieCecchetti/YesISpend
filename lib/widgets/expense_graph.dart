import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/widgets/information_title.dart';

class ExpenseGraphScreen extends ConsumerWidget {
  const ExpenseGraphScreen({super.key, required this.monthlyObjective});

  final double monthlyObjective;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get transactions from the provider
    final transactions = ref.watch(monthlyTransactionsProvider);

    if (transactions.isEmpty) {
      return Container(
        color: Colors.blueGrey[900], // Match the background color of the chart
        child: const Center(
          child: Text(
            "No transactions available.",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    // Sort transactions by date
    transactions.sort((a, b) => a.date.compareTo(b.date));

    // Filter transactions for income and expenses
    final incomeTransactions = transactions.where((t) => t.price > 0).toList();
    final outcomeTransactions = transactions.where((t) => t.price < 0).toList();

    // Calculate cumulative values for income and absolute expenses
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> outcomeSpots = [];
    final Map<double, String> dayLabels = {};

    double incomeTotal = 0.0;
    double outcomeTotal = 0.0;

    // Generate spots for income transactions
    for (final transaction in incomeTransactions) {
      incomeTotal += transaction.price;
      incomeSpots.add(FlSpot(
        transaction.date.day.toDouble(),
        incomeTotal,
      ));
      dayLabels[transaction.date.day.toDouble()] =
          '${transaction.date.day}/${transaction.date.month}';
    }

    // Generate spots for outcome transactions
    for (final transaction in outcomeTransactions) {
      outcomeTotal += transaction.price.abs();
      outcomeSpots.add(FlSpot(
        transaction.date.day.toDouble(),
        outcomeTotal,
      ));
      dayLabels[transaction.date.day.toDouble()] =
          '${transaction.date.day}/${transaction.date.month}';
    }
    return Container(
      color: Colors.blueGrey[900], // Background for the graph area
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const InformationTitle(
            title: 'Expenses Graph',
            description:
                'This panel displays a graph of your income and expenses over time. '
                'The green line represents your cumulative income, '
                'while the red line represents your cumulative expenses. '
                'The blue line indicates your monthly objective.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: true,
                  horizontalInterval: 500,
                  verticalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Colors.white38,
                      strokeWidth: 1,
                      dashArray: [4, 4], // Dotted lines
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: Colors.white24,
                      strokeWidth: 1,
                      dashArray: [4, 4], // Dotted lines
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                      interval: 1000,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.lightGreenAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.lightGreenAccent.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    barWidth: 3,
                  ),
                  LineChartBarData(
                    spots: outcomeSpots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.redAccent, Colors.pinkAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.pinkAccent.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    barWidth: 3,
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: monthlyObjective,
                      color: Colors.blueAccent,
                      strokeWidth: 2,
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) =>
                            'Target: max-expenses: ${line.y.toInt()}€',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                minY: 0,
                maxY: outcomeTotal > monthlyObjective ? outcomeTotal+500 : monthlyObjective +500,
                minX: 0,
                maxX: 30,
              ),
            ),
          ),
        ],
      ),
    );
 
  }
}

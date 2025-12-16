import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:monthly_count/models/transaction.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';

class ExpenseGraphScreen extends ConsumerStatefulWidget {
  final Color? backgroundColor;

  ExpenseGraphScreen({super.key, this.backgroundColor});

  @override
  ConsumerState<ExpenseGraphScreen> createState() => _ExpenseGraphScreenState();
}

class _ExpenseGraphScreenState extends ConsumerState<ExpenseGraphScreen> {
  List<LineChartBarData> lineBars = [];
  var minDate = 0.0;
  var maxDate = 30.0;
  var maxY = 0.0;
  var graphLimitY = 0.0;
  bool showIncome = true;
  bool showOutcome = true;
  bool showTarget = true;

  @override
  Widget build(BuildContext context) {
    // Get transactions from the provider
    final transactions = ref.watch(monthlyTransactionsProvider);
    final validTransactions =
        TransactionsNotifier.filterValidTransactions(transactions);
    final monthlyObjective =
        ref.watch(settingsProvider)[Settings.expenseObjective] as double;

    if (validTransactions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
        ),
        child: Center(
          child: Text(
            "No transactions available.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    } else {
      // Sort transactions by date
      validTransactions.sort((a, b) => a.date.compareTo(b.date));

      maxDate = validTransactions.last.date.day.toDouble();

      // Calculate total outcome and income
      final outcomeTotal = validTransactions
          .where((t) => t.price < 0)
          .fold(0.0, (sum, t) => sum + t.price.abs());
      final incomeTotal = validTransactions
          .where((t) => t.price > 0)
          .fold(0.0, (sum, t) => sum + t.price);

      // Generate line bars data
      final errorColor = Theme.of(context).colorScheme.error;
      final secondaryColor = Theme.of(context).colorScheme.secondary;
      final outcomeLineBarsData = getTransactionsLinebars(
          validTransactions.where((t) => t.price < 0).toList(), errorColor);
      final incomeLineBarsData = getTransactionsLinebars(
          validTransactions.where((t) => t.price > 0).toList(), secondaryColor);

      setState(() {
        lineBars = getLineBarsData(
            incomeLineBarsData, showIncome, outcomeLineBarsData, showOutcome);
        graphLimitY =
            retrieveMaxY(lineBars, showTarget ? monthlyObjective : null);
      });

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: showIncome,
                      onChanged: (value) {
                        setState(() {
                          showIncome = value ?? true; // Update showIncome state
                          getLineBarsData(incomeLineBarsData, showIncome,
                              outcomeLineBarsData, showOutcome);
                          // Ensure that if both are unchecked, we still have an empty but valid dataset
                          if (lineBars.isEmpty) {
                            lineBars = [
                              LineChartBarData(spots: [])
                            ]; // Keeps the chart from disappearing
                          }
                        });
                      },
                    ),
                    Text(
                      'Income',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Checkbox(
                      value: showOutcome,
                      onChanged: (value) {
                        setState(() {
                          showOutcome =
                              value ?? true; // Update showIncome state
                          getLineBarsData(incomeLineBarsData, showIncome,
                              outcomeLineBarsData, showOutcome);
                        });
                      },
                    ),
                    Text(
                      'Outcome',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: showTarget,
                      onChanged: (value) {
                        setState(() {
                          showTarget = value ?? true;
                        });
                      },
                    ),
                    Text(
                      'Target',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: LineChart(
                LineChartData(
                  // dotted line grid
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: 500,
                    verticalInterval: 3,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.2),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.15),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      );
                    },
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            if (touchedSpot.bar.spots[touchedSpot.spotIndex].x <
                                    minDate ||
                                touchedSpot.bar.spots[touchedSpot.spotIndex].x >
                                    maxDate) {
                              // Return null for no tooltip for this specific spot
                              return null;
                            }
                            // Otherwise return a tooltip item
                            Color tooltipTextColor =
                                touchedSpot.bar.gradient!.colors.first;
                            return LineTooltipItem(
                                '${touchedSpot.y}',
                                TextStyle(
                                    color:
                                        tooltipTextColor) // Set the tooltip text color to match the line color
                                );
                          }).toList();
                        }),
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((index) {
                        final spotX = barData.spots[index].x;
                        if (spotX < minDate || spotX > maxDate) {
                          // Disable interaction outside the date range
                          return const TouchedSpotIndicatorData(
                              FlLine(color: Colors.transparent, strokeWidth: 0),
                              FlDotData(show: false));
                        }
                        // Enable interaction within the date range
                        return const TouchedSpotIndicatorData(
                            FlLine(color: Colors.blue, strokeWidth: 4),
                            FlDotData(show: true));
                      }).toList();
                    },
                  ),
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
                        interval: 1000,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt().toString()}',
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
                  lineBarsData: lineBars,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: showTarget
                        ? [
                            HorizontalLine(
                              y: monthlyObjective,
                              color: Theme.of(context).colorScheme.primary,
                              strokeWidth: 2,
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                labelResolver: (line) =>
                                    'Target: max-expenses: ${line.y.toInt()}€',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ]
                        : [],
                  ),
                  minY: 0,
                  maxY: graphLimitY,
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

  List<LineChartBarData> getLineBarsData(List<LineChartBarData> incomeBars,
      bool showIncome, List<LineChartBarData> outcomeBars, bool showOutcome) {
    final List<LineChartBarData> result = [];
    if (showIncome) {
      result.addAll(incomeBars);
    }
    if (showOutcome) {
      result.addAll(outcomeBars);
    }
    // If both are unchecked, return a dummy line to prevent disappearance
    if (result.isEmpty) {
      return [
        LineChartBarData(
          spots: [FlSpot(0, 0)],
          isCurved: false,
          barWidth: 0, // Hide line
        )
      ];
    }
    return result;
  }

  double retrieveMaxY(List<LineChartBarData> bars, double? monthlyObjective) {
    // If the monthly objective is set, use it to determine the max Y value
    var maxY = bars
        .map((bar) =>
            bar.spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
    return monthlyObjective != null
        ? (maxY > monthlyObjective ? maxY + 100 : monthlyObjective + 200)
        : maxY + 100;
  }

  List<LineChartBarData> getTransactionsLinebars(
      List<Transaction> transactions, Color color) {
    if (transactions.isEmpty) {
      return [];
    }

    final List<FlSpot> zeroSpots = List.of(
      [
        const FlSpot(0, 0), // Starting point at zero
        FlSpot(transactions.first.date.day.toDouble(),
            transactions.first.price.abs().toDouble()),
      ],
    );

    // Calculate cumulative values for income and absolute expenses
    final List<FlSpot> spots = [];
    final Map<double, String> dayLabels = {};
    double total = 0.0;
    int lastDay = transactions.last.date.day;
    // Generate spots for outcome transactions
    for (final transaction in transactions) {
      total += transaction.price.abs();
      spots.add(FlSpot(
        transaction.date.day.toDouble(),
        total,
      ));
      dayLabels[transaction.date.day.toDouble()] =
          '${transaction.date.day}/${transaction.date.month}';
    }

    // Calculate the estimated increase in expenses
    final estimatedIncrease = total / lastDay;
    final List<FlSpot> projectedSpots = [];

    double lastY = total;
    for (double i = spots.last.x.toDouble() + 1; i < 30; i++) {
      lastY += estimatedIncrease;
      projectedSpots.add(FlSpot(i, lastY));
    }

    return [
      getLineBarObject(zeroSpots, color,
          barWidth: 1, isDashed: true, haveShadow: false, isTouchable: false),
      getLineBarObject(spots, color),
      getLineBarObject(projectedSpots, color,
          barWidth: 2, isDashed: true, haveShadow: false, isTouchable: false),
    ];
  }

  LineChartBarData getLineBarObject(List<FlSpot> spots, Color color,
      {int barWidth = 3,
      bool isDashed = false,
      bool haveShadow = true,
      bool isTouchable = true}) {
    return LineChartBarData(
      // Project zero to data
      spots: spots,
      isCurved: false,
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.9), // Lighter or more transparent
          color.withOpacity(0.7), // Slightly more transparent
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      dotData: FlDotData(show: isTouchable),
      belowBarData: BarAreaData(
        show: haveShadow,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1), // More transparent
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      barWidth: barWidth.toDouble(), // Optionally thinner line for projection
      dashArray: isDashed
          ? [4, 4]
          : null, // Make the projection line dashed only if isDashed
    );
  }
}

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
  var minDate = 1.0;
  var maxDate = 30.0;
  var maxY = 0.0;
  var graphLimitY = 0.0;
  bool showIncome = true;
  bool showOutcome = true;
  bool showTarget = true;
  bool showBalance = false;
  // Store daily values for tooltip
  Map<int, double> dailyIncome = {};
  Map<int, double> dailyExpenses = {};

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

      // Calculate daily values (not cumulative) for tooltip
      dailyIncome.clear();
      dailyExpenses.clear();
      for (var transaction in validTransactions) {
        final day = transaction.date.day;
        if (transaction.price > 0) {
          dailyIncome[day] = (dailyIncome[day] ?? 0.0) + transaction.price;
        } else {
          dailyExpenses[day] =
              (dailyExpenses[day] ?? 0.0) + transaction.price.abs();
        }
      }

      // Generate line bars data
      final errorColor = Theme.of(context).colorScheme.error;
      final secondaryColor = Theme.of(context).colorScheme.secondary;
      // Use a more visible color for balance - purple/violet
      final balanceColor = Colors.purple;
      final outcomeLineBarsData = getTransactionsLinebars(
          validTransactions.where((t) => t.price < 0).toList(), errorColor);
      final incomeLineBarsData = getTransactionsLinebars(
          validTransactions.where((t) => t.price > 0).toList(), secondaryColor);
      final balanceLineBarsData =
          getBalanceLinebars(validTransactions, balanceColor);

      setState(() {
        lineBars = getLineBarsData(
            incomeLineBarsData, showIncome,
            outcomeLineBarsData, showOutcome, balanceLineBarsData, showBalance);
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
            // Icon-only filter chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Tooltip(
                  message: 'Income',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showIncome = !showIncome;
                        lineBars = getLineBarsData(
                            incomeLineBarsData,
                            showIncome,
                            outcomeLineBarsData,
                            showOutcome,
                            balanceLineBarsData,
                            showBalance);
                        if (lineBars.isEmpty) {
                          lineBars = [LineChartBarData(spots: [])];
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: showIncome
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.2)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: showIncome
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.3),
                          width: showIncome ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        size: 20,
                        color: showIncome
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Expenses',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showOutcome = !showOutcome;
                        lineBars = getLineBarsData(
                            incomeLineBarsData,
                            showIncome,
                            outcomeLineBarsData,
                            showOutcome,
                            balanceLineBarsData,
                            showBalance);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: showOutcome
                            ? Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.2)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: showOutcome
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.3),
                          width: showOutcome ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        Icons.trending_down,
                        size: 20,
                        color: showOutcome
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Balance',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showBalance = !showBalance;
                        lineBars = getLineBarsData(
                            incomeLineBarsData,
                            showIncome,
                            outcomeLineBarsData,
                            showOutcome,
                            balanceLineBarsData,
                            showBalance);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: showBalance
                            ? Colors.purple.withOpacity(0.2)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: showBalance
                              ? Colors.purple
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.3),
                          width: showBalance ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        size: 20,
                        color: showBalance
                            ? Colors.purple
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Target',
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showTarget = !showTarget;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: showTarget
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: showTarget
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.3),
                          width: showTarget ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        Icons.flag,
                        size: 20,
                        color: showTarget
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  // dotted line grid
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine:
                        false, // Hide vertical lines for cleaner look
                    horizontalInterval: graphLimitY / 5, // Dynamic interval
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.1),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchSpotThreshold:
                        20, // Increase threshold to make it easier to touch
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      tooltipMargin: 8,
                      getTooltipColor: (touchedSpot) =>
                          Theme.of(context).colorScheme.surface,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return _getTooltipItems(touchedSpots, context);
                      },
                    ),
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                      return _getTouchedSpotIndicator(barData, spotIndexes);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()}€',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                        interval: graphLimitY / 5,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            'Day ${value.toInt()}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
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
                            .withOpacity(0.2),
                        width: 1.5,
                      ),
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.2),
                        width: 1.5,
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
                              strokeWidth: 2.5,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                padding:
                                    const EdgeInsets.only(right: 8, top: 4),
                                labelResolver: (line) =>
                                    'Target: ${line.y.toInt()}€',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            ),
                          ]
                        : [],
                  ),
                  minY: showBalance ? _calculateMinY(lineBars) : 0,
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

  List<LineChartBarData> getLineBarsData(
      List<LineChartBarData> incomeBars,
      bool showIncome,
      List<LineChartBarData> outcomeBars,
      bool showOutcome,
      List<LineChartBarData> balanceBars,
      bool showBalance) {
    final List<LineChartBarData> result = [];
    if (showIncome) {
      result.addAll(incomeBars);
    }
    if (showOutcome) {
      result.addAll(outcomeBars);
    }
    if (showBalance) {
      result.addAll(balanceBars);
    }
    // If all are unchecked, return a dummy line to prevent disappearance
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

  double _calculateMinY(List<LineChartBarData> bars) {
    if (bars.isEmpty) return 0;
    var minY = bars
        .map((bar) =>
            bar.spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b))
        .reduce((a, b) => a < b ? a : b);
    // Add some padding below the minimum
    return minY < 0 ? minY - 100 : 0;
  }

  double retrieveMaxY(List<LineChartBarData> bars, double? monthlyObjective) {
    // If the monthly objective is set, use it to determine the max Y value
    var maxY = bars
        .map((bar) =>
            bar.spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
    // Also check for negative values (balance can be negative)
    var minY = bars
        .map((bar) =>
            bar.spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b))
        .reduce((a, b) => a < b ? a : b);
    final absMax = maxY.abs() > minY.abs() ? maxY.abs() : minY.abs();
    return monthlyObjective != null
        ? (absMax > monthlyObjective ? absMax + 100 : monthlyObjective + 200)
        : absMax + 100;
  }

  List<LineChartBarData> getBalanceLinebars(
      List<Transaction> transactions, Color color) {
    if (transactions.isEmpty) {
      return [];
    }

    // Sort transactions by date
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate cumulative balance (income - outcome)
    final List<FlSpot> spots = [];
    double balance = 0.0;

    // Always start at day 1 with balance 0 to ensure consistent x-coordinates
    spots.add(const FlSpot(1.0, 0.0));

    // Generate spots for balance (cumulative income - cumulative expenses)
    for (final transaction in sortedTransactions) {
      balance += transaction.price; // income is positive, expenses are negative
      final day = transaction.date.day.toDouble();

      // Update day 1 if this is the first transaction on day 1
      if (day == 1.0) {
        final existingIndex = spots.indexWhere((spot) => spot.x == 1.0);
        if (existingIndex >= 0) {
          spots[existingIndex] = FlSpot(1.0, balance);
        } else {
          spots.add(FlSpot(1.0, balance));
        }
      } else {
        // For other days, add the spot
        spots.add(FlSpot(day, balance));
      }
    }

    return [
      getLineBarObject(spots, color),
    ];
  }

  List<LineChartBarData> getTransactionsLinebars(
      List<Transaction> transactions, Color color) {
    if (transactions.isEmpty) {
      return [];
    }

    // Calculate cumulative values for income and absolute expenses
    final List<FlSpot> spots = [];
    final Map<double, String> dayLabels = {};
    double total = 0.0;
    int lastDay = transactions.last.date.day;

    // Always start at day 1 with value 0 to ensure consistent x-coordinates
    spots.add(const FlSpot(1.0, 0.0));

    // Generate spots for transactions
    for (final transaction in transactions) {
      total += transaction.price.abs();
      final day = transaction.date.day.toDouble();

      // Update day 1 if this is the first transaction on day 1
      if (day == 1.0) {
        final existingIndex = spots.indexWhere((spot) => spot.x == 1.0);
        if (existingIndex >= 0) {
          spots[existingIndex] = FlSpot(1.0, total);
        } else {
          spots.add(FlSpot(1.0, total));
        }
      } else {
        // For other days, add the spot
        spots.add(FlSpot(day, total));
      }
      dayLabels[day] =
          '${transaction.date.day}/${transaction.date.month}';
    }

    // Calculate the estimated increase in expenses
    final estimatedIncrease = total / lastDay;
    final List<FlSpot> projectedSpots = [];

    double lastY = total;
    final lastDataDay = spots.last.x;
    for (double i = lastDataDay + 1; i <= 30; i++) {
      lastY += estimatedIncrease;
      projectedSpots.add(FlSpot(i, lastY));
    }

    return [
      getLineBarObject(spots, color),
      if (projectedSpots.isNotEmpty)
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
      spots: spots,
      isCurved: true, // Make lines curved for smoother look
      curveSmoothness: 0.35,
      gradient: LinearGradient(
        colors: [
          color,
          color.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dotData: const FlDotData(show: false), // Remove all dots
      belowBarData: BarAreaData(
        show: haveShadow,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      barWidth: barWidth.toDouble(),
      dashArray: isDashed ? [8, 4] : null,
    );
  }

  /// Checks if a line bar is touchable (not a projection, zero line, or target)
  bool _isLineTouchable(LineChartBarData barData) {
    // Exclude dashed lines (projections and zero lines)
    return barData.dashArray == null;
  }

  /// Normalizes the touch X coordinate to a day value (1-31)
  /// This ensures consistent day calculation across all lines
  int _normalizeTouchXToDay(double touchX) {
    if (touchX <= 0.0) {
      return 1;
    } else if (touchX < 1.0) {
      // Between 0 and 1, it's day 1
      return 1;
    } else {
      // Round to nearest integer for day
      return touchX.round().clamp(1, 31);
    }
  }

  /// Generalized tooltip items generator for all touchable lines
  List<LineTooltipItem> _getTooltipItems(
      List<LineBarSpot> touchedSpots, BuildContext context) {
    if (touchedSpots.isEmpty) {
      return [];
    }

    // Filter out non-touchable lines (projections, zero lines, target)
    final validSpots = touchedSpots.where((spot) {
      return _isLineTouchable(spot.bar);
    }).toList();

    // If we only touched non-touchable lines, don't show tooltip
    if (validSpots.isEmpty) {
      return [];
    }

    // Use the first valid spot's X coordinate to determine the day
    // All touchable lines should have consistent X coordinates for the same day
    final firstValidSpot = validSpots.first;
    final touchX = firstValidSpot.x;
    final touchedDay = _normalizeTouchXToDay(touchX);

    // Get daily values (not cumulative) for this day
    final dayIncome = dailyIncome[touchedDay] ?? 0.0;
    final dayExpenses = dailyExpenses[touchedDay] ?? 0.0;

    // Build tooltip text with day and all available daily values
    final List<LineTooltipItem> tooltipItems = [];

    // Always show the day
    tooltipItems.add(
      LineTooltipItem(
        'Day $touchedDay',
        TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );

    // Show income if available
    if (dayIncome > 0) {
      final incomeColor = Theme.of(context).colorScheme.secondary;
      tooltipItems.add(
        LineTooltipItem(
          'Income: ${dayIncome.toStringAsFixed(2)}€',
          TextStyle(
            color: incomeColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }

    // Show expenses if available
    if (dayExpenses > 0) {
      final expensesColor = Theme.of(context).colorScheme.error;
      tooltipItems.add(
        LineTooltipItem(
          'Expenses: ${dayExpenses.toStringAsFixed(2)}€',
          TextStyle(
            color: expensesColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }

    // If no daily values, show cumulative values from all touchable lines
    // Use the y value directly from touched spots (fl_chart interpolates the value)
    if (dayIncome == 0 && dayExpenses == 0) {
      for (final spot in validSpots) {
        final lineColor = spot.bar.gradient?.colors.first ??
            Theme.of(context).colorScheme.primary;
        tooltipItems.add(
          LineTooltipItem(
            '${spot.y.toStringAsFixed(2)}€',
            TextStyle(
              color: lineColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        );
      }
    }

    return tooltipItems;
  }

  /// Generalized touched spot indicator generator
  /// Only shows indicators for touchable lines (excludes projections, zero lines, target)
  List<TouchedSpotIndicatorData> _getTouchedSpotIndicator(
      LineChartBarData barData, List<int> spotIndexes) {
    // Don't show indicators for non-touchable lines
    if (!_isLineTouchable(barData)) {
      return spotIndexes.map((index) {
        return const TouchedSpotIndicatorData(
            FlLine(color: Colors.transparent, strokeWidth: 0),
            FlDotData(show: false));
      }).toList();
    }

    return spotIndexes.map((index) {
      final spotX = barData.spots[index].x;
      final touchedDay = _normalizeTouchXToDay(spotX);

      // Validate day range
      if (touchedDay < 1 || touchedDay > 31) {
        return const TouchedSpotIndicatorData(
            FlLine(color: Colors.transparent, strokeWidth: 0),
            FlDotData(show: false));
      }

      final lineColor = barData.gradient?.colors.first ?? Colors.blue;
      return TouchedSpotIndicatorData(
        FlLine(
          color: lineColor,
          strokeWidth: 2,
          dashArray: [4, 4],
        ),
        FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 6,
            color: lineColor,
            strokeWidth: 3,
            strokeColor: Colors.white,
          ),
        ),
      );
    }).toList();
  }
}

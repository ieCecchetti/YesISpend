import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/widgets/in_out_item.dart';
import 'package:monthly_count/widgets/expense_graph.dart';
import 'package:monthly_count/widgets/cathegory_chart.dart';
import 'package:monthly_count/widgets/statistics_view.dart';
import 'package:monthly_count/widgets/day_cost_histogram.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    List<Map<String, dynamic>> analyticsItems = [];
    
    if (settings[Settings.showResumeStats] as bool) {
      analyticsItems.add({
        'title': 'Income & Expenses',
        'icon': Icons.account_balance_wallet,
        'description': 'This panel provides an overview of your financial status. '
            'You can see your total balance, income, and expenses. '
            'The bar below shows the percentage of your income that has been spent.',
        'widget': const IncomeOutcomeWidget(),
      });
    }
    if (settings[Settings.showExpenseLineChart] as bool) {
      analyticsItems.add({
        'title': 'Expense Graph',
        'icon': Icons.show_chart,
        'description': 'This panel displays a graph of your income and expenses over time. '
            'The green line represents your cumulative income, '
            'while the red line represents your cumulative expenses. '
            'The blue line indicates your monthly objective.',
        'widget': ExpenseGraphScreen(),
      });
    }
    if (settings[Settings.showCathegoryPieChart] as bool) {
      analyticsItems.add({
        'title': 'Category Chart',
        'icon': Icons.pie_chart,
        'description': 'This panel shows the distribution of expenses by category. '
            'Each category is represented by a slice of the pie chart. '
            'The legend below shows the total amount and percentage of expenses for each category.',
        'widget': const CategoryPieChart(),
      });
    }
    if (settings[Settings.showMonthlyInstogram] as bool) {
      analyticsItems.add({
        'title': 'Daily Expenses',
        'icon': Icons.bar_chart,
        'description': 'Each bar shows daily expenses, stacked by category using its assigned color.',
        'widget': const DayCostHistogram(),
      });
    }
    if (settings[Settings.showStatistics] as bool) {
      analyticsItems.add({
        'title': 'Statistics',
        'icon': Icons.analytics,
        'description': 'This panel shows the key statistics of your financial status. '
            'You can see your total expenses, income, average daily expense, '
            'projected total expense, largest expense, largest income, '
            'number of transactions, and budget used percentage.',
        'widget': const StatisticsView(),
      });
    }

    if (analyticsItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No analytics enabled',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enable analytics in Settings',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Ensure selected index is valid
    if (_selectedIndex >= analyticsItems.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Column(
        children: [
          // Segmented Control / Tab Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(analyticsItems.length, (index) {
                  final item = analyticsItems[index];
                  final isSelected = index == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildAnalyticsChip(
                      context,
                      title: item['title'] as String,
                      icon: item['icon'] as IconData,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          // Scrollable Analytics Views
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              itemCount: analyticsItems.length,
              itemBuilder: (context, index) {
                final item = analyticsItems[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.white),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        title: Text(
                                          item['title'] as String,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        content: Text(
                                          item['description'] as String,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Close',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: item['widget'] as Widget,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Page Indicator Dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: analyticsItems.length,
              effect: WormEffect(
                activeDotColor: Theme.of(context).colorScheme.primary,
                dotColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChip(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


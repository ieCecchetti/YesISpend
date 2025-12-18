import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/models/transaction.dart';

import 'package:monthly_count/screens/category_screen.dart';
import 'package:monthly_count/screens/settings_screen.dart';
import 'package:monthly_count/screens/create_transaction_screen.dart';
import 'package:monthly_count/screens/filter_screen.dart';
import 'package:monthly_count/screens/analytics_screen.dart';
import 'package:monthly_count/screens/changelog_screen.dart';

import 'package:monthly_count/widgets/transaction_item.dart';
import 'package:monthly_count/widgets/animations/balance_emoji.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/db/db_handler.dart';

class MainViewScreen extends ConsumerStatefulWidget {
  const MainViewScreen({super.key});

  @override
  ConsumerState<MainViewScreen> createState() {
    return _MainViewSampleState();
  }
}

class _MainViewSampleState extends ConsumerState<MainViewScreen> {
  int _selectedIndex = 0;
  int _selectedTab = 0; // 0: All, 1: Shared, 2: Recurrent

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    // Filter transactions by month
    var montlyTransactions = allTransactions.where((transaction) {
      return transaction.date.year == selectedMonth.year &&
          transaction.date.month == selectedMonth.month;
    }).toList();

    // Generate recurrent transactions for future months
    final now = DateTime.now();
    final recurrentTransactions = allTransactions
        .where((t) => t.recurrent && t.originalRecurrentId == t.id)
        .toList();

    for (var recurrentTx in recurrentTransactions) {
      final originalDate = recurrentTx.date;
      var nextDate =
          DateTime(selectedMonth.year, selectedMonth.month, originalDate.day);

      // If the date is in the future (not yet occurred), add it as a preview
      if (nextDate.isAfter(now) &&
          nextDate.year == selectedMonth.year &&
          nextDate.month == selectedMonth.month) {
        // Check if this recurrent transaction for this month already exists
        final exists = allTransactions.any((t) =>
            t.originalRecurrentId == recurrentTx.id &&
            t.date.year == nextDate.year &&
            t.date.month == nextDate.month);

        if (!exists) {
          // Create a preview transaction (not yet occurred)
          final previewTx = Transaction(
            id: '${recurrentTx.id}_preview_${nextDate.millisecondsSinceEpoch}',
            title: recurrentTx.title,
            category_ids: List.from(recurrentTx.category_ids),
            place: recurrentTx.place,
            price: recurrentTx.price,
            date: nextDate,
            splitInfo: recurrentTx.splitInfo,
            recurrent: true,
            originalRecurrentId: recurrentTx.id,
          );
          montlyTransactions.add(previewTx);
        }
      }
    }

    montlyTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Filter by tab
    List filteredTransactions = montlyTransactions;
    if (_selectedTab == 1) {
      // Shared = transactions with split
      filteredTransactions =
          montlyTransactions.where((t) => t.splitInfo != null).toList();
    } else if (_selectedTab == 2) {
      // Recurrent = transactions that are recurrent
      filteredTransactions =
          montlyTransactions.where((t) => t.recurrent).toList();
    }

    final List<Widget> _screens = [
      _buildTransactionsScreen(
          context, filteredTransactions, montlyTransactions),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTransactionScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTransactionsScreen(
      BuildContext context,
      List filteredTransactions, List allMonthlyTransactions) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverAppBar(
              floating: true,
              forceElevated: innerBoxIsScrolled,
              title: const Text('YesISpend'),
              actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilterTransactionScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.category_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryDisplayScreen(),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "Export") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Function will be available in the next patch"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  if (value == "Settings") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  }
                    if (value == "PatchNotes") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangelogScreen(),
                        ),
                      );
                    }
                  if (value == "CleanUp") {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Cleanup'),
                          content: const Text(
                              'Are you sure you want to delete all the data (transactions/categories)? This action cannot be undone.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteAll();
                                ref
                                    .read(transactionsProvider.notifier)
                                    .refreshTransactions();
                                ref
                                    .read(categoriesProvider.notifier)
                                    .refreshCategories();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: "Export",
                      child: Text("Export Excel"),
                    ),
                    const PopupMenuItem(
                      value: "Settings",
                      child: Text("Settings"),
                    ),
                    const PopupMenuItem(
                        value: "PatchNotes",
                        child: Text("Patch Notes"),
                      ),
                      const PopupMenuItem(
                      value: "CleanUp",
                      child: Text("CleanUp data"),
                    ),
                  ];
                },
              ),
            ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left Arrow
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final currentMonth = ref.read(selectedMonthProvider);
                        final newMonth = DateTime(
                          currentMonth.year,
                          currentMonth.month - 1,
                        );
                        ref
                            .read(selectedMonthProvider.notifier)
                            .setSelectedMonth(newMonth);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Centered Month Text with badge style
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      DateFormat('MMM yyyy')
                          .format(ref.watch(selectedMonthProvider)),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Arrow
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final currentMonth = ref.read(selectedMonthProvider);
                        final newMonth = DateTime(
                          currentMonth.year,
                          currentMonth.month + 1,
                        );
                        ref
                            .read(selectedMonthProvider.notifier)
                            .setSelectedMonth(newMonth);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Summary Card (scrollable, can disappear)
          SliverToBoxAdapter(
            child: _buildSummaryCard(context, ref, allMonthlyTransactions),
          ),
          // Tabs (always visible, pinned with top margin)
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _TabsHeaderDelegate(
              child: Container(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'All',
                        0,
                        Icons.list,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'Shared',
                        1,
                        Icons.people,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton(
                        context,
                        'Recurrent',
                        2,
                        Icons.repeat,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      },
      body: filteredTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedTab == 1
                        ? 'No shared transactions in this month'
                        : _selectedTab == 2
                            ? 'No recurrent transactions in this month'
                            : 'Tap the + button to add your first transaction',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : Builder(
              builder: (context) {
                return CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredTransactions[index];
                            // Check if this is a future recurrent transaction (preview)
                            final now = DateTime.now();
                            final today =
                                DateTime(now.year, now.month, now.day);
                            final itemDate = DateTime(
                                item.date.year, item.date.month, item.date.day);
                            // Only show as future if the date is AFTER today (not today itself)
                            final isFutureRecurrent = item.recurrent &&
                                item.originalRecurrentId != null &&
                                itemDate.isAfter(today) &&
                                item.id.contains('_preview_');

                            return Opacity(
                              opacity: isFutureRecurrent ? 0.5 : 1.0,
                              child: Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.horizontal,
                                background: Container(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: const Icon(Icons.edit,
                                      color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Theme.of(context).colorScheme.error,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CreateTransactionScreen(
                                            transaction: item),
                                      ),
                                    );
                                    return false;
                                  }

                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    final confirm =
                                        await showConfirmationDialog(
                                      context: context,
                                      title: "Delete Transaction",
                                      content:
                                          "Are you sure you want to delete this transaction?",
                                    );
                                    if (confirm) {
                                      ref
                                          .read(transactionsProvider.notifier)
                                          .removeTransaction(item);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Transaction removed')),
                                      );
                                    }
                                    return confirm;
                                  }
                                  return false;
                                },
                                child: TransactionItem(item: item),
                              ),
                            );
                          },
                          childCount: filteredTransactions.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTabButton(
      BuildContext context, String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, WidgetRef ref, List montlyTransactions) {
    // Exclude future recurrent transactions from calculations
    final validTransactions = montlyTransactions.where((t) {
      if (t.recurrent &&
          t.originalRecurrentId != null &&
          t.id.contains('_preview_')) {
        return false; // Exclude future preview transactions
      }
      return true;
    }).toList();

    final totalIncome = validTransactions
        .where((t) => t.price > 0)
        .fold(0.0, (sum, t) => sum + t.price);
    final totalExpenses = validTransactions
        .where((t) => t.price < 0)
        .fold(0.0, (sum, t) => sum + t.price.abs());
    final balance = totalIncome - totalExpenses;
    final transactionCount = validTransactions.length;

    // Calculate expense projection
    final selectedMonth = ref.read(selectedMonthProvider);
    final now = DateTime.now();
    final daysPassed = now.day;
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyExpense = daysPassed > 0 ? totalExpenses / daysPassed : 0.0;
    final expenseProjection = dailyExpense * daysInMonth;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 0),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              BalanceEmoji(balance: balance),
            ],
          ),
          const SizedBox(height: 16),
          // First row: Income and Expenses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Income',
                  totalIncome,
                  Icons.trending_up,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Expenses',
                  totalExpenses,
                  Icons.trending_down,
                  Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Expense Projection and Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Expense Projection',
                  expenseProjection,
                  Icons.analytics,
                  Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Transactions',
                  transactionCount.toDouble(),
                  Icons.receipt_long,
                  Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    final isCount = label == 'Transactions';
    final isProjection = label == 'Expense Projection';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCount
                ? value.toInt().toString()
                : isProjection
                    ? '${value.toStringAsFixed(2)}€'
                    : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}€',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // User canceled
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User confirmed
                },
                child: const Text("Remove"),
              ),
            ],
          );
        },
      ) ??
      false; // Default to false if the dialog is dismissed without a choice
}

// Delegate for pinned tabs header
class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double topMargin = 25.0;

  _TabsHeaderDelegate({required this.child});

  @override
  double get minExtent => 56.0 + topMargin; // Height + top margin

  @override
  double get maxExtent => 56.0 + topMargin; // Height + top margin

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // When pinned, maintain 100px top margin
    final topMargin = shrinkOffset > 0 ? this.topMargin : this.topMargin;
    return Container(
      margin: EdgeInsets.only(top: topMargin),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_TabsHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}


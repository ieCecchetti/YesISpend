import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';

import 'package:monthly_count/screens/category_screen.dart';
import 'package:monthly_count/screens/settings_screen.dart';
import 'package:monthly_count/screens/create_transaction_screen.dart';
import 'package:monthly_count/screens/filter_screen.dart';
import 'package:monthly_count/screens/analytics_screen.dart';

import 'package:monthly_count/widgets/transaction_item.dart';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final montlyTransactions = ref.watch(monthlyTransactionsProvider)
      ..sort((a, b) => b.date.compareTo(a.date));

    final List<Widget> _screens = [
      _buildTransactionsScreen(context, montlyTransactions),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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
      BuildContext context, List montlyTransactions) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            floating: true,
            forceElevated: innerBoxIsScrolled,
            title: const Text('Transactions'),
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
                      value: "CleanUp",
                      child: Text("CleanUp data"),
                    ),
                  ];
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () {
                      final newMonth = DateTime(
                        ref
                            .read(monthlyTransactionsProvider.notifier)
                            .selectedMonth
                            .year,
                        ref
                                .read(monthlyTransactionsProvider.notifier)
                                .selectedMonth
                                .month -
                            1,
                      );
                      ref
                          .read(monthlyTransactionsProvider.notifier)
                          .setSelectedMonth(newMonth);
                    },
                  ),
                  // Centered Month Text
                  Text(
                    DateFormat('MMMM yyyy').format(ref
                        .watch(monthlyTransactionsProvider.notifier)
                        .selectedMonth),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // Right Arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: () {
                      final newMonth = DateTime(
                        ref
                            .read(monthlyTransactionsProvider.notifier)
                            .selectedMonth
                            .year,
                        ref
                                .read(monthlyTransactionsProvider.notifier)
                                .selectedMonth
                                .month +
                            1,
                      );
                      ref
                          .read(monthlyTransactionsProvider.notifier)
                          .setSelectedMonth(newMonth);
                    },
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      body: montlyTransactions.isEmpty
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
                    'No transactions yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first transaction',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSummaryCard(context, montlyTransactions),
                const SizedBox(height: 8),
                ...montlyTransactions.map((item) => Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        color: Theme.of(context).colorScheme.secondary,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Theme.of(context).colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateTransactionScreen(transaction: item),
                            ),
                          );
                          return false;
                        }

                        if (direction == DismissDirection.endToStart) {
                          final confirm = await showConfirmationDialog(
                            context: context,
                            title: "Delete Transaction",
                            content:
                                "Are you sure you want to delete this transaction?",
                          );
                          if (confirm) {
                            ref
                                .read(transactionsProvider.notifier)
                                .removeTransaction(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Transaction removed')),
                            );
                          }
                          return confirm;
                        }
                        return false;
                      },
                      child: TransactionItem(item: item),
                    )),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List montlyTransactions) {
    final totalIncome = montlyTransactions
        .where((t) => t.price > 0)
        .fold(0.0, (sum, t) => sum + t.price);
    final totalExpenses = montlyTransactions
        .where((t) => t.price < 0)
        .fold(0.0, (sum, t) => sum + t.price.abs());
    final balance = totalIncome - totalExpenses;
    final transactionCount = montlyTransactions.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Monthly Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Balance',
                  balance,
                  Icons.account_balance_wallet,
                  balance >= 0
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Income',
                  totalIncome,
                  Icons.trending_up,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Expenses',
                  totalExpenses,
                  Icons.trending_down,
                  Theme.of(context).colorScheme.error,
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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:monthly_count/screens/category_screen.dart';
import 'package:monthly_count/screens/settings_screen.dart';
import 'package:monthly_count/screens/create_transaction_screen.dart';
import 'package:monthly_count/screens/filter_screen.dart';

import 'package:monthly_count/widgets/transaction_item.dart';
import 'package:monthly_count/widgets/in_out_item.dart';
import 'package:monthly_count/widgets/expense_graph.dart';
import 'package:monthly_count/widgets/statistics_view.dart';
import 'package:monthly_count/widgets/day_cost_histogram.dart';

import 'package:monthly_count/providers/montly_transactions_provider.dart';
import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/db/db_handler.dart';

class MainViewScreen extends ConsumerStatefulWidget {
  const MainViewScreen({super.key});

  @override
  ConsumerState<MainViewScreen> createState() {
    return _MainViewSampleState();
  }
}

class _MainViewSampleState extends ConsumerState<MainViewScreen> {
  late PageController _pageController;
  int _clickCount = 0;
  double _turns = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final montlyTransactions = ref.watch(monthlyTransactionsProvider)
      ..sort((a, b) => b.date.compareTo(a.date));

    List<Widget> pages = [
      const IncomeOutcomeWidget(),
      ExpenseGraphScreen(
        monthlyObjective: settings[Settings.expenseObjective] as double,
      ),
      const DayCostHistogram(),
      StatisticsView(
        monthlyObjective: settings[Settings.expenseObjective] as double,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _clickCount++;
                  if (_clickCount == 3) {
                    _clickCount = 0;
                    _turns += 2;
                  }
                });
              },
              child: AnimatedRotation(
                turns: _turns,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut, // Smooth rotation curve
                child: const Icon(
                  Icons.attach_money,
                  size: 32, // Adjust icon size if necessary
                ),
              ),
            ),
            const Text('YesISpend'),
          ],
        ),
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
            icon: const Icon(Icons.category),
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
              // Handle the selection
              if (value == "Export") {
                const SnackBar(
                  content: Text("Function will be available in the next patch"),
                  duration: Duration(seconds: 2),
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
                // Show confirmation dialog
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
                            // Cancel the operation
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Call the deleteAll method from DatabaseHelper to drop the database
                            await DatabaseHelper.instance.deleteAll();

                            // Refresh the transactions state
                            ref
                                .read(transactionsProvider.notifier)
                                .refreshTransactions();

                            // Refresh the categories state
                            ref
                                .read(categoriesProvider.notifier)
                                .refreshCategories();

                            // Close the dialog after the operations are done
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            getSliverAppBar(
                context, ref.watch(monthlyTransactionsProvider.notifier)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  color: Colors.blueGrey[900],
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          children: pages,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: pages.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: Colors.white.withOpacity(0.9),
                          dotColor: Colors.blueGrey.shade200,
                          dotHeight: 10,
                          dotWidth: 10,
                          expansionFactor: 3,
                          spacing: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: ListView.builder(
          itemCount: montlyTransactions.length,
          itemBuilder: (context, index) {
            final item = montlyTransactions[index];
            return Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) async {
                final confirm = await showConfirmationDialog(
                    context: context,
                    title: "Delete Transaction",
                    content:
                        "Are you sure you want to delete this transaction?");
                if (confirm) {
                  ref
                      .read(transactionsProvider.notifier)
                      .removeTransaction(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction removed')),
                  );
                } else {
                  ref.read(transactionsProvider.notifier).rebuildItem(item);
                }
              },
              child: TransactionItem(item: item),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the Create Transaction Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTransactionScreen(),
            ),
          );
        }, // Call method to add a new page
        child: const Icon(Icons.add),
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

Widget getSliverAppBar(
    BuildContext context, MonthlyTransactionsNotifier montlyTransactions) {
  return SliverAppBar(
    // pinned: true,
    floating: true,
    forceElevated: true,
    flexibleSpace: FlexibleSpaceBar(
      titlePadding: const EdgeInsets.only(left: 6.0, bottom: 6.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Arrow
          IconButton(
            icon: const Icon(Icons.arrow_left, color: Colors.white),
            onPressed: () {
              final newMonth = DateTime(
                montlyTransactions.selectedMonth.year,
                montlyTransactions.selectedMonth.month - 1,
              );
              montlyTransactions.setSelectedMonth(newMonth);
            },
          ),
          // Centered Month Text
          Text(
            DateFormat('MMMM yyyy').format(montlyTransactions.selectedMonth),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
          // Right Arrow
          IconButton(
            icon: const Icon(Icons.arrow_right, color: Colors.white),
            onPressed: () {
              // increment the month and trigger the UI
              final newMonth = DateTime(
                montlyTransactions.selectedMonth.year,
                montlyTransactions.selectedMonth.month + 1,
              );
              montlyTransactions.setSelectedMonth(newMonth);
            },
          ),
        ],
      ),
      background: Container(
        color: Theme.of(context).primaryColor,
      ),
    ),
  );
}

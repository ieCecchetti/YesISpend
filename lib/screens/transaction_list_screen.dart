import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/widgets/transaction_item.dart';

import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/providers/categories_provider.dart';

enum FilterStyle {
  nameFilter,
  dateFilter,
  transactionTypeFilter,
  categoryFilter,
  amountFilter,
  splitFilter
}

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key, required this.filters});

  final Map<FilterStyle, dynamic> filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var userTransactions = ref.read(transactionsProvider);
    var filteredTransactions = filterTransactions(userTransactions, filters);
    
    // Sort transactions by date (newest first)
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Group transactions by month
    Map<String, List<Transaction>> groupedByMonth = {};
    for (var transaction in filteredTransactions) {
      final monthKey = DateFormat('MMMM yyyy').format(transaction.date);
      if (!groupedByMonth.containsKey(monthKey)) {
        groupedByMonth[monthKey] = [];
      }
      groupedByMonth[monthKey]!.add(transaction);
    }

    // Sort months (newest first)
    final sortedMonths = groupedByMonth.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('YesISpend'),
      ),
      body: Column(
        children: [
          if (filters.isNotEmpty) // Check if any filters are applied
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Filtered transactions: ${filteredTransactions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: filters.entries.map((filter) {
                      String filterValue;

                      // Customize filter value display based on filter type
                      switch (filter.key) {
                        case FilterStyle.nameFilter:
                          filterValue = 'Name: ${filter.value}';
                          break;
                        case FilterStyle.dateFilter:
                          filterValue = 'Date: ${filter.value}';
                          break;
                        case FilterStyle.transactionTypeFilter:
                          filterValue = 'Type: ${filter.value}';
                          break;
                        case FilterStyle.categoryFilter:
                          var categoryTitles = filter.value.map((categoryId) {
                            return ref
                                .read(categoriesProvider)
                                .firstWhere(
                                    (category) => category.id == categoryId)
                                .title;
                          }).toList();
                          filterValue =
                              'Category: ${categoryTitles.join(", ")}';
                          break;
                        case FilterStyle.amountFilter:
                          var range = filter.value as RangeValues;
                          filterValue = 'Amount: ${range.start} - ${range.end}';
                          break;
                        case FilterStyle.splitFilter:
                          filterValue = 'Split: ${filter.value}';
                          break;
                      }

                      return Chip(
                        label: Text(
                          filterValue,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        deleteIcon:
                            const Icon(Icons.close, color: Colors.white),
                        onDeleted: () {},
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          Expanded(
            child: sortedMonths.length == 1
                ? ListView.builder(
              key: ValueKey(filteredTransactions.length),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final item = filteredTransactions[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    ref
                        .read(transactionsProvider.notifier)
                        .removeTransaction(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Transaction dismissed')),
                    );
                  },
                  child: TransactionItem(
                    item: item,
                  ),
                );
              },
                  )
                : ListView.builder(
                    key: ValueKey(filteredTransactions.length),
                    itemCount: sortedMonths.length,
                    itemBuilder: (context, monthIndex) {
                      final monthKey = sortedMonths[monthIndex];
                      final monthTransactions = groupedByMonth[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.5),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  monthKey,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.8),
                                      ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${monthTransactions.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Transactions for this month
                          ...monthTransactions.map((item) {
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                ref
                                    .read(transactionsProvider.notifier)
                                    .removeTransaction(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Transaction dismissed')),
                                );
                              },
                              child: TransactionItem(
                                item: item,
                              ),
                            );
                          }),
                        ],
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}

List<Transaction> filterTransactions(
    List<Transaction> transactions, Map<FilterStyle, dynamic> filters) {
  var filteredTransactions = transactions;

  if (filters.containsKey(FilterStyle.nameFilter)) {
    String query = (filters[FilterStyle.nameFilter] as String).toLowerCase();

    filteredTransactions = filteredTransactions
        .where((transaction) =>
            transaction.title.toLowerCase().contains(query.toLowerCase()) ||
            transaction.place.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  if (filters.containsKey(FilterStyle.dateFilter)) {
    String period = filters[FilterStyle.dateFilter] as String;
    final now = DateTime.now();

    // Calculate the start date based on the selected time period
    DateTime? startDate;
    if (period == '1 Mo') {
      startDate = DateTime(now.year, now.month - 1, now.day);
    } else if (period == '3 Mo') {
      startDate = DateTime(now.year, now.month - 3, now.day);
    } else if (period == '6 Mo') {
      startDate = DateTime(now.year, now.month - 6, now.day);
    } else if (period == '12 Mo') {
      startDate = DateTime(now.year - 1, now.month, now.day);
    }

    // Filter transactions based on the calculated start date
    if (startDate != null) {
      filteredTransactions = filteredTransactions
          .where((transaction) =>
              startDate != null && transaction.date.isAfter(startDate))
          .toList();
    }
  }

  if (filters.containsKey(FilterStyle.transactionTypeFilter)) {
    String type = filters[FilterStyle.transactionTypeFilter] as String;
    if (type == 'Income') {
      filteredTransactions = filteredTransactions
          .where((transaction) => transaction.price >= 0)
          .toList();
    } else if (type == 'Outcome') {
      filteredTransactions = filteredTransactions
          .where((transaction) => transaction.price < 0)
          .toList();
    } else if (type == 'Both') {
      // Do nothing
    } else {
      throw Exception('Invalid transaction type filter');
    }
  }

  if (filters.containsKey(FilterStyle.categoryFilter)) {
    var selectedCategories =
        filters[FilterStyle.categoryFilter] as List<String>;
    filteredTransactions = filteredTransactions
        .where((element) => element.category_ids.any((catId) => selectedCategories.contains(catId)))
        .toList();
  }

  if (filters.containsKey(FilterStyle.amountFilter)) {
    var range = filters[FilterStyle.amountFilter] as RangeValues;
    filteredTransactions = filteredTransactions
        .where((element) =>
            element.price.abs() >= range.start &&
            element.price.abs() <= range.end)
        .toList();
  }

  if (filters.containsKey(FilterStyle.splitFilter)) {
    filteredTransactions = filteredTransactions
        .where((transaction) => transaction.splitInfo != null)
        .toList();
  }


  return filteredTransactions;
}


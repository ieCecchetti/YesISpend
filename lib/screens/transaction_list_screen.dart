import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key, required this.filters});

  final Map<FilterStyle, dynamic> filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var userTransactions = ref.read(transactionsProvider);
    var filteredTransactions = filterTransactions(userTransactions, filters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
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
                      return ref.read(categoriesProvider).firstWhere(
                            (category) => category.id == categoryId
                          ).title;
                    }).toList();
                    filterValue = 'Category: ${categoryTitles.join(", ")}';
                    break;
                  case FilterStyle.amountFilter:
                    var range = filter.value as RangeValues;
                    filterValue = 'Amount: ${range.start} - ${range.end}';
                          break;
                }

                return Chip(
                  label: Text(
                    filterValue,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  deleteIcon: const Icon(Icons.close, color: Colors.white),
                  onDeleted: () {
                    
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    Expanded(
      child: ListView.builder(
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
                const SnackBar(content: Text('Transaction dismissed')),
              );
            },
            child: TransactionItem(
              item: item,
            ),
          );
        },
      ),
    ),
  ],
    ),);
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
        .where((element) => selectedCategories.contains(element.category_id))
        .toList();
  }

  if (filters.containsKey(FilterStyle.amountFilter)) {
    var range = filters[FilterStyle.amountFilter] as RangeValues;
    filteredTransactions = filteredTransactions
      .where((element) =>
        element.price.abs() >= range.start && element.price.abs() <= range.end)
      .toList();
  }

  return filteredTransactions;
}

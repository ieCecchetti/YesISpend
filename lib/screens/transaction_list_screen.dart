import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/widgets/transaction_item.dart';

import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/screens/main_screen.dart'
    show showRecurrenceDeleteDialog, RecurrenceDeleteChoice;

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

    // Build alternating [DateTime, List<Transaction>] groups
    final List<dynamic> rows = [];
    String? lastDayKey;
    for (final tx in filteredTransactions) {
      final dayKey = DateFormat('yyyy-MM-dd').format(tx.date);
      if (dayKey != lastDayKey) {
        rows.add(tx.date);
        rows.add(<Transaction>[]);
        lastDayKey = dayKey;
      }
      (rows.last as List<Transaction>).add(tx);
    }

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
            child: ListView.builder(
              key: ValueKey(rows.length),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];

                if (row is DateTime) return _DayHeader(date: row);

                final group = row as List<Transaction>;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      for (int i = 0; i < group.length; i++) ...[
                        _buildDismissible(context, ref, group[i]),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildDismissible(
    BuildContext context, WidgetRef ref, Transaction item) {
  return Dismissible(
    key: ValueKey(item.id),
    direction: DismissDirection.endToStart,
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (direction) async {
      final isOriginalRecurrent =
          item.recurrent && item.originalRecurrentId == item.id;
      if (isOriginalRecurrent) {
        final choice = await showRecurrenceDeleteDialog(context);
        if (!context.mounted) return false;
        if (choice == null || choice == RecurrenceDeleteChoice.cancel) {
          return false;
        }
        final notifier = ref.read(transactionsProvider.notifier);
        if (choice == RecurrenceDeleteChoice.keepPast) {
          await notifier
              .cancelRecurrenceAndMaintains(item.originalRecurrentId!);
        } else {
          await notifier.cancelAllRecurrences(item.originalRecurrentId!);
        }
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(choice == RecurrenceDeleteChoice.keepPast
                ? 'Recurrence cancelled. Past months kept.'
                : 'All recurring expenses deleted.')));
        return true;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete transaction'),
          content: const Text(
              'Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete')),
          ],
        ),
      );
      if (confirm == true) {
        await ref
            .read(transactionsProvider.notifier)
            .removeTransaction(item);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transaction deleted')));
        }
        return true;
      }
      return false;
    },
    child: TransactionItem(item: item),
  );
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final label = isToday ? 'Today' : DateFormat('EEE d').format(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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


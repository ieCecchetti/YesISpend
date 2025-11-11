import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/screens/transaction_list_screen.dart';
import 'package:monthly_count/widgets/information_title.dart';
import 'package:monthly_count/data/strings.dart';

const List<Widget> transactionType = <Widget>[
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.arrow_upward, size: 18),
      SizedBox(width: 4),
      Text('Income'),
    ],
  ),
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.arrow_downward, size: 18),
      SizedBox(width: 4),
      Text('Outcome'),
    ],
  ),
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.compare_arrows, size: 18),
      SizedBox(width: 4),
      Text('Both'),
    ],
  )
];

List<String> timePeriods = <String>[
  '1 Mo',
  '3 Mo',
  '6 Mo',
  '12 Mo',
];

class FilterTransactionScreen extends ConsumerStatefulWidget {
  const FilterTransactionScreen({super.key});

  @override
  ConsumerState<FilterTransactionScreen> createState() =>
      _FilterTransactionScreenState();
}

class _FilterTransactionScreenState
    extends ConsumerState<FilterTransactionScreen> {
  final List<bool> _selectedTimePeriods = <bool>[false, false, false, false];
  final List<bool> _selectedType = <bool>[false, false, false];
  final List<String> _selectedCategories = <String>[];
  RangeValues _priceRange = const RangeValues(0, 1000);
  final Map<FilterStyle, dynamic> _filters = {};

  @override
  Widget build(BuildContext context) {
    final List<TransactionCategory> categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            Card(
              child: TextField(
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Item or Place contains your text',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filters[FilterStyle.nameFilter] = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Time Period
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InformationTitle(
                      title: 'Select time period',
                      description: timePeriodFilterDescription,
                      lightmode: true,
                      centerText: false,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        timePeriods.length,
                        (index) => FilterChip(
                          label: Text(timePeriods[index]),
                          selected: _selectedTimePeriods[index],
                          onSelected: (selected) {
                            setState(() {
                              for (int i = 0;
                                  i < _selectedTimePeriods.length;
                                  i++) {
                                _selectedTimePeriods[i] = i == index;
                              }
                              _filters[FilterStyle.dateFilter] = timePeriods[
                                  _selectedTimePeriods
                                      .indexWhere((element) => element)];
                            });
                          },
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transaction Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InformationTitle(
                      title: 'Transaction Type',
                      description: transactionTypeFilterDescription,
                      lightmode: true,
                      centerText: false,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        transactionType.length,
                        (index) => FilterChip(
                          label: transactionType[index],
                          selected: _selectedType[index],
                          onSelected: (selected) {
                            setState(() {
                              for (int i = 0; i < _selectedType.length; i++) {
                                _selectedType[i] = i == index;
                              }
                              final selectedRow = transactionType[index] as Row;
                              final textWidget =
                                  selectedRow.children[1] as Text;
                              final selectedText = textWidget.data;
                              _filters[FilterStyle.transactionTypeFilter] =
                                  selectedText;
                            });
                          },
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categories
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InformationTitle(
                      title: 'Transaction Category',
                      description: categoryFilterDescription,
                      lightmode: true,
                      centerText: false,
                    ),
                    const SizedBox(height: 12),
                    if (categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No categories available',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          categories.length,
                          (index) => FilterChip(
                            avatar: CircleAvatar(
                              backgroundColor: categories[index].color,
                              radius: 12,
                              child: Icon(
                                categories[index].icon,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            label: Text(categories[index].title),
                            selected: _selectedCategories
                                .contains(categories[index].id),
                            onSelected: (isSelected) {
                              setState(() {
                                if (isSelected) {
                                  _selectedCategories.add(categories[index].id);
                                } else {
                                  _selectedCategories
                                      .remove(categories[index].id);
                                }
                                _filters[FilterStyle.categoryFilter] =
                                    _selectedCategories;
                              });
                            },
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            checkmarkColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price Range
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InformationTitle(
                      title: 'Price Range',
                      description: priceRangeFilterDescription,
                      lightmode: true,
                      centerText: false,
                    ),
                    const SizedBox(height: 12),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 2000,
                      divisions: 100,
                      labels: RangeLabels(
                        "€${_priceRange.start.toInt()}",
                        "€${_priceRange.end.toInt()}",
                      ),
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      onChanged: (RangeValues values) {
                        setState(() {
                          _priceRange = values;
                          _filters[FilterStyle.amountFilter] = _priceRange;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "€${_priceRange.start.toInt()} - €${_priceRange.end.toInt()}",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Split Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InformationTitle(
                      title: 'Is Splitted',
                      description: isSplittedFilterDescription,
                      lightmode: true,
                      centerText: false,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Yes'),
                          selected: _filters[FilterStyle.splitFilter] == true,
                          onSelected: (selected) {
                            setState(() {
                              _filters[FilterStyle.splitFilter] =
                                  selected ? true : null;
                            });
                          },
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        FilterChip(
                          label: const Text('No'),
                          selected: _filters[FilterStyle.splitFilter] == false,
                          onSelected: (selected) {
                            setState(() {
                              _filters[FilterStyle.splitFilter] =
                                  selected ? false : null;
                            });
                          },
                          selectedColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Search Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionListScreen(
                        filters: _filters,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

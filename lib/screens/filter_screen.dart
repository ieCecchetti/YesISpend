import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/screens/transaction_list_screen.dart';
import 'package:monthly_count/widgets/information_title.dart';
import 'package:monthly_count/data/strings.dart';

const List<Widget> transactionType = <Widget>[
  Row(
    children: [
      Icon(Icons.attach_money),
      Text('Income'),
    ],
  ),
  Row(
    children: [
      Icon(Icons.money_off),
      Text('Outcome'),
    ],
  ),
  Row(
    children: [
      Icon(Icons.compare_arrows),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap Column with SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Item or Place contains your text',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filters[FilterStyle.nameFilter] = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const InformationTitle(
                title: 'Select time period',
                description: timePeriodFilterDescription,
                lightmode: true,
                centerText: false,
              ),
              const SizedBox(height: 12),
              Center(
                child: ToggleButtons(
                  direction: Axis.horizontal,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _selectedTimePeriods.length; i++) {
                        _selectedTimePeriods[i] = i == index;
                      }
                      _filters[FilterStyle.dateFilter] = timePeriods[
                          _selectedTimePeriods
                              .indexWhere((element) => element)];
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Colors.green[700],
                  selectedColor: Colors.white,
                  fillColor: Colors.green[600],
                  color: Colors.green[800],
                  constraints: const BoxConstraints(
                    minHeight: 40.0,
                    minWidth: 70.0,
                  ),
                  isSelected: _selectedTimePeriods,
                  children: timePeriods.map((String timePeriod) {
                    return Text(timePeriod);
                  }).toList(),
                ),
              ),
              const InformationTitle(
                title: 'Transaction Type',
                description: transactionTypeFilterDescription,
                lightmode: true,
                centerText: false,
              ),
              const SizedBox(height: 12),
              Center(
                child: ToggleButtons(
                  direction: Axis.horizontal,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _selectedType.length; i++) {
                        _selectedType[i] = i == index;
                      }
                      final selectedRow = transactionType[index] as Row;
                      final textWidget = selectedRow.children[1] as Text;
                      final selectedText = textWidget.data;
                      _filters[FilterStyle.transactionTypeFilter] =
                          selectedText;
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Colors.green[700],
                  selectedColor: Colors.white,
                  fillColor: Colors.green[600],
                  color: Colors.green[800],
                  constraints: const BoxConstraints(
                    minHeight: 50.0,
                    minWidth: 100.0,
                  ),
                  isSelected: _selectedType,
                  children: transactionType,
                ),
              ),
              const SizedBox(height: 12),
              const InformationTitle(
                title: 'Transaction Category',
                description: categoryFilterDescription,
                lightmode: true,
                centerText: false,
              ),
              const SizedBox(height: 12),
              Center(
                  child: Wrap(
                spacing: 12.0,
                runSpacing: 8.0,
                children: List.generate(
                  categories.length,
                  (index) => FilterChip(
                    label: Text(
                      categories[index].title,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color:
                            _selectedCategories.contains(categories[index].id)
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    selected:
                        _selectedCategories.contains(categories[index].id),
                    selectedColor: Colors.green[600],
                    backgroundColor: Colors.grey[300],
                    elevation: 4.0,
                    shadowColor: Colors.black38,
                    pressElevation: 8.0,
                    side: BorderSide(
                      color: _selectedCategories.contains(categories[index].id)
                          ? Colors.green[700]!
                          : Colors.grey[400]!,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    onSelected: (bool isSelected) {
                      setState(() {
                        if (isSelected) {
                          _selectedCategories.add(categories[index].id);
                        } else {
                          _selectedCategories.remove(categories[index].id);
                        }
                        _filters[FilterStyle.categoryFilter] =
                            _selectedCategories;
                      });
                    },
                  ),
                ),
              )),
              const InformationTitle(
                title: 'Price Range',
                description: priceRangeFilterDescription,
                lightmode: true,
                centerText: false,
              ),
              const SizedBox(height: 12),
              Center(
                  child: Column(
                children: [
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 2000,
                    divisions: 100,
                    labels: RangeLabels(
                      "€${_priceRange.start.toInt()}",
                      "€${_priceRange.end.toInt()}",
                    ),
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey[300],
                    onChanged: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                        _filters[FilterStyle.amountFilter] = _priceRange;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Selected Range: €${_priceRange.start.toInt()} - €${_priceRange.end.toInt()}",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              )),
              const SizedBox(height: 16),
              const InformationTitle(
                title: 'Is Splitted',
                description: isSplittedFilterDescription,
                lightmode: true,
                centerText: false,
              ),
              const SizedBox(height: 12),
              Center(
                child: ToggleButtons(
                  direction: Axis.horizontal,
                  onPressed: (int index) {
                    setState(() {
                      _filters[FilterStyle.splitFilter] = index == 0;
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Colors.green[700],
                  selectedColor: Colors.white,
                  fillColor: Colors.green[600],
                  color: Colors.green[800],
                  constraints: const BoxConstraints(
                    minHeight: 50.0,
                    minWidth: 100.0,
                  ),
                  isSelected: <bool>[
                    _filters[FilterStyle.splitFilter] == true,
                    _filters[FilterStyle.splitFilter] == false,
                  ],
                  children: const <Widget>[
                    Text('Yes'),
                    Text('No'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    child: const Text('Search'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

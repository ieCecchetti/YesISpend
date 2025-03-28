import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/models/split_info.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/widgets/forms/price_textview.dart';
import 'package:monthly_count/providers/categories_provider.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  ConsumerState<CreateTransactionScreen> createState() {
    return _CreateTransactionScreenState();
  }
}

class _CreateTransactionScreenState
    extends ConsumerState<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  String _transactionType = '-';
  final _priceController = TextEditingController();
  TransactionCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  // split controllers
  bool _isSplitWithSomeone = false;
  int? _selectedPercentage;
  final _splitNoteController = TextEditingController();

  double getTransactionAmount(String transactionType, String priceInput) {
    try {
      // Normalize the price input by replacing ',' with '.'
      final normalizedPrice = priceInput.replaceAll(',', '.').trim();

      // Parse the price and apply the transaction type logic
      return transactionType == "-"
          ? -double.parse(normalizedPrice) // Negative for "-"
          : double.parse(normalizedPrice); // Positive for "+"
    } catch (e) {
      throw FormatException('Invalid price format: $priceInput');
    }
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final newTransaction = Transaction(
        id: const Uuid().v4(),
        title: _titleController.text,
        category_id: _selectedCategory!.id,
        place: _placeController.text,
        price: !_isSplitWithSomeone
            ? getTransactionAmount(_transactionType, _priceController.text)
            : (getTransactionAmount(_transactionType, _priceController.text) *
                _selectedPercentage! /
                100),
        date: _selectedDate,
        splitInfo: _isSplitWithSomeone
            ? SplitInfo(
                amount: getTransactionAmount(
                    _transactionType, _priceController.text),
                percentage: _selectedPercentage!,
                notes: _placeController.text,
              )
            : null,
      );

      ref.watch(transactionsProvider.notifier).addTransaction(newTransaction);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction created')),
      );

      // Go back to the previous screen
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryList = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Category Dropdown
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                items: categoryList
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon, color: category.color),
                            const SizedBox(width: 8),
                            Text(category.title),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16.0),

              // Place Field
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: 'Place',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Price Field
              priceTextView(
                selectedType: _transactionType,
                priceController: _priceController,
                onTypeChanged: (String? newValue) {
                  setState(() {
                    _transactionType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16.0),

              Row(
                children: [
                  Text('Split with someone:'),
                  const Spacer(),
                  Checkbox(
                    value: _isSplitWithSomeone,
                    onChanged: (bool? value) {
                      if (_priceController.text.isNotEmpty &&
                          double.tryParse(
                                  _priceController.text.replaceAll(',', '.')) !=
                              null) {
                        setState(() {
                          _isSplitWithSomeone = value ?? false;
                          if (!_isSplitWithSomeone) {
                            _selectedPercentage = null;
                          } else {
                            _selectedPercentage = 50;
                          }
                        });
                      } else if (_transactionType == "+") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Income transactions cannot be splitted')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please enter a valid price first')),
                        );
                      }
                    },
                  ),
                ],
              ),
              if (_isSplitWithSomeone)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Split Percentage:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Slider(
                      value: (_selectedPercentage ?? 50).toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 4,
                      label: '${_selectedPercentage ?? 50}%',
                      onChanged: (double newValue) {
                        setState(() {
                          _selectedPercentage = newValue.toInt();
                        });
                      },
                    ),
                    Text(
                      'Selected: ${_selectedPercentage ?? 50}% - Your Share: ${(getTransactionAmount(_transactionType, _priceController.text) * (_selectedPercentage ?? 50) / 100).toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextFormField(
                        controller: _splitNoteController,
                        decoration: const InputDecoration(
                          labelText: 'Notes about the split',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16.0),

              // Date Pickerr
              Row(
                children: [
                  Text(
                    'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Create Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final Transaction? transaction;
  const CreateTransactionScreen({super.key, this.transaction});

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

  @override
  void initState() {
    super.initState();

    final tx = widget.transaction;
    if (tx != null) {
      _titleController.text = tx.title;
      _placeController.text = tx.place;
      _priceController.text = tx.price.abs().toStringAsFixed(2);
      _transactionType = tx.price < 0 ? '-' : '+';
      _selectedDate = tx.date;
      try {
        _selectedCategory = ref
            .read(categoriesProvider)
            .firstWhere((cat) => cat.id == tx.category_id);
      } catch (_) {
        // should never happen, but in case of a missing category
        print('errors in category id');
        _selectedCategory = null;
      }

      if (tx.splitInfo != null) {
        _isSplitWithSomeone = true;
        _selectedPercentage = tx.splitInfo!.percentage;
        _splitNoteController.text = tx.splitInfo!.notes;
      }
    }
  }

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
        id: widget.transaction?.id ?? const Uuid().v4(),
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
                notes: _splitNoteController.text,
              )
            : null,
      );

      final notifier = ref.read(transactionsProvider.notifier);

      if (widget.transaction != null) {
        notifier.updateTransaction(newTransaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated')),
        );
      } else {
        notifier.addTransaction(newTransaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction created')),
        );
      }
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
        title: Text(widget.transaction == null
            ? 'Create Transaction'
            : 'Edit Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),

            // Category Dropdown
            DropdownButtonFormField<TransactionCategory>(
              value: _selectedCategory,
              items: categoryList
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(category.icon,
                                color: category.color, size: 20),
                          ),
                          const SizedBox(width: 12),
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
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 20.0),

            // Place Field
            TextFormField(
              controller: _placeController,
              decoration: InputDecoration(
                labelText: 'Place',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                return null;
              },
            ),
            const SizedBox(height: 20.0),

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
            const SizedBox(height: 20.0),

            // Split Toggle
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Split with someone',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
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
            ),
            if (_isSplitWithSomeone) ...[
              const SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Split Percentage',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Share:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${(getTransactionAmount(_transactionType, _priceController.text) * (_selectedPercentage ?? 50) / 100).toStringAsFixed(2)} €',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _splitNoteController,
                      decoration: InputDecoration(
                        labelText: 'Notes about the split',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      validator: (value) {
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20.0),

            // Date Picker
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        Text(
                          DateFormat.yMMMd().format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.transaction == null
                      ? 'Create Transaction'
                      : 'Update Transaction',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

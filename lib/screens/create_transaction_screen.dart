import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/models/transaction_category.dart';
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

class _CreateTransactionScreenState extends ConsumerState<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  String _transactionType = '-';
  final _priceController = TextEditingController();
  TransactionCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

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
        price: getTransactionAmount(_transactionType, _priceController.text),
        date: _selectedDate,
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter a place';
                  }
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

              // Date Picker
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

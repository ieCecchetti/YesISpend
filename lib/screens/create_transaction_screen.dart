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
  final bool readOnly;
  const CreateTransactionScreen({
    super.key,
    this.transaction,
    this.readOnly = false,
  });

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
  List<TransactionCategory> _selectedCategories = [];
  DateTime _selectedDate = DateTime.now();
  // split controllers
  bool _isSplitWithSomeone = false;
  int? _selectedPercentage;
  final _splitNoteController = TextEditingController();
  // recurrent
  bool _isRecurrent = false;
  late bool _isReadOnly;

  @override
  void initState() {
    super.initState();
    _isReadOnly = widget.readOnly;

    final tx = widget.transaction;
    if (tx != null) {
      _titleController.text = tx.title;
      _placeController.text = tx.place;
      _priceController.text = tx.price.abs().toStringAsFixed(2);
      _transactionType = tx.price < 0 ? '-' : '+';
      _selectedDate = tx.date;
      try {
        final allCategories = ref.read(categoriesProvider);
        _selectedCategories = allCategories
            .where((cat) => tx.category_ids.contains(cat.id))
            .toList();
      } catch (_) {
        // should never happen, but in case of a missing category
        print('errors in category ids');
        _selectedCategories = [];
      }

      if (tx.splitInfo != null) {
        _isSplitWithSomeone = true;
        _selectedPercentage = tx.splitInfo!.percentage;
        _splitNoteController.text = tx.splitInfo!.notes;
      }
      _isRecurrent = tx.recurrent;
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
    if (_formKey.currentState!.validate() && _selectedCategories.isNotEmpty) {
      final transactionId = widget.transaction?.id ?? const Uuid().v4();
      final newTransaction = Transaction(
        id: transactionId,
        title: _titleController.text,
        category_ids: _selectedCategories.map((cat) => cat.id).toList(),
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
        recurrent: _isRecurrent,
        originalRecurrentId: widget.transaction?.originalRecurrentId ??
            (_isRecurrent ? transactionId : null),
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
        title: Text(
          _isReadOnly
              ? 'Transaction Details'
              : (widget.transaction == null
                  ? 'Create Transaction'
                  : 'Edit Transaction'),
        ),
        actions: [
          if (_isReadOnly)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isReadOnly = false;
                });
              },
              tooltip: 'Edit',
            ),
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Transaction'),
                      content: const Text(
                          'Are you sure you want to delete this transaction? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(transactionsProvider.notifier)
                                .removeTransaction(widget.transaction!);
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context)
                                .pop(); // Close transaction screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Transaction deleted')),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              enabled: !_isReadOnly,
              readOnly: _isReadOnly,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (!_isReadOnly && (value == null || value.isEmpty)) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),

            // Categories Selection
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: categoryList.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : category.color,
                            ),
                            const SizedBox(width: 6),
                            Text(category.title),
                          ],
                        ),
                        onSelected: _isReadOnly
                            ? null
                            : (bool selected) {
                                setState(() {
                                  if (selected) {
                                    if (!_selectedCategories.contains(category)) {
                                      _selectedCategories.add(category);
                                    }
                                  } else {
                                    _selectedCategories.remove(category);
                                  }
                                });
                              },
                        selectedColor: category.color,
                        checkmarkColor: Colors.white,
                        backgroundColor: category.color.withOpacity(0.1),
                        side: BorderSide(
                          color: isSelected
                              ? category.color
                              : category.color.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      );
                    }).toList(),
                  ),
                  if (!_isReadOnly && _selectedCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Please select at least one category',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                ],
              ),
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
              readOnly: _isReadOnly,
            ),
            const SizedBox(height: 20.0),

            // Advanced Section
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: ExpansionTile(
                title: Text(
                  'Advanced',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                leading: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // Place Field
                        TextFormField(
                          controller: _placeController,
                          enabled: !_isReadOnly,
                          readOnly: _isReadOnly,
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
                        // Split Toggle
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
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
                                onChanged: _isReadOnly
                                    ? null
                                    : (bool? value) {
                                        if (_priceController.text.isNotEmpty &&
                                            double.tryParse(_priceController
                                                    .text
                                                    .replaceAll(',', '.')) !=
                                                null) {
                                          setState(() {
                                            _isSplitWithSomeone =
                                                value ?? false;
                                            if (!_isSplitWithSomeone) {
                                              _selectedPercentage = null;
                                            } else {
                                              _selectedPercentage = 50;
                                            }
                                          });
                                        } else if (_transactionType == "+") {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Income transactions cannot be splitted')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Please enter a valid price first')),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Split Percentage',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
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
                                  onChanged: _isReadOnly
                                      ? null
                                      : (double newValue) {
                                          setState(() {
                                            _selectedPercentage =
                                                newValue.toInt();
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Your Share:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        '${(getTransactionAmount(_transactionType, _priceController.text) * (_selectedPercentage ?? 50) / 100).toStringAsFixed(2)} €',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _splitNoteController,
                                  enabled: !_isReadOnly,
                                  readOnly: _isReadOnly,
                                  decoration: InputDecoration(
                                    labelText: 'Notes about the split',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).colorScheme.surface,
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
                        // Recurrent Toggle
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.repeat,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recurrent transaction',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This transaction will repeat every month on the same day',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isRecurrent,
                                onChanged: _isReadOnly
                                    ? null
                                    : (bool? value) {
                                        setState(() {
                                          _isRecurrent = value ?? false;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                  if (!_isReadOnly)
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
            if (!_isReadOnly) ...[
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
          ],
        ),
      ),
    );
  }
}

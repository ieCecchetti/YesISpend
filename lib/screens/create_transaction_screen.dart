import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/models/split_info.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/widgets/forms/price_textview.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/services/image_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:monthly_count/widgets/expand_panel.dart';
import 'package:monthly_count/screens/main_screen.dart'
    show showRecurrenceDeleteDialog, RecurrenceDeleteChoice;
import 'package:monthly_count/services/transaction_share_service.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final bool readOnly;
  final ImportedTransactionDraft? importedDraft;
  const CreateTransactionScreen({
    super.key,
    this.transaction,
    this.readOnly = false,
    this.importedDraft,
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
  bool _specifyEndDate = false;
  DateTime? _selectedEndDate;
  late bool _isReadOnly;
  // images
  List<String> _imagePaths = [];
  List<XFile> _selectedImages = [];

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
      if (tx.recurrent && tx.endDate != null) {
        _specifyEndDate = true;
        _selectedEndDate = tx.endDate;
      }
      _imagePaths = List.from(tx.imagePaths);

      // Verify image paths exist after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyImagePaths();
      });
    }

    // Pre-fill from a shared transaction draft (import flow)
    final draft = widget.importedDraft;
    if (tx == null && draft != null) {
      final dtx = draft.transaction;
      _titleController.text = dtx.title;
      _placeController.text = dtx.place;
      _priceController.text = dtx.price.abs().toStringAsFixed(2);
      _transactionType = dtx.price < 0 ? '-' : '+';
      _selectedDate = dtx.date;
      _selectedImages = List.from(draft.images);
      try {
        final allCategories = ref.read(categoriesProvider);
        _selectedCategories = allCategories
            .where((cat) => dtx.category_ids.contains(cat.id))
            .toList();
      } catch (_) {
        _selectedCategories = [];
      }
      if (dtx.splitInfo != null) {
        _isSplitWithSomeone = true;
        _selectedPercentage = dtx.splitInfo!.percentage;
        _splitNoteController.text = dtx.splitInfo!.notes;
      }
      _isRecurrent = dtx.recurrent;
      if (dtx.recurrent && dtx.endDate != null) {
        _specifyEndDate = true;
        _selectedEndDate = dtx.endDate;
      }
    }
  }

  // Verify that image paths exist and filter out invalid ones
  Future<void> _verifyImagePaths() async {
    if (_imagePaths.isEmpty) return;

    final validPaths = await ImageService.filterValidImagePaths(_imagePaths);
    if (validPaths.length != _imagePaths.length) {
      setState(() {
        _imagePaths = validPaths;
      });

      // Update transaction in database if paths were filtered
      final tx = widget.transaction;
      if (tx != null && validPaths.length != tx.imagePaths.length) {
        final updatedTx = Transaction(
          id: tx.id,
          title: tx.title,
          category_ids: tx.category_ids,
          place: tx.place,
          price: tx.price,
          date: tx.date,
          splitInfo: tx.splitInfo,
          recurrent: tx.recurrent,
          originalRecurrentId: tx.originalRecurrentId,
          endDate: tx.endDate,
          imagePaths: validPaths,
        );
        // Update in database
        ref.read(transactionsProvider.notifier).updateTransaction(updatedTx);
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedCategories.isNotEmpty) {
      final transactionId = widget.transaction?.id ?? const Uuid().v4();
      
      // Get original image paths to compare
      final originalImagePaths = widget.transaction?.imagePaths ?? [];

      // Save new images and get their paths
      final List<String> savedImagePaths =
          List.from(_imagePaths); // Keep existing images
      for (int i = 0; i < _selectedImages.length; i++) {
        try {
          final savedPath = await ImageService.saveImage(
            transactionId,
            _selectedImages[i],
            savedImagePaths.length + i,
          );
          savedImagePaths.add(savedPath);
        } catch (e) {
          print('Error saving image: $e');
        }
      }

      // Delete removed images
      final imagesToDelete = originalImagePaths
          .where((path) => !_imagePaths.contains(path))
          .toList();
      for (final path in imagesToDelete) {
        await ImageService.deleteImage(path);
      }
      
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
        endDate: _isRecurrent && _specifyEndDate && _selectedEndDate != null
            ? _selectedEndDate
            : null,
        imagePaths: savedImagePaths, // Include saved image paths
      );

      final notifier = ref.read(transactionsProvider.notifier);

      if (widget.transaction != null) {
        notifier.updateTransaction(newTransaction);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction updated')),
          );
        }
      } else {
        notifier.addTransaction(newTransaction);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction created')),
          );
        }
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgLight = Theme.of(context).inputDecorationTheme.fillColor ??
        Theme.of(context).colorScheme.surface;

    final categoryList = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReadOnly
              ? 'Transaction Details'
              : (widget.transaction == null
                  ? 'Create' : 'Edit'),
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
          if (_isReadOnly && widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _shareTransaction,
              tooltip: 'Share transaction',
            ),
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final tx = widget.transaction!;
                final isOriginalRecurrent =
                    tx.recurrent && tx.originalRecurrentId == tx.id;
                if (isOriginalRecurrent) {
                  final choice = await showRecurrenceDeleteDialog(context);
                  if (!context.mounted) return;
                  if (choice == null ||
                      choice == RecurrenceDeleteChoice.cancel) {
                    return;
                  }
                  final notifier = ref.read(transactionsProvider.notifier);
                  if (choice == RecurrenceDeleteChoice.keepPast) {
                    await notifier
                        .cancelRecurrenceAndMaintains(tx.originalRecurrentId!);
                  } else {
                    await notifier.cancelAllRecurrences(tx.originalRecurrentId!);
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // Close transaction screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(choice == RecurrenceDeleteChoice.keepPast
                            ? 'Recurrence cancelled. Past months kept.'
                            : 'All recurring expenses deleted.')),
                  );
                  return;
                }
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
                          onPressed: () async {
                            await ref
                                .read(transactionsProvider.notifier)
                                .removeTransaction(widget.transaction!);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
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
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                filled: true,
                fillColor: bgLight,
              ),
              validator: (value) {
                if (!_isReadOnly && (value == null || value.isEmpty)) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20.0),

            // Place Field
            TextFormField(
              controller: _placeController,
              enabled: !_isReadOnly,
              readOnly: _isReadOnly,
              decoration: InputDecoration(
                labelText: 'Place',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                filled: true,
                fillColor: bgLight,
              ),
              validator: (value) {
                return null;
              },
            ),
            const SizedBox(height: 20.0),

            // Date Picker
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: bgLight,
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
                          _isRecurrent ? 'Start date' : 'Date',
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
                    ElevatedButton(
                      onPressed: _pickDate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Change'),
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

            // Categories Selection
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: bgLight,
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
                      return GestureDetector(
                        onTap: _isReadOnly
                            ? null
                            : () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCategories.remove(category);
                                  } else {
                                    if (!_selectedCategories.contains(category)) {
                                      _selectedCategories.add(category);
                                    }
                                  }
                                });
                              },
                        child: Tooltip(
                          message: category.title,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? category.color
                                  : category.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? category.color
                                    : category.color.withOpacity(0.3),
                                width: isSelected ? 3 : 2,
                              ),
                            ),
                            child: Icon(
                              category.icon,
                              size: 24,
                              color: isSelected
                                  ? Colors.white
                                  : category.color,
                            ),
                          ),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Long tap to see the category names',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Receipt Images Section
            if (!_isReadOnly ||
                _imagePaths.isNotEmpty ||
                _selectedImages.isNotEmpty)
              ExpandPanel(
                title: 'Receipt Images',
                icon: Icons.receipt_long,
                initiallyExpanded: _imagePaths.isNotEmpty || _selectedImages.isNotEmpty,
                trailing: _isReadOnly &&
                        (_imagePaths.isNotEmpty ||
                            _selectedImages.isNotEmpty)
                    ? IconButton(
                        onPressed: () => _shareReceipts([
                          ..._imagePaths,
                          ..._selectedImages.map((img) => img.path)
                        ]),
                        icon: Icon(
                          Icons.share,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Share receipts',
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display images - carousel for read-only, grid for edit
                    if (_imagePaths.isNotEmpty || _selectedImages.isNotEmpty)
                      _isReadOnly
                          ? _buildImageCarousel()
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Existing saved images
                                ..._imagePaths.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final path = entry.value;
                                  return _buildImageThumbnail(
                                    path,
                                    index,
                                    isExisting: true,
                                  );
                                }),
                                // New selected images
                                ..._selectedImages.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final image = entry.value;
                                  return _buildImageThumbnail(
                                    image.path,
                                    _imagePaths.length + index,
                                    isExisting: false,
                                  );
                                }),
                                // Add image button
                                if (!_isReadOnly)
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: bgLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                    else if (!_isReadOnly)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: Theme.of(context).colorScheme.primary,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Receipt Images',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20.0),

            // Advanced Section
            ExpandPanel(
              title: 'Advanced',
              icon: Icons.settings_outlined,
              initiallyExpanded: false,
              showBottomBorder: false,
              child: Column(
                children: [
                        // Split Toggle + Percentage (unified card)
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                      color: bgLight,
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Split with someone',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ),
                                  Switch(
                                    value: _isSplitWithSomeone,
                                    onChanged: _isReadOnly
                                        ? null
                                        : (bool? value) {
                                            if (_priceController
                                                    .text.isNotEmpty &&
                                                double.tryParse(_priceController
                                                        .text
                                                        .replaceAll(
                                                            ',', '.')) !=
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
                                            } else if (_transactionType ==
                                                "+") {
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
                              if (_isSplitWithSomeone) ...[
                                const Divider(height: 28),
                                Text(
                                  'Split Percentage',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Slider(
                                  value:
                                      (_selectedPercentage ?? 50).toDouble(),
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
                              fillColor: bgLight,
                                  ),
                                  validator: (value) => null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        // Recurrent Toggle + End Date (unified card)
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                      color: bgLight,
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Recurrent transaction',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Repeats every month on the same day',
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
                                              if (!_isRecurrent) {
                                                _specifyEndDate = false;
                                                _selectedEndDate = null;
                                              }
                                            });
                                          },
                                  ),
                                ],
                              ),
                              if (_isRecurrent) ...[
                                const Divider(height: 28),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Specify end date',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                    Switch(
                                      value: _specifyEndDate,
                                      onChanged: _isReadOnly
                                          ? null
                                          : (bool? value) {
                                              setState(() {
                                                _specifyEndDate =
                                                    value ?? false;
                                                if (_specifyEndDate &&
                                                    _selectedEndDate == null) {
                                                  final now = DateTime.now();
                                                  _selectedEndDate = DateTime(
                                                          now.year,
                                                          now.month + 1,
                                                          1)
                                                      .subtract(const Duration(
                                                          days: 1));
                                                } else if (!_specifyEndDate) {
                                                  _selectedEndDate = null;
                                                }
                                              });
                                            },
                                    ),
                                  ],
                                ),
                                if (_specifyEndDate &&
                                    _selectedEndDate != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const SizedBox(width: 34),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'End date',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            Text(
                                              DateFormat.yMMMd()
                                                  .format(_selectedEndDate!),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!_isReadOnly) ...[
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final picked =
                                                await showDatePicker(
                                              context: context,
                                              initialDate: _selectedEndDate!,
                                              firstDate: _selectedDate,
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setState(() =>
                                                  _selectedEndDate = picked);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                          ),
                                          child: const Text('Change'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ],
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
                  onPressed: () async {
                    await _submitForm();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.transaction == null
                        ? 'Create' : 'Update',
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

  Future<void> _pickImages() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo library'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      print('Starting image picker...');
      final images = await ImageService.pickImages(
        allowMultiple: true,
        source: source,
      );
      print('Picked ${images.length} images');
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        // If we only got one image and user wants multiple, ask if they want to add more
        // (This happens when multi-image picker is not available, e.g., on iOS Simulator)
        if (images.length == 1 && !_isReadOnly && _selectedImages.length == 1) {
          // Show a snackbar suggesting they can add more
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('Image added. Tap the + button to add more.'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Add More',
                  onPressed: _pickImages,
                ),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      print('Error in _pickImages: $e');
      print('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Error picking image.'),
                const SizedBox(height: 4),
                Text(
                  'Please stop the app completely and restart it (not just hot restart).',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Widget _buildImageThumbnail(String imagePath, int index,
      {required bool isExisting}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
        ),
        if (!_isReadOnly)
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isExisting) {
                    _imagePaths.removeAt(index);
                  } else {
                    _selectedImages.removeAt(index - _imagePaths.length);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Build image carousel for read-only mode
  Widget _buildImageCarousel() {
    final allImages = [
      ..._imagePaths,
      ..._selectedImages.map((img) => img.path)
    ];

    if (allImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(allImages[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          size: 48, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareReceipts(List<String> imagePaths) async {
    try {
      if (imagePaths.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No images to share')),
          );
        }
        return;
      }
      final files = imagePaths.map((p) => XFile(p)).toList();
      await Share.shareXFiles(
        files,
        text: 'Receipt images from transaction: ${_titleController.text}',
        subject: 'Receipt Images',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing receipts: $e')),
        );
      }
    }
  }

  Future<void> _shareTransaction() async {
    final tx = widget.transaction;
    if (tx == null) return;

    // If the transaction is split, ask the user to confirm/adjust the percentage
    int? sharePercentage;
    if (tx.splitInfo != null) {
      sharePercentage = await showDialog<int>(
        context: context,
        builder: (ctx) => _SplitPercentageDialog(
          currentPercentage: tx.splitInfo!.percentage,
        ),
      );
      if (sharePercentage == null) return; // user cancelled
    }

    try {
      final allImagePaths = [
        ..._imagePaths,
        ..._selectedImages.map((img) => img.path),
      ];
      final filePath = await TransactionShareService.exportTransaction(
        tx,
        allImagePaths,
        overrideSharePercentage: sharePercentage,
      );
      final text = TransactionShareService.buildShareText(
        tx,
        overridePercentage: sharePercentage,
      );
      await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: 'Transaction: ${tx.title}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing transaction: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Split percentage confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _SplitPercentageDialog extends StatefulWidget {
  final int currentPercentage;
  const _SplitPercentageDialog({required this.currentPercentage});

  @override
  State<_SplitPercentageDialog> createState() =>
      _SplitPercentageDialogState();
}

class _SplitPercentageDialogState extends State<_SplitPercentageDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPercentage.clamp(1, 100);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Split percentage to share'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose the percentage to communicate in the shared message:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Slider(
            value: _selected.toDouble(),
            min: 1,
            max: 100,
            label: '$_selected%',
            onChanged: (v) => setState(() => _selected = v.round()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('User share:',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '$_selected%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Share'),
        ),
      ],
    );
  }
}

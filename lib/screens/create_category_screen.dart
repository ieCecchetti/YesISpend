import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:monthly_count/data/icons.dart';
import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/widgets/icon_picker_dialog.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  final TransactionCategory? category;

  const CreateCategoryScreen({super.key, this.category});

  @override
  ConsumerState<CreateCategoryScreen> createState() {
    return _CreateCategoryScreenState();
  }
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.category != null;
    if (_isEditMode) {
      _titleController = TextEditingController(text: widget.category!.title);
      _selectedIcon = getIconByCodePoint(widget.category!.iconCodePoint);
      _selectedColor = widget.category!.color;
    } else {
      _titleController = TextEditingController();
      _selectedIcon = Icons.category;
      _selectedColor = Colors.blue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _pickIcon() async {
    final selectedIcon = await showDialog<IconData>(
      context: context,
      builder: (BuildContext context) {
        return const IconPickerDialog();
      },
    );
    if (selectedIcon != null) {
      setState(() {
        _selectedIcon = selectedIcon;
      });
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Category' : 'Create Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title Field
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Category Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              ),
            ),
            const SizedBox(height: 16.0),

            // Icon Picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Icon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _selectedIcon,
                            size: 48.0,
                            color: _selectedColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickIcon,
                            icon: const Icon(Icons.palette_outlined),
                            label: const Text('Pick Icon'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Color Picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 56.0,
                          height: 56.0,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickColor,
                            icon: const Icon(Icons.color_lens_outlined),
                            label: const Text('Pick Color'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_isEditMode) {
                      // Update existing category
                      final updatedCategory = TransactionCategory(
                        id: widget.category!.id,
                        title: _titleController.text,
                        iconCodePoint: _selectedIcon.codePoint,
                        color: _selectedColor,
                      );

                      ref
                          .read(categoriesProvider.notifier)
                          .updateCategory(updatedCategory);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category updated')),
                      );
                    } else {
                      // Create new category
                      final newCategory = TransactionCategory(
                        id: const Uuid().v4(),
                        title: _titleController.text,
                        iconCodePoint: _selectedIcon.codePoint,
                        color: _selectedColor,
                      );

                      ref
                          .read(categoriesProvider.notifier)
                          .addCategory(newCategory);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category created')),
                      );
                    }

                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isEditMode ? 'Update Category' : 'Create Category',
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

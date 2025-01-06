import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/widgets/icon_picker_dialog.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  ConsumerState<CreateCategoryScreen> createState() {
    return _CreateCategoryScreenState();
  }
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.blue;

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
        title: const Text('Create Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Category Title',
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

              // Icon Picker
              Row(
                children: [
                  Text(
                    'Selected Icon:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8.0),
                  Icon(
                    _selectedIcon,
                    size: 32.0,
                    color: _selectedColor,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _pickIcon,
                    child: const Text('Pick Icon'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Color Picker
              Row(
                children: [
                  Text(
                    'Selected Color:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _pickColor,
                    child: const Text('Pick Color'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
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

                      Navigator.pop(context, newCategory);
                    }
                  },
                  child: const Text('Create Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

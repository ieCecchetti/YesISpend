import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import 'package:monthly_count/screens/create_category_screen.dart';
import 'package:monthly_count/providers/categories_provider.dart';

class CategoryDisplayScreen extends ConsumerStatefulWidget {
  const CategoryDisplayScreen({super.key});

  @override
  ConsumerState<CategoryDisplayScreen> createState() =>
      _CategoryDisplayScreenState();
}

class _CategoryDisplayScreenState extends ConsumerState<CategoryDisplayScreen> {
  bool isDeletionMode = false;

  void _toggleDeletionMode() {
    setState(() {
      isDeletionMode = !isDeletionMode;

      // Trigger vibration when entering deletion mode
      if (isDeletionMode) {
        Vibration.vibrate(duration: 100);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesList = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCategoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              tooltip: 'Create new category',
            ),
            isDeletionMode
                ? IconButton(
                    onPressed: _toggleDeletionMode,
                    icon: const Icon(Icons.close),
                    tooltip: 'Exit Deletion Mode',
                  )
                : IconButton(
                    onPressed: _toggleDeletionMode,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Enter Deletion Mode',
                  ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Display two boxes per row
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.5, // Adjust the aspect ratio of the boxes
          ),
          itemCount: categoriesList.length,
          itemBuilder: (context, index) {
            final category = categoriesList[index];
            return GestureDetector(
              onLongPress: _toggleDeletionMode,
              child: Stack(
                fit: StackFit.expand, // Ensures the container takes full space
                children: [
                  // Category Item
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: isDeletionMode
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.title,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Delete Button
                  if (isDeletionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(categoriesProvider.notifier)
                              .removeCategory(category);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        ));
  }
}

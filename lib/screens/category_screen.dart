import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import 'package:monthly_count/screens/create_category_screen.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/screens/transaction_list_screen.dart';

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
    final allTransactions = ref.watch(transactionsProvider);

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
                  icon: const Icon(Icons.cancel),
                  tooltip: 'Exit Edit Mode',
                )
              : IconButton(
                  onPressed: _toggleDeletionMode,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Enter Edit Mode',
                ),
        ],
      ),
      body: categoriesList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first category',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
                  childAspectRatio: 1.2,
          ),
          itemCount: categoriesList.length,
          itemBuilder: (context, index) {
            final category = categoriesList[index];
                  final transactionCount = allTransactions
                      .where((t) => t.category_ids.contains(category.id))
                      .length;
            return GestureDetector(
                    onTap: isDeletionMode
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionListScreen(
                                  filters: {
                                    FilterStyle.categoryFilter: [category.id],
                                  },
                                ),
                              ),
                            );
                          },
              onLongPress: _toggleDeletionMode,
              child: Stack(
                      fit: StackFit.expand,
                children: [
                  // Category Item
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDeletionMode
                                  ? Theme.of(context).colorScheme.error
                                  : category.color.withOpacity(0.3),
                              width: isDeletionMode ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDeletionMode
                                    ? Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: isDeletionMode ? 10 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: category.color.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                          category.icon,
                                  size: 32,
                                  color: category.color,
                                ),
                        ),
                              const SizedBox(height: 12),
                        Text(
                          category.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$transactionCount ${transactionCount == 1 ? 'transaction' : 'transactions'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: category.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                        ),
                      ],
                    ),
                  ),
                        // Edit and Delete Buttons (hidden for Uncategorized category)
                        if (isDeletionMode && category.id != '0')
                          Stack(
                            children: [
                              // Edit Button
                              Positioned(
                                top: 8,
                                right: 48,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateCategoryScreen(
                                          category: category,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              // Delete Button
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
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error
                                              .withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                ],
              ),
            );
          },
        ),
            ),
    );
  }
}

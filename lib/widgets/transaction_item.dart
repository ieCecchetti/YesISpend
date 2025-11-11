import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/models/transaction_category.dart';
import 'package:collection/collection.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:intl/intl.dart';

class TransactionItem extends ConsumerWidget {
  const TransactionItem({super.key, required this.item});

  final Transaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    TransactionCategory? category = categories.firstWhereOrNull(
      (element) => element.id == item.category_id,
    );

    category ??= TransactionCategory(
      id: '0',
      title: 'Unknown',
      color: Colors.grey,
      iconCodePoint: Icons.help_outline.codePoint,
    );

    final String formattedDate = DateFormat('dd MMM yyyy').format(item.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Circular background for the icon
          item.splitInfo != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                      // Outer Circle (Indicator of Split)
                    Container(
                        padding: const EdgeInsets.all(10.0),
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
                          size: 28.0,
                          color: category.color,
                      ),
                    ),

                    // Percentage Indicator (Positioned on Top)
                    Positioned(
                        top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                        ),
                        child: Text(
                          "${item.splitInfo!.percentage}%",
                            style: TextStyle(
                              fontSize: 9,
                            fontWeight: FontWeight.bold,
                              color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Return Icon if hasReturned is true
                    if (item.splitInfo!.hasReturned)
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              size: 12.0,
                              color: Colors.white,
                            ),
                        ),
                      ),
                  ],
                )
              : Container(
                    padding: const EdgeInsets.all(10.0),
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
                      size: 28.0,
                      color: category.color,
                  ),
                ),
          const SizedBox(width: 16.0),
          // Title and Date at Place
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                ),
                const SizedBox(height: 4.0),
                Text(
                    '$formattedDate • ${item.place}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ],
            ),
          ),
          // Price
          item.splitInfo != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${item.splitInfo!.share.toStringAsFixed(2)} €',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                    ),
                    Text(
                        'of ${item.splitInfo!.amount.toStringAsFixed(2)} €',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                    ),
                  ],
                )
              : Text(
            '${item.price > 0 ? '+' : ''}${item.price.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: item.price > 0
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.error,
                        ),
                )
        ],
      ),
      ),
    );
  }
}

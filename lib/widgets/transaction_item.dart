import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/screens/create_transaction_screen.dart';
import 'package:monthly_count/widgets/multi_category_icon.dart';
import 'package:intl/intl.dart';

class TransactionItem extends ConsumerWidget {
  const TransactionItem({super.key, required this.item});

  final Transaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String formattedDate = DateFormat('dd MMM yyyy').format(item.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTransactionScreen(
                transaction: item,
                readOnly: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
        children: [
          // Circular background for the icon
              item.splitInfo != null || item.recurrent
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                        // Multi-category icon widget
                        MultiCategoryIcon(
                          categoryIds: item.category_ids,
                          showRecurrent: item.recurrent,
                          showShared: item.splitInfo != null,
                        ),

                        // Percentage Indicator (Positioned on Top) - for split
                        if (item.splitInfo != null)
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
                        if (item.splitInfo != null &&
                            item.splitInfo!.hasReturned)
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
                  : MultiCategoryIcon(
                      categoryIds: item.category_ids,
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
      ),
    );
  }
}

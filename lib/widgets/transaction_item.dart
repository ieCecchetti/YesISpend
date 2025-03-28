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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 1.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white60,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular background for the icon
          item.splitInfo != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Black Circle (Indicator of Split)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: category.color
                            .withOpacity(0.6), // Ensure same opacity effect
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category.icon,
                        size: 32.0,
                        color: Colors.black87,
                      ),
                    ),

                    // Percentage Indicator (Positioned on Top)
                    Positioned(
                      top: 0,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Text(
                          "${item.splitInfo!.percentage}%",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // Return Icon if hasReturned is true
                    if (item.splitInfo!.hasReturned)
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        child: Icon(
                          Icons.refresh,
                          size: 14.0,
                          color: Colors.green, // Green to show money returned
                        ),
                      ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 32.0,
                    color: Colors.black87,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$formattedDate -- ${item.place}',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[700],
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
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow[800],
                      ),
                    ),
                    Text(
                      'of ${item.splitInfo!.amount.toStringAsFixed(2)} €', // Total transaction amount
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                )
              : Text(
            '${item.price > 0 ? '+' : ''}${item.price.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: item.price > 0 ? Colors.green : Colors.red,
            ),
                )
        ],
      ),
    );
  }
}

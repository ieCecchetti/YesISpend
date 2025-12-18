import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import 'package:monthly_count/models/transaction_category.dart';
import 'package:monthly_count/providers/categories_provider.dart';

class MultiCategoryIcon extends ConsumerStatefulWidget {
  const MultiCategoryIcon({
    super.key,
    required this.categoryIds,
    this.size = 48.0,
    this.showRecurrent = false,
    this.showShared = false,
  });

  final List<String> categoryIds;
  final double size;
  final bool showRecurrent;
  final bool showShared;

  @override
  ConsumerState<MultiCategoryIcon> createState() => _MultiCategoryIconState();
}

class _MultiCategoryIconState extends ConsumerState<MultiCategoryIcon>
    with SingleTickerProviderStateMixin {
  Timer? _animationTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Only animate if there are multiple categories
    if (widget.categoryIds.length > 1) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _animationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.categoryIds.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    if (categories.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get all categories for this transaction
    final transactionCategories = widget.categoryIds
        .map((categoryId) => categories.firstWhereOrNull(
              (element) => element.id == categoryId,
            ))
        .whereType<TransactionCategory>()
        .toList();

    if (transactionCategories.isEmpty) {
      // Default grey circle with more_horiz icon if no categories found
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.more_horiz,
          size: widget.size * 0.5,
          color: Colors.white,
        ),
      );
    }

    // Single category - no animation, normal display
    if (transactionCategories.length == 1) {
      return _buildSingleCategory(transactionCategories.first);
    }

    // Multiple categories - overlapping with animation
    return _buildOverlappingCategories(transactionCategories);
  }

  Widget _buildSingleCategory(TransactionCategory category) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: category.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            category.icon,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
          // Show recurrent/shared icons if needed
          if (widget.showRecurrent)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.repeat,
                  size: 12.0,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlappingCategories(List<TransactionCategory> categories) {
    const offset = 12.0; // Margin between overlapping circles

    // Build list with front category last (highest z-index in Stack)
    final orderedCategories = <MapEntry<int, TransactionCategory>>[];
    for (int i = 0; i < categories.length; i++) {
      if (i != _currentIndex) {
        orderedCategories.add(MapEntry(i, categories[i]));
      }
    }
    // Add front category at the end (will be on top)
    orderedCategories.add(MapEntry(_currentIndex, categories[_currentIndex]));

    return SizedBox(
      width: widget.size + (categories.length - 1) * offset,
      height: widget.size,
      child: Stack(
        children: orderedCategories.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isFront = index == _currentIndex;
          
          return Positioned(
            left: index * offset,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: isFront
                    ? [
                        BoxShadow(
                          color: category.color.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    category.icon,
                    size: widget.size * 0.5,
                    color: Colors.white,
                  ),
                  // Show recurrent/shared icons only on front category
                  if (isFront && widget.showRecurrent)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.repeat,
                          size: 12.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


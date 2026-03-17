import 'package:flutter/material.dart';

import 'package:monthly_count/widgets/menu/app_menu.dart';

class YesISpendAppBar extends StatelessWidget implements PreferredSizeWidget {
  const YesISpendAppBar({
    super.key,
    required this.onOpenBuyMeCoffee,
    required this.onOpenSearch,
    required this.onOpenCategories,
  });

  final VoidCallback onOpenBuyMeCoffee;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenCategories;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('YesISpend'),
      actions: _buildActions(
        onOpenBuyMeCoffee: onOpenBuyMeCoffee,
        onOpenSearch: onOpenSearch,
        onOpenCategories: onOpenCategories,
      ),
    );
  }
}

class YesISpendSliverAppBar extends StatelessWidget {
  const YesISpendSliverAppBar({
    super.key,
    required this.forceElevated,
    required this.onOpenBuyMeCoffee,
    required this.onOpenSearch,
    required this.onOpenCategories,
  });

  final bool forceElevated;
  final VoidCallback onOpenBuyMeCoffee;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      forceElevated: forceElevated,
      title: const Text('YesISpend'),
      actions: _buildActions(
        onOpenBuyMeCoffee: onOpenBuyMeCoffee,
        onOpenSearch: onOpenSearch,
        onOpenCategories: onOpenCategories,
      ),
    );
  }
}

List<Widget> _buildActions({
  required VoidCallback onOpenBuyMeCoffee,
  required VoidCallback onOpenSearch,
  required VoidCallback onOpenCategories,
}) {
  return [
    IconButton(
      icon: Image.asset(
        'assets/images/bmac-icon.png',
        width: 22,
        height: 22,
      ),
      tooltip: 'Support on BuyMeACoffee',
      onPressed: onOpenBuyMeCoffee,
    ),
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: onOpenSearch,
    ),
    IconButton(
      icon: const Icon(Icons.apps),
      onPressed: onOpenCategories,
    ),
    const AppMenu(),
  ];
}

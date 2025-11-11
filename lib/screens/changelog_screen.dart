import 'package:flutter/material.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVersionCard(
            context,
            version: '1.0.1',
            date: 'November 2024',
            features: [
              '🎨 Complete UI/UX redesign with modern Material 3 design',
              '🌈 New vibrant color scheme inspired by Revolut app',
              '📊 Redesigned Analytics page with swipeable cards and page indicators',
              '📱 New tab system: All, Shared, and Recurrent transactions',
              '🔄 Recurrent transactions feature - automatically create transactions on the same day each month',
              '👁️ Transaction preview mode - view transactions in read-only mode',
              '✏️ Edit and Delete buttons in transaction details screen',
              '📈 Monthly Summary card on main screen with balance, income, expenses, and transaction count',
              '🏷️ Category list now shows transaction count for each category',
              '📅 Transactions grouped by month in category view',
              '🎯 Improved transaction form with modern design',
              '🎨 Updated icons for transaction type (Income/Outcome)',
              '📱 Fixed app bar titles to always show "YesISpend"',
              '🎨 Updated intro screen with blue and white circles matching app theme',
              '📊 Analytics graphs now exclude future recurrent transactions from calculations',
              '🎨 Improved readability of Income and Expense text in analytics',
              '📱 Better scroll behavior with pinned tabs and collapsible summary',
            ],
          ),
          const SizedBox(height: 16),
          _buildVersionCard(
            context,
            version: '1.0.0',
            date: 'Initial Release',
            features: [
              '✨ Basic transaction management',
              '📊 Category management',
              '📈 Basic analytics and charts',
              '🔍 Transaction filtering',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required String version,
    required String date,
    required List<String> features,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version $version',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}


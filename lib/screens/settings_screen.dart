import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/widgets/settings/budget_checker.dart';
import 'package:monthly_count/widgets/section_card.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var settings = ref.watch(settingsProvider);
    var actualFilters = settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Section
            SectionCard(
              title: 'Expense Budget',
              description: 'Set your monthly expense budget limit',
              child: budgetChecker(context, ref),
            ),
            const SizedBox(height: 4),

            // Analytics Display Section
            SectionCard(
              title: 'Analytics Display',
              description:
                  'Configure which analytics panels to show on the home screen',
              child: Column(
                children: [
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show main screen statistics',
                    'Show the income/outcome resume statistics on the main screen',
                    Settings.showResumeStats,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show income/expenses line chart',
                    'Show the income/expenses line chart on the home screen',
                    Settings.showExpenseLineChart,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show category pie chart',
                    'Show a category pie chart on the home screen',
                    Settings.showCathegoryPieChart,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show expenses daily histogram',
                    'Show expenses daily histogram on the home screen',
                    Settings.showMonthlyInstogram,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show expenses statistics',
                    'Show expenses statistics on the home screen',
                    Settings.showStatistics,
                    actualFilters,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    Settings setting,
    Map<Settings, Object> actualFilters,
  ) {
    return SwitchListTile(
      value: actualFilters[setting] as bool,
      onChanged: (isChecked) {
        ref.read(settingsProvider.notifier).updateFilter(setting, isChecked);
      },
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

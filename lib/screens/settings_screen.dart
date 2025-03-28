import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/widgets/settings/budget_checker.dart';


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
      body: Column(
        children: [
          budgetChecker(context, ref),
          SwitchListTile(
            value: actualFilters[Settings.showResumeStats] as bool,
            onChanged: (isChecked) {
              ref
                  .read(settingsProvider.notifier)
                  .updateFilter(Settings.showResumeStats, isChecked);
            },
            title: Text("Show main screen statistics",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            subtitle: Text(
                "Show the income/outcome resume statistics on the main screen",
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            activeColor: Theme.of(context).colorScheme.tertiary,
            contentPadding: const EdgeInsets.only(left: 34, right: 22),
          ),
          SwitchListTile(
            value: actualFilters[Settings.showExpenseLineChart] as bool,
            onChanged: (isChecked) {
              ref
                  .read(settingsProvider.notifier)
                  .updateFilter(Settings.showExpenseLineChart, isChecked);
            },
            title: Text("Show income/expenses line chart",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            subtitle: Text(
                "Show the income/expenses line chart on the home screen",
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            activeColor: Theme.of(context).colorScheme.tertiary,
            contentPadding: const EdgeInsets.only(left: 34, right: 22),
          ),
          SwitchListTile(
            value: actualFilters[Settings.showCathegoryPieChart] as bool,
            onChanged: (isChecked) {
              ref
                  .read(settingsProvider.notifier)
                  .updateFilter(Settings.showCathegoryPieChart, isChecked);
            },
            title: Text("Show category pie chart",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            subtitle: Text("Show a cathegory pie chart on the home screen",
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            activeColor: Theme.of(context).colorScheme.tertiary,
            contentPadding: const EdgeInsets.only(left: 34, right: 22),
          ),
          SwitchListTile(
            value: actualFilters[Settings.showMonthlyInstogram] as bool,
            onChanged: (isChecked) {
              ref
                  .read(settingsProvider.notifier)
                  .updateFilter(Settings.showMonthlyInstogram, isChecked);
            },
            title: Text("Show expenses daily instogram",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            subtitle: Text("Show expenses daily instogram on the home screen",
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            activeColor: Theme.of(context).colorScheme.tertiary,
            contentPadding: const EdgeInsets.only(left: 34, right: 22),
          ),
          SwitchListTile(
            value: actualFilters[Settings.showStatistics] as bool,
            onChanged: (isChecked) {
              ref
                  .read(settingsProvider.notifier)
                  .updateFilter(Settings.showStatistics, isChecked);
            },
            title: Text("Show expenses statistics",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            subtitle: Text("Show expenses statistics on the home screen",
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground)),
            activeColor: Theme.of(context).colorScheme.tertiary,
            contentPadding: const EdgeInsets.only(left: 34, right: 22),
          ),
        ],
      ),
    );
  }
}



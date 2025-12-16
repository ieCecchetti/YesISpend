import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monthly_count/providers/settings_provider.dart';


Widget budgetChecker(BuildContext context, WidgetRef ref) {
  var budget = ref.watch(settingsProvider)[Settings.expenseObjective] as double;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Monthly Budget",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Set your monthly expense budget",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(
                text: budget.toStringAsFixed(0),
              ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "€",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) {
                double? newBudget = double.tryParse(value);
                if (newBudget != null && newBudget >= 0) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateFilter(Settings.expenseObjective, newBudget);
                }
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Slider(
        value: budget,
        min: 0.0,
        max: 5000.0,
        divisions: 100,
        label: "€${budget.toStringAsFixed(0)}",
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        onChanged: (value) {
          ref
              .read(settingsProvider.notifier)
              .updateFilter(Settings.expenseObjective, value);
        },
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          "€${budget.toStringAsFixed(0)}",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    ],
  );
}

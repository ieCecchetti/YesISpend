import 'package:flutter/material.dart';
import 'package:monthly_count/providers/settings_provider.dart';


Widget budgetChecker(BuildContext context, ref) {
  var budget = ref.watch(settingsProvider)[Settings.expenseObjective];
  return Padding(
    padding: const EdgeInsets.all(30),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
            Text(
            "Expense Budget",
              style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          const Text(
            "Set your monthly expense budget",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Slider(
            value: budget,
            min: 0.0,
            max: 5000.0,
            divisions: 100,
            label: "€${budget.toStringAsFixed(0)}",
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .updateFilter(Settings.expenseObjective, value);
            },
          ),
        ],
      ),
      SizedBox(
        width: 80,
        height: 48,
        child: TextField(
          controller: TextEditingController(
            text: budget.toStringAsFixed(0),
          ),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "€",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            double? newBudget = double.tryParse(value);
            if (newBudget != null) {
              ref
                  .read(settingsProvider.notifier)
                  .updateFilter(Settings.expenseObjective, newBudget);
            }
          },
        ),
      ),
    ],
    ),
  );
}

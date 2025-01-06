import 'package:flutter/material.dart';
import 'package:monthly_count/providers/settings_provider.dart';


Widget budgetChecker(ref, {double budget = 2000}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            "Expense Budget",
            style: TextStyle(fontSize: 16),
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
  );
}

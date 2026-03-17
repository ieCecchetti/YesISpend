import 'package:flutter/material.dart';

Widget priceTextView({
  required String selectedType,
  required TextEditingController priceController,
  required Function(String?) onTypeChanged,
  bool readOnly = false,
}) {
  return Builder(
    builder: (context) {
      final isIncome = selectedType == '+';
      final fillColor = Theme.of(context).inputDecorationTheme.fillColor ??
          Theme.of(context).colorScheme.surface;
      final borderColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      return Row(
        children: [
          // Tap-to-toggle +/− button (no dropdown, no arrow)
          GestureDetector(
            onTap: readOnly
                ? null
                : () => onTypeChanged(isIncome ? '-' : '+'),
            child: Container(
              width: 52,
              height: 56,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: TextFormField(
              controller: priceController,
              enabled: !readOnly,
              readOnly: readOnly,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price',
                suffixText: '€',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                filled: true,
                fillColor: fillColor,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                try {
                  final price =
                      double.parse(value.replaceAll(',', '.'));
                  if (price < 0) return 'Price cannot be negative';
                  return null;
                } catch (_) {
                  return 'Please enter a valid number';
                }
              },
            ),
          ),
        ],
      );
    },
  );
}

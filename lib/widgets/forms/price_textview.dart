import 'package:flutter/material.dart';

Widget priceTextView({
  required String selectedType, 
  required TextEditingController priceController,
  required Function(String?) onTypeChanged,
}) {
  return Builder(
    builder: (context) => Row(
      children: [
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: selectedType,
            onChanged: onTypeChanged,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            selectedItemBuilder: (BuildContext context) {
              return ['-', '+'].map<Widget>((String value) {
                final isIncome = value == '+';
                return Center(
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncome
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                );
              }).toList();
            },
            items: ['-', '+'].map<DropdownMenuItem<String>>((String value) {
              final isIncome = value == '+';
              return DropdownMenuItem<String>(
                value: value,
                child: Center(
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncome
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                ),
              );
            }).toList(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 5,
          child: TextFormField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Price',
              suffixText: '€',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            validator: (value) {
              // Ensure the value is not null or empty
              if (value == null || value.isEmpty) {
                return 'Please enter a price';
              }

              try {
                // Normalize the input by replacing ',' with '.'
                final normalizedValue = value.replaceAll(',', '.');

                // Try parsing the value
                final price = double.parse(normalizedValue);

                // Additional check: Ensure the price is positive or within a valid range
                if (price < 0) {
                  return 'Price cannot be negative';
                }
                return null; // Input is valid
              } catch (e) {
                // Handle invalid input gracefully
                return 'Please enter a valid number';
              }
            },
          ),
        ),
      ],
    ),
  );
}

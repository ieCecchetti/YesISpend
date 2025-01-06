import 'package:flutter/material.dart';

Widget priceTextView({
  required String selectedType, 
  required TextEditingController priceController,
  required Function(String?) onTypeChanged,
}) {
  return Row(
    children: [
      Expanded(
        flex: 1,
        child: DropdownButtonFormField<String>(
          value: selectedType,
          onChanged: onTypeChanged,
          isExpanded:
              true, // Ensures the dropdown expands to match the width of its parent
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            filled: true, // Enables background color
            fillColor: selectedType == '-'
                ? Colors.red[100]
                : Colors.green[100], // Dynamic background
          ),
          items: ['-', '+'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Center(
                // Center the text inside the dropdown item
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: value == '-'
                        ? Colors.red
                        : Colors.green, // Dynamic text color
                  ),
                ),
              ),
            );
          }).toList(),
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.black,
          ),
        ),
      ),
      const SizedBox(width: 8.0), 
      Expanded(
        flex: 5,
        child: TextFormField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price',
            suffixText: '€',
            border: OutlineInputBorder(),
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
  );
}

import 'package:flutter/material.dart';
import 'package:monthly_count/data/icons.dart';

// Helper Widget for Icon Picker
class IconPickerDialog extends StatelessWidget {
  const IconPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick an Icon'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: availableIcons.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context, availableIcons[index]);
              },
              child: Icon(
                availableIcons[index],
                size: 32.0,
                color: Colors.blueGrey,
              ),
            );
          },
        ),
      ),
    );
  }
}

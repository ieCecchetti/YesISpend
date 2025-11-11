import 'package:flutter/material.dart';

class InformationTitle extends StatelessWidget {
  const InformationTitle({
    super.key,
    required this.title,
    required this.description,
    this.lightmode = true,
    this.centerText = true,
  });

  final String title;
  final String description;
  final bool lightmode;
  final bool centerText;

  @override
  Widget build(BuildContext context) {
    final fontColor =
        lightmode ? Colors.black : Theme.of(context).colorScheme.onSurface;
    final backColor =
        lightmode ? Colors.white : Theme.of(context).colorScheme.surface;

    return Row(
      mainAxisAlignment: centerText ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: fontColor)),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: backColor, 
                  title: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fontColor.withOpacity(0.9),
                    ),
                  ),
                  content: Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: fontColor.withOpacity(0.8),
                    ),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: backColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: fontColor.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          color: fontColor,
        ),
      ],
    );
  }
}

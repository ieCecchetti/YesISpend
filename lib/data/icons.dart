
import 'package:flutter/material.dart';

const List<IconData> availableIcons = [
  Icons.child_friendly_rounded,
  Icons.sports,
  Icons.home,
  Icons.car_rental,
  Icons.work,
  Icons.attach_money,
  Icons.fastfood,
  Icons.local_cafe,
  Icons.movie,
  Icons.music_note,
  Icons.school,
  Icons.pets,
  Icons.health_and_safety,
  Icons.travel_explore,
  Icons.local_grocery_store,
  Icons.restaurant,
  Icons.local_hospital,
  Icons.directions_car,
  Icons.business,
  Icons.family_restroom,
  Icons.face_3_outlined,
  Icons.face_outlined,
  Icons.shopping_bag_outlined,
  Icons.store,
  Icons.checkroom,
  Icons.sports_bar_outlined,
  Icons.sports_esports,
  Icons.run_circle_outlined,
  Icons.category,
  Icons.flight,
  Icons.train,
  Icons.celebration,
  Icons.more_horiz,
];

/// Function to get IconData by integer (codePoint)
IconData getIconByCodePoint(int iconCodePoint) {
  for (var icon in availableIcons) {
    if (icon.codePoint == iconCodePoint) {
      return icon;
    }
  }
  throw ArgumentError("No IconData found for codePoint: $iconCodePoint");
}

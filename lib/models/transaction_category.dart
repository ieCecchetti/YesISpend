import 'package:flutter/material.dart';

class TransactionCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  TransactionCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  String toString() {
    return 'TransactionCategory{id: $id, title: $title, icon: $icon, color: $color}';
  }

  // Convert a TransactionCategory into a Map
  Map<String, Object> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon.codePoint,
      'color': color.value,
    };
  }

  // Convert a Map into a TransactionCategory
  factory TransactionCategory.fromMap(Map<String, Object?> map) {
    return TransactionCategory(
      id: map['id'] as String,
      title: map['title'] as String,
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] as int),
    );
  }
}
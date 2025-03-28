import 'package:monthly_count/models/split_info.dart';
import 'dart:convert';

class Transaction {
  String id;
  String title;
  String category_id;
  String place;
  double price;
  DateTime date;
  SplitInfo? splitInfo;

  Transaction({
    required this.id,
    required this.title,
    required this.category_id,
    required this.place,
    required this.price,
    required this.date,
    this.splitInfo,
  });

  @override
  String toString() {
    return 'Transaction{id: $id, title: $title, category_id: $category_id, place: $place, price: $price, date: $date, splittedInfo: $splitInfo}';
  }

  // Convert a Transaction into a Map
  Map<String, Object> toMap() {
    return {
      'id': id,
      'title': title,
      'category_id': category_id,
      'place': place,
      'price': price,
      'date': date.toIso8601String(),
      'splittedInfo': splitInfo != null ? jsonEncode(splitInfo!.toMap()) : '',
    };
  }

  // Convert a Map into a Transaction
  factory Transaction.fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      category_id: map['category_id'] as String,
      place: map['place'] as String,
      price: map['price'] as double,
      date: DateTime.parse(map['date'] as String),
      splitInfo: (map['splittedInfo'] as String?)?.isNotEmpty == true
          ? SplitInfo.fromMap(jsonDecode(map['splittedInfo'] as String))
          : null,
    );
  }

}

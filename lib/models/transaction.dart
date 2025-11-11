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
  bool recurrent;
  String? originalRecurrentId; // ID of the original recurrent transaction

  Transaction({
    required this.id,
    required this.title,
    required this.category_id,
    required this.place,
    required this.price,
    required this.date,
    this.splitInfo,
    this.recurrent = false,
    this.originalRecurrentId,
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
      'recurrent': recurrent ? 1 : 0,
      'originalRecurrentId': originalRecurrentId ?? '',
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
      recurrent: (map['recurrent'] as int? ?? 0) == 1,
      originalRecurrentId:
          (map['originalRecurrentId'] as String?)?.isNotEmpty == true
              ? map['originalRecurrentId'] as String
              : null,
    );
  }

}

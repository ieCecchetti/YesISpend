class Transaction {
  String id;
  String title;
  String category_id;
  String place;
  double price;
  DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.category_id,
    required this.place,
    required this.price,
    required this.date,
  });

  @override
  String toString() {
    return 'Transaction{id: $id, title: $title, category_id: $category_id, place: $place, price: $price, date: $date}';
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
    );
  }
}
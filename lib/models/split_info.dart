class SplitInfo {
  final double amount;
  final int percentage; // 0-25-50-75-100
  final bool hasReturned;
  final String notes;

  SplitInfo(
      {required this.percentage,
      required this.amount,
      this.hasReturned = false,
      required this.notes});

  get share => amount * percentage / 100;

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'percentage': percentage,
      'hasReturned': hasReturned,
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'SplitInfo(amount: $amount, percentage: $percentage%, hasReturned: $hasReturned), notes: $notes';
  }

  factory SplitInfo.fromMap(Map<String, dynamic> map) {
    return SplitInfo(
      amount: map['amount'],
      percentage: map['percentage'],
      hasReturned: map['hasReturned'] ?? false,
      notes: map['notes'] ?? '',
    );
  }
}

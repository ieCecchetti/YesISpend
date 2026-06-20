import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_count/services/field_mapping.dart';
import 'package:monthly_count/services/import_service.dart';

void main() {
  test('deterministic id is stable for the same payment', () {
    final p = ParsedPayment(
        title: 'Coffee', price: -1.40, date: DateTime(2026, 5, 1, 9));
    final a = buildImportTransactions([p]).single.id;
    final b = buildImportTransactions([p]).single.id;
    expect(a, b);
  });

  test('identical rows in one batch get distinct ids (occ 0,1)', () {
    final p = ParsedPayment(
        title: 'Coffee', price: -1.40, date: DateTime(2026, 5, 1, 9));
    final txs = buildImportTransactions([p, p]);
    expect(txs.length, 2);
    expect(txs[0].id, isNot(txs[1].id));
    expect(txs[0].id.endsWith('|0'), isTrue);
    expect(txs[1].id.endsWith('|1'), isTrue);
  });

  test('imported transactions are Uncategorized with negative price kept', () {
    final tx = buildImportTransactions([
      ParsedPayment(title: 'Lunch', price: -10.0, date: DateTime(2026, 5, 2)),
    ]).single;
    expect(tx.category_ids, ['0']);
    expect(tx.price, -10.0);
    expect(tx.place, '');
  });
}

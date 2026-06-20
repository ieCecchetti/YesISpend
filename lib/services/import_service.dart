import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/services/field_mapping.dart';

class ImportResult {
  final int added;
  final int skipped;
  ImportResult(this.added, this.skipped);
}

/// Builds transactions with deterministic ids so re-importing the same file is a
/// no-op (via INSERT OR IGNORE), while genuine duplicates within one file are
/// disambiguated by an occurrence counter.
List<Transaction> buildImportTransactions(List<ParsedPayment> payments) {
  final seen = <String, int>{};
  final result = <Transaction>[];
  for (final p in payments) {
    final sig = '${p.date.toIso8601String()}|${p.price}|${p.title}';
    final occ = seen[sig] ?? 0;
    seen[sig] = occ + 1;
    result.add(Transaction(
      id: 'imp|$sig|$occ',
      title: p.title.isEmpty ? '(no description)' : p.title,
      category_ids: ['0'],
      place: '',
      price: p.price,
      date: p.date,
    ));
  }
  return result;
}

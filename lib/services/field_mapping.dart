import 'package:intl/intl.dart';

import 'package:monthly_count/services/table_detector.dart';

enum AmountMode { single, split }

class FieldMapping {
  AmountMode amountMode;
  String nameHeader;
  String dateHeader;
  String? amountHeader;
  String? entrateHeader;
  String? usciteHeader;
  String dateFormat;
  String decimalSeparator;

  FieldMapping({
    required this.amountMode,
    required this.nameHeader,
    required this.dateHeader,
    this.amountHeader,
    this.entrateHeader,
    this.usciteHeader,
    this.dateFormat = 'dd/MM/yyyy',
    this.decimalSeparator = '.',
  });
}

class ParsedPayment {
  final String title;
  final double price;
  final DateTime date;
  ParsedPayment({required this.title, required this.price, required this.date});
}

class MappingResult {
  final List<ParsedPayment> payments;
  final List<int> invalidRows;
  MappingResult(this.payments, this.invalidRows);
}

DateTime? parseDate(String raw, String pattern) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  try {
    return DateFormat(pattern).parseStrict(s);
  } catch (_) {
    try {
      return DateFormat(pattern).parse(s);
    } catch (_) {
      return null;
    }
  }
}

double? parseAmount(String raw, String decimalSeparator) {
  var s = raw.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (s.isEmpty || s == '-') return null;
  if (decimalSeparator == ',') {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else {
    s = s.replaceAll(',', '');
  }
  return double.tryParse(s);
}

MappingResult applyMapping(DetectedTable table, FieldMapping m) {
  int col(String? header) =>
      header == null ? -1 : table.headers.indexOf(header);
  final nameC = col(m.nameHeader);
  final dateC = col(m.dateHeader);
  final amtC = col(m.amountHeader);
  final entC = col(m.entrateHeader);
  final uscC = col(m.usciteHeader);

  final payments = <ParsedPayment>[];
  final invalid = <int>[];

  for (var i = 0; i < table.dataRows.length; i++) {
    final row = table.dataRows[i];
    String at(int c) => (c >= 0 && c < row.length) ? row[c] : '';

    final date = dateC >= 0 ? parseDate(at(dateC), m.dateFormat) : null;
    double? price;
    if (m.amountMode == AmountMode.single) {
      price = amtC >= 0 ? parseAmount(at(amtC), m.decimalSeparator) : null;
    } else {
      final ent = entC >= 0 ? parseAmount(at(entC), m.decimalSeparator) : null;
      final usc = uscC >= 0 ? parseAmount(at(uscC), m.decimalSeparator) : null;
      price = (ent != null && ent != 0) ? ent : usc;
    }

    if (date == null || price == null) {
      invalid.add(i);
      continue;
    }
    payments.add(ParsedPayment(title: at(nameC), price: price, date: date));
  }
  return MappingResult(payments, invalid);
}

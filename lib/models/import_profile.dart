import 'package:monthly_count/services/field_mapping.dart';

String? _nullIfEmpty(Object? v) {
  final s = v as String?;
  return (s == null || s.isEmpty) ? null : s;
}

class ImportProfile {
  final String id;
  final String name;
  final AmountMode amountMode;
  final String nameHeader;
  final String dateHeader;
  final String? amountHeader;
  final String? entrateHeader;
  final String? usciteHeader;
  final String dateFormat;
  final String decimalSeparator;

  ImportProfile({
    required this.id,
    required this.name,
    required this.amountMode,
    required this.nameHeader,
    required this.dateHeader,
    this.amountHeader,
    this.entrateHeader,
    this.usciteHeader,
    required this.dateFormat,
    required this.decimalSeparator,
  });

  FieldMapping toMapping() => FieldMapping(
        amountMode: amountMode,
        nameHeader: nameHeader,
        dateHeader: dateHeader,
        amountHeader: amountHeader,
        entrateHeader: entrateHeader,
        usciteHeader: usciteHeader,
        dateFormat: dateFormat,
        decimalSeparator: decimalSeparator,
      );

  Map<String, Object> toMap() => {
        'id': id,
        'name': name,
        'amountMode': amountMode.name,
        'nameHeader': nameHeader,
        'dateHeader': dateHeader,
        'amountHeader': amountHeader ?? '',
        'entrateHeader': entrateHeader ?? '',
        'usciteHeader': usciteHeader ?? '',
        'dateFormat': dateFormat,
        'decimalSeparator': decimalSeparator,
      };

  factory ImportProfile.fromMap(Map<String, Object?> m) => ImportProfile(
        id: m['id'] as String,
        name: m['name'] as String,
        amountMode: (m['amountMode'] as String) == 'split'
            ? AmountMode.split
            : AmountMode.single,
        nameHeader: m['nameHeader'] as String,
        dateHeader: m['dateHeader'] as String,
        amountHeader: _nullIfEmpty(m['amountHeader']),
        entrateHeader: _nullIfEmpty(m['entrateHeader']),
        usciteHeader: _nullIfEmpty(m['usciteHeader']),
        dateFormat: m['dateFormat'] as String,
        decimalSeparator: m['decimalSeparator'] as String,
      );
}

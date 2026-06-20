import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_count/services/field_mapping.dart';
import 'package:monthly_count/services/table_detector.dart';

void main() {
  group('parseAmount', () {
    test('comma decimal', () => expect(parseAmount('-10,29', ','), -10.29));
    test('dot decimal', () => expect(parseAmount('-10.29', '.'), -10.29));
    test('thousands comma + dot decimal',
        () => expect(parseAmount('1,234.56', '.'), 1234.56));
    test('thousands dot + comma decimal',
        () => expect(parseAmount('1.234,56', ','), 1234.56));
    test('empty -> null', () => expect(parseAmount('', '.'), isNull));
  });

  group('parseDate', () {
    test('dd/MM/yyyy',
        () => expect(parseDate('28/05/2026', 'dd/MM/yyyy'), DateTime(2026, 5, 28)));
    test('yyyy-MM-dd HH:mm:ss', () {
      expect(parseDate('2026-05-01 15:56:48', 'yyyy-MM-dd HH:mm:ss'),
          DateTime(2026, 5, 1, 15, 56, 48));
    });
    test('garbage -> null', () => expect(parseDate('nope', 'dd/MM/yyyy'), isNull));
  });

  group('applyMapping', () {
    final table = DetectedTable(
      headerRowIndex: 0,
      columnIndexes: [0, 1, 2, 3],
      headers: ['Tipologia', 'Data', 'Entrate', 'Uscite'],
      dataRows: [
        ['POS', '28/05/2026', '', '-10.29'],
        ['Bonifico', '28/05/2026', '8027.94', ''],
        ['Broken', 'not-a-date', '', '5'],
      ],
    );

    test('split columns choose entrate else uscite', () {
      final m = FieldMapping(
        amountMode: AmountMode.split,
        nameHeader: 'Tipologia',
        dateHeader: 'Data',
        entrateHeader: 'Entrate',
        usciteHeader: 'Uscite',
        dateFormat: 'dd/MM/yyyy',
        decimalSeparator: '.',
      );
      final r = applyMapping(table, m);
      expect(r.payments.length, 2);
      expect(r.payments[0].price, -10.29);
      expect(r.payments[0].title, 'POS');
      expect(r.payments[1].price, 8027.94);
      expect(r.invalidRows, [2]); // bad date
    });

    test('split: positive uscite magnitude is forced negative', () {
      // Source CSV has Uscite as a positive magnitude (e.g. "10.29")
      final tablePositiveUsc = DetectedTable(
        headerRowIndex: 0,
        columnIndexes: [0, 1, 2, 3],
        headers: ['Tipologia', 'Data', 'Entrate', 'Uscite'],
        dataRows: [
          ['POS', '28/05/2026', '', '10.29'],   // positive uscita
        ],
      );
      final m = FieldMapping(
        amountMode: AmountMode.split,
        nameHeader: 'Tipologia',
        dateHeader: 'Data',
        entrateHeader: 'Entrate',
        usciteHeader: 'Uscite',
        dateFormat: 'dd/MM/yyyy',
        decimalSeparator: '.',
      );
      final r = applyMapping(tablePositiveUsc, m);
      expect(r.payments.length, 1);
      expect(r.payments[0].price, -10.29); // must be negative
    });

    test('split: negative-looking entrate is normalized positive', () {
      // Source CSV has Entrate as a negative magnitude (e.g. "-8027.94")
      final tableNegativeEnt = DetectedTable(
        headerRowIndex: 0,
        columnIndexes: [0, 1, 2, 3],
        headers: ['Tipologia', 'Data', 'Entrate', 'Uscite'],
        dataRows: [
          ['Bonifico', '28/05/2026', '-8027.94', ''],  // negative entrata
        ],
      );
      final m = FieldMapping(
        amountMode: AmountMode.split,
        nameHeader: 'Tipologia',
        dateHeader: 'Data',
        entrateHeader: 'Entrate',
        usciteHeader: 'Uscite',
        dateFormat: 'dd/MM/yyyy',
        decimalSeparator: '.',
      );
      final r = applyMapping(tableNegativeEnt, m);
      expect(r.payments.length, 1);
      expect(r.payments[0].price, 8027.94); // must be positive
    });

    test('single signed column', () {
      final t2 = DetectedTable(
        headerRowIndex: 0,
        columnIndexes: [0, 1, 2],
        headers: ['Descrizione', 'Data', 'Importo'],
        dataRows: [
          ['Coffee', '2026-05-01 15:56:48', '-1.40'],
        ],
      );
      final m = FieldMapping(
        amountMode: AmountMode.single,
        nameHeader: 'Descrizione',
        dateHeader: 'Data',
        amountHeader: 'Importo',
        dateFormat: 'yyyy-MM-dd HH:mm:ss',
        decimalSeparator: '.',
      );
      final r = applyMapping(t2, m);
      expect(r.payments.single.price, -1.40);
      expect(r.payments.single.title, 'Coffee');
    });
  });
}

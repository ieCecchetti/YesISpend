import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_count/services/bank_file_parser.dart';

void main() {
  group('parseCsv', () {
    test('comma-delimited', () {
      expect(parseCsv('a,b,c\n1,2,3'), [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('semicolon-delimited (auto-detected)', () {
      expect(parseCsv('a;b;c\n1;2;3'), [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('quoted field with delimiter, newline and escaped quote', () {
      const csv = 'name,amt\n"Pay, ""x""\nnext",10';
      expect(parseCsv(csv), [
        ['name', 'amt'],
        ['Pay, "x"\nnext', '10'],
      ]);
    });
  });

  test('parseXlsx reads first sheet rows', () {
    final ex = Excel.createExcel();
    final sheet = ex[ex.getDefaultSheet()!];
    sheet.appendRow([TextCellValue('A'), TextCellValue('B')]);
    sheet.appendRow([TextCellValue('1'), TextCellValue('2')]);
    final bytes = Uint8List.fromList(ex.encode()!);

    expect(parseXlsx(bytes), [
      ['A', 'B'],
      ['1', '2'],
    ]);
  });

  test('parseXlsx formats date cells as yyyy-MM-dd HH:mm:ss', () {
    final ex = Excel.createExcel();
    final sheet = ex[ex.getDefaultSheet()!];
    sheet.appendRow([
      DateTimeCellValue(year: 2026, month: 6, day: 8, hour: 0, minute: 0),
      DoubleCellValue(-63.2),
    ]);
    final bytes = Uint8List.fromList(ex.encode()!);

    final grid = parseXlsx(bytes);
    expect(grid.first[0], '2026-06-08 00:00:00');
    expect(grid.first[1], '-63.2');
  });
}

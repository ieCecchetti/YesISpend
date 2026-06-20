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
}

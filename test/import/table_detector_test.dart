import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_count/services/table_detector.dart';

void main() {
  test('detects clean header at row 0 (Revolut-shaped)', () {
    final grid = [
      ['Tipo', 'Descrizione', 'Importo', 'Valuta'],
      ['Pagamento', 'Coffee', '-1.40', 'EUR'],
      ['Pagamento', 'Lunch', '-10.00', 'EUR'],
    ];
    final t = detectTable(grid);
    expect(t.headerRowIndex, 0);
    expect(t.headers, ['Tipo', 'Descrizione', 'Importo', 'Valuta']);
    expect(t.dataRows.length, 2);
  });

  test('skips noise and empty leading column (Mediobanca-shaped)', () {
    final grid = [
      ['', 'LISTA MOVIMENTI', '', '', '', '', ''],
      ['', 'IBAN:', 'IT87...', '', '', '', ''],
      ['', 'FILTRI', '', '', '', '', ''],
      ['', 'Data contabile', 'Data valuta', 'Tipologia', 'Entrate', 'Uscite', 'Divisa'],
      ['', '28/05/2026', '26/05/2026', 'POS', '', '-10.29', 'EUR'],
      ['', '28/05/2026', '28/05/2026', 'Bonifico', '8027.94', '', 'EUR'],
    ];
    final t = detectTable(grid);
    expect(t.headerRowIndex, 3);
    expect(t.headers, contains('Entrate'));
    expect(t.headers, contains('Uscite'));
    expect(t.columnIndexes.first, 1); // empty col A excluded
    expect(t.dataRows.length, 2);
  });

  test('tableFromHeaderRow re-derives from a chosen header row', () {
    final grid = [
      ['x', 'y'],
      ['Name', 'Amount'],
      ['Coffee', '-1.40'],
    ];
    final t = tableFromHeaderRow(grid, 1);
    expect(t.headers, ['Name', 'Amount']);
    expect(t.dataRows, [
      ['Coffee', '-1.40'],
    ]);
  });
}

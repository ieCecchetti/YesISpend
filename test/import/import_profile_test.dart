import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_count/models/import_profile.dart';
import 'package:monthly_count/services/field_mapping.dart';

void main() {
  test('toMap/fromMap round-trip (split, null single header)', () {
    final p = ImportProfile(
      id: 'p1',
      name: 'Mediobanca',
      amountMode: AmountMode.split,
      nameHeader: 'Tipologia',
      dateHeader: 'Data contabile',
      amountHeader: null,
      entrateHeader: 'Entrate',
      usciteHeader: 'Uscite',
      dateFormat: 'dd/MM/yyyy',
      decimalSeparator: '.',
    );
    final back = ImportProfile.fromMap(p.toMap());
    expect(back.name, 'Mediobanca');
    expect(back.amountMode, AmountMode.split);
    expect(back.entrateHeader, 'Entrate');
    expect(back.amountHeader, isNull);
    expect(back.toMapping().usciteHeader, 'Uscite');
  });
}

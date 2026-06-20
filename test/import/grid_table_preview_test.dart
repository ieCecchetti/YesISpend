import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_count/widgets/grid_table_preview.dart';

void main() {
  testWidgets('renders headers and capped rows', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GridTablePreview(
          headers: const ['Name', 'Amount'],
          rows: const [
            ['Coffee', '-1.40'],
            ['Lunch', '-10.00'],
          ],
        ),
      ),
    ));

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
  });
}

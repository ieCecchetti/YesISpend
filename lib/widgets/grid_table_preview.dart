import 'package:flutter/material.dart';

/// Renders a grid (header + rows) as a horizontally scrollable table with the
/// header row highlighted. Used in the import wizard's preview and review steps.
class GridTablePreview extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final int maxRows;

  const GridTablePreview({
    super.key,
    required this.headers,
    required this.rows,
    this.maxRows = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = rows.take(maxRows).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        columns: [
          for (final h in headers)
            DataColumn(
              label: Text(h,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
        rows: [
          for (final r in shown)
            DataRow(cells: [
              for (var i = 0; i < headers.length; i++)
                DataCell(Text(i < r.length ? r[i] : '')),
            ]),
        ],
      ),
    );
  }
}

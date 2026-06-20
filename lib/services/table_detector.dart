import 'dart:math';

class DetectedTable {
  final int headerRowIndex;
  final List<int> columnIndexes;
  final List<String> headers;
  final List<List<String>> dataRows;

  DetectedTable({
    required this.headerRowIndex,
    required this.columnIndexes,
    required this.headers,
    required this.dataRows,
  });
}

int _nonEmpty(List<String> row) =>
    row.where((c) => c.trim().isNotEmpty).length;

/// Finds the real transaction table inside a noisy grid: the largest block of
/// consecutive rows whose populated-cell count is near the maximum; the first
/// row of that block is the header.
DetectedTable detectTable(List<List<String>> grid) {
  if (grid.isEmpty) return tableFromHeaderRow(grid, 0);
  final counts = grid.map(_nonEmpty).toList();
  final maxCols = counts.reduce(max);
  if (maxCols < 3) return tableFromHeaderRow(grid, 0);

  final threshold = max(3, maxCols - 1);
  var bestStart = 0, bestLen = 0, curStart = -1, curLen = 0;
  for (var i = 0; i < grid.length; i++) {
    if (counts[i] >= threshold) {
      if (curStart < 0) {
        curStart = i;
        curLen = 0;
      }
      curLen++;
      if (curLen > bestLen) {
        bestLen = curLen;
        bestStart = curStart;
      }
    } else {
      curStart = -1;
      curLen = 0;
    }
  }
  return _build(grid, bestStart, bestStart + bestLen);
}

/// Re-derives a [DetectedTable] using [headerIndex] as the header row,
/// data running to the end of the grid. Used by the manual override.
DetectedTable tableFromHeaderRow(List<List<String>> grid, int headerIndex) {
  if (grid.isEmpty) {
    return DetectedTable(
        headerRowIndex: 0, columnIndexes: [], headers: [], dataRows: []);
  }
  return _build(grid, headerIndex, grid.length);
}

DetectedTable _build(List<List<String>> grid, int headerIdx, int end) {
  final headerRow = grid[headerIdx];
  final cols = <int>[
    for (var i = 0; i < headerRow.length; i++)
      if (headerRow[i].trim().isNotEmpty) i
  ];
  final headers = [for (final c in cols) headerRow[c].trim()];
  final data = <List<String>>[];
  for (var r = headerIdx + 1; r < end; r++) {
    data.add([
      for (final c in cols) c < grid[r].length ? grid[r][c].trim() : '',
    ]);
  }
  return DetectedTable(
    headerRowIndex: headerIdx,
    columnIndexes: cols,
    headers: headers,
    dataRows: data,
  );
}

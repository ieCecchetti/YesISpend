import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Parses a bank file into a rectangular grid of trimmed cell strings.
List<List<String>> parseGrid(Uint8List bytes, String extension) {
  final ext = extension.toLowerCase().replaceAll('.', '');
  if (ext == 'csv') return parseCsv(utf8.decode(bytes, allowMalformed: true));
  if (ext == 'xlsx') return parseXlsx(bytes);
  throw UnsupportedError('Unsupported file type: .$ext');
}

/// Minimal RFC-4180 CSV parser. Delimiter auto-detected (',' or ';') from the
/// first non-empty line. Handles "-quoted fields with embedded delimiters,
/// newlines and escaped "" quotes. Cells are trimmed.
List<List<String>> parseCsv(String text) {
  final firstLine = text
      .split(RegExp(r'\r?\n'))
      .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final delim =
      firstLine.split(';').length > firstLine.split(',').length ? ';' : ',';

  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == delim) {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n') {
      row.add(field.toString());
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else if (c == '\r') {
      // ignore
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows.map((r) => r.map((c) => c.trim()).toList()).toList();
}

/// Reads the first sheet of an XLSX into a grid of trimmed strings.
List<List<String>> parseXlsx(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return [];
  final sheet = excel.tables[excel.tables.keys.first]!;
  return sheet.rows
      .map((row) => row.map(_cellToString).toList())
      .toList();
}

String _cellToString(Data? cell) {
  final v = cell?.value;
  if (v == null) return '';
  if (v is TextCellValue) return v.value.toString().trim();
  if (v is IntCellValue) return v.value.toString();
  if (v is DoubleCellValue) return v.value.toString();
  if (v is BoolCellValue) return v.value.toString();
  if (v is DateCellValue) return _fmtDate(v.asDateTimeLocal());
  if (v is DateTimeCellValue) return _fmtDate(v.asDateTimeLocal());
  return v.toString().trim();
}

/// Formats a date cell as `yyyy-MM-dd HH:mm:ss` so it parses with that pattern.
String _fmtDate(DateTime d) {
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${p2(d.month)}-${p2(d.day)} '
      '${p2(d.hour)}:${p2(d.minute)}:${p2(d.second)}';
}

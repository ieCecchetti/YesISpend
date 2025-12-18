import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/models/split_info.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CsvService {
  // Export transactions to CSV with tabs for each month
  static Future<String?> exportTransactionsToCsv(
    List<Transaction> transactions,
    WidgetRef ref,
  ) async {
    try {
      if (transactions.isEmpty) {
        return null;
      }

      // Get categories for category names
      final categories = ref.read(categoriesProvider);

      // Group transactions by month
      final Map<String, List<Transaction>> transactionsByMonth = {};
      for (var transaction in transactions) {
        final monthKey = DateFormat('MM/yyyy').format(transaction.date);
        transactionsByMonth.putIfAbsent(monthKey, () => []).add(transaction);
      }

      // Sort months
      final sortedMonths = transactionsByMonth.keys.toList()
        ..sort((a, b) {
          final dateA = DateFormat('MM/yyyy').parse(a);
          final dateB = DateFormat('MM/yyyy').parse(b);
          return dateB.compareTo(dateA); // Newest first
        });

      // Build CSV content
      final StringBuffer csvContent = StringBuffer();

      // CSV Header
      csvContent.writeln(
          'ID,Title,Categories,Place,Price,Date,Is Recurrent,Original Recurrent ID,Split Amount,Split Percentage,Split Notes');

      // Add transactions grouped by month
      for (var monthKey in sortedMonths) {
        final monthTransactions = transactionsByMonth[monthKey]!;
        
        // Sort transactions by date (newest first)
        monthTransactions.sort((a, b) => b.date.compareTo(a.date));

        // Add month header as comment
        csvContent.writeln('# Month: $monthKey');

        // Add transactions for this month
        for (var transaction in monthTransactions) {
          // Get category names
          final categoryNames = transaction.category_ids
              .map((catId) {
                final category = categories.firstWhere(
                  (cat) => cat.id == catId,
                  orElse: () => categories.firstWhere(
                    (cat) => cat.id == '0',
                    orElse: () => throw Exception('Category not found'),
                  ),
                );
                return category.title;
              })
              .join('; ');

          // Build CSV row
          final row = [
            transaction.id,
            _escapeCsvField(transaction.title),
            _escapeCsvField(categoryNames),
            _escapeCsvField(transaction.place),
            transaction.price.toStringAsFixed(2),
            DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.date),
            transaction.recurrent ? '1' : '0',
            transaction.originalRecurrentId ?? '',
            transaction.splitInfo != null
                ? transaction.splitInfo!.amount.toStringAsFixed(2)
                : '',
            transaction.splitInfo != null
                ? transaction.splitInfo!.percentage.toString()
                : '',
            transaction.splitInfo != null
                ? _escapeCsvField(transaction.splitInfo!.notes)
                : '',
          ];

          csvContent.writeln(row.join(','));
        }

        // Add empty line between months
        csvContent.writeln('');
      }

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/transactions_export_$timestamp.csv');

      // Write to file
      await file.writeAsString(csvContent.toString());

      return file.path;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  // Import transactions from CSV
  static Future<List<Transaction>> importTransactionsFromCsv(
    String filePath,
    WidgetRef ref,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final content = await file.readAsString();
      final lines = content.split('\n');

      final List<Transaction> transactions = [];
      final categories = ref.read(categoriesProvider);

      // Skip header and process lines
      for (var line in lines) {
        line = line.trim();
        
        // Skip empty lines and comments
        if (line.isEmpty || line.startsWith('#')) {
          continue;
        }

        // Skip header line
        if (line.startsWith('ID,Title,Categories')) {
          continue;
        }

        // Parse CSV row
        final fields = _parseCsvLine(line);
        if (fields.length < 6) {
          continue; // Skip invalid rows
        }

        try {
          // Map category names to IDs
          final categoryNames = fields[2].split(';').map((s) => s.trim()).toList();
          final categoryIds = categoryNames.map((name) {
            final category = categories.firstWhere(
              (cat) => cat.title == name,
              orElse: () => categories.firstWhere(
                (cat) => cat.id == '0',
                orElse: () => throw Exception('Category not found: $name'),
              ),
            );
            return category.id;
          }).toList();

          // Parse date
          DateTime date;
          try {
            date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(fields[5]);
          } catch (e) {
            // Try alternative format
            date = DateFormat('yyyy-MM-dd').parse(fields[5]);
          }

          // Parse split info if present
          SplitInfo? splitInfo;
          if (fields.length >= 11 &&
              fields[8].isNotEmpty &&
              fields[9].isNotEmpty) {
            splitInfo = SplitInfo(
              amount: double.parse(fields[8]),
              percentage: int.parse(fields[9]),
              notes: fields.length > 10 ? fields[10] : '',
            );
          }

          final transaction = Transaction(
            id: fields[0],
            title: fields[1],
            category_ids: categoryIds,
            place: fields[3],
            price: double.parse(fields[4]),
            date: date,
            splitInfo: splitInfo,
            recurrent: fields.length > 6 && fields[6] == '1',
            originalRecurrentId:
                fields.length > 7 && fields[7].isNotEmpty ? fields[7] : null,
          );

          transactions.add(transaction);
        } catch (e) {
          print('Error parsing transaction row: $e');
          continue;
        }
      }

      return transactions;
    } catch (e) {
      print('Error importing from CSV: $e');
      rethrow;
    }
  }

  // Escape CSV field (handle commas and quotes)
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Parse CSV line handling quoted fields
  static List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          currentField.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }

    // Add last field
    fields.add(currentField.toString());

    return fields;
  }
}


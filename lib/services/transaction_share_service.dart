import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:monthly_count/models/split_info.dart';
import 'package:monthly_count/models/transaction.dart';
import 'package:monthly_count/models/transaction_category.dart';

/// Returned by [TransactionShareService.importFromJsonFile] for the
/// single-transaction share flow (draft opened in CreateTransactionScreen).
class ImportedTransactionDraft {
  final Transaction transaction;
  final List<XFile> images;

  ImportedTransactionDraft({
    required this.transaction,
    required this.images,
  });
}

/// Returned by [TransactionShareService.fromYiSj] for the bulk export/import
/// flow (all transactions + categories).
class YiSjImportResult {
  final List<Transaction> transactions;
  final List<TransactionCategory> categories;

  YiSjImportResult({required this.transactions, required this.categories});
}

class TransactionShareService {
  static const String fileExtension = 'yisj';

  // ─────────────────────────────────────────────────────────────────────────
  // BULK EXPORT — all transactions + categories → .yisj file
  // ─────────────────────────────────────────────────────────────────────────

  /// Serializes [transactions] and [categories] to a .yisj file.
  /// Transactions are grouped by month (key: "yyyy-MM").
  /// Images are embedded as base64 strings.
  static Future<String> toYiSj(
    List<Transaction> transactions,
    List<TransactionCategory> categories,
  ) async {
    // Group by "yyyy-MM"
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(await _txToMap(tx));
    }

    // Sort month keys chronologically
    final sortedKeys = grouped.keys.toList()..sort();
    final orderedGrouped = <String, dynamic>{
      for (final k in sortedKeys) k: grouped[k],
    };

    final payload = {
      'transactions': orderedGrouped,
      'categories': categories
          .where((c) => c.id != '0')
          .map((c) => c.toMap())
          .toList(),
      'metadata': {
        'ultimo_aggiornamento': DateTime.now().toUtc().toIso8601String(),
        'version': '1.0',
      },
    };

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file =
        File('${dir.path}/yesispend_export_$ts.$fileExtension');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BULK IMPORT — .yisj file → transactions + categories
  // ─────────────────────────────────────────────────────────────────────────

  /// Parses a .yisj file exported by [toYiSj].
  /// Images are saved permanently to the app's documents directory.
  static Future<YiSjImportResult> fromYiSj(String filePath) async {
    final content = await File(filePath).readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;

    // ── Categories ──────────────────────────────────────────────────────────
    final categoriesRaw = decoded['categories'] as List? ?? [];
    final categories = categoriesRaw.map((raw) {
      final m = raw as Map<String, dynamic>;
      return TransactionCategory(
        id: m['id'] as String,
        title: m['title'] as String,
        iconCodePoint: (m['iconCodePoint'] as num).toInt(),
        color: Color((m['color'] as num).toInt()),
      );
    }).toList();

    // ── Transactions ────────────────────────────────────────────────────────
    final txByMonth =
        decoded['transactions'] as Map<String, dynamic>? ?? {};
    final transactions = <Transaction>[];

    for (final monthEntry in txByMonth.entries) {
      final list = monthEntry.value as List;
      for (final raw in list) {
        final m = raw as Map<String, dynamic>;
        final savedImagePaths =
            await _decodeAndSaveImages(m['id'] as String, m['images']);

        final splitInfoMap = m['splitInfo'];
        final splitInfo = splitInfoMap is Map<String, dynamic>
            ? SplitInfo.fromMap(splitInfoMap)
            : null;

        final categoryIds = ((m['category_ids'] as List?) ?? [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();

        transactions.add(Transaction(
          id: m['id'] as String,
          title: m['title'] as String,
          category_ids: categoryIds,
          place: m['place'] as String,
          price: (m['price'] as num).toDouble(),
          date: DateTime.parse(m['date'] as String),
          splitInfo: splitInfo,
          recurrent: m['recurrent'] == true,
          originalRecurrentId: m['originalRecurrentId'] as String?,
          endDate: m['endDate'] != null
              ? DateTime.tryParse(m['endDate'] as String)
              : null,
          imagePaths: savedImagePaths,
        ));
      }
    }

    return YiSjImportResult(
        transactions: transactions, categories: categories);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SINGLE-TRANSACTION SHARE (existing feature, unchanged contract)
  // ─────────────────────────────────────────────────────────────────────────

  /// Serializes one [transaction] + its images to a .yisj file.
  static Future<String> exportTransaction(
    Transaction transaction,
    List<String> imagePaths, {
    int? overrideSharePercentage,
  }) async {
    final txMap = await _txToMap(transaction);
    // Optionally override the split percentage communicated in the file
    if (overrideSharePercentage != null && txMap['splitInfo'] != null) {
      (txMap['splitInfo'] as Map<String, dynamic>)['percentage'] =
          overrideSharePercentage;
    }

    final payload = {'transaction': txMap, 'images': txMap.remove('images')};

    final dir = await getTemporaryDirectory();
    final safeTitle = transaction.title
        .replaceAll(RegExp(r'[^\w]'), '_')
        .toLowerCase();
    final file = File(
        '${dir.path}/${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  /// Human-readable WhatsApp message body for a single transaction.
  static String buildShareText(
    Transaction transaction, {
    int? overridePercentage,
  }) {
    final sign = transaction.price < 0 ? '−' : '+';
    final absPrice = transaction.price.abs().toStringAsFixed(2);
    final date = DateFormat('dd MMM yyyy').format(transaction.date);
    final pct = overridePercentage ?? transaction.splitInfo?.percentage;
    final lines = <String>[
      '📤 YesISpend Transaction',
      'Title: ${transaction.title}',
      'Amount: $sign€$absPrice',
      'Date: $date',
      if (transaction.place.isNotEmpty) 'Place: ${transaction.place}',
      if (transaction.splitInfo != null && pct != null)
        'Split: $pct% '
            '(total €${transaction.splitInfo!.amount.abs().toStringAsFixed(2)})',
      '',
      '👆 Tap the attachment to import it in YesISpend.',
    ];
    return lines.join('\n');
  }

  /// Parses a single-transaction .yisj file into an [ImportedTransactionDraft].
  static Future<ImportedTransactionDraft> importFromJsonFile(
      String filePath) async {
    final decoded =
        jsonDecode(await File(filePath).readAsString()) as Map<String, dynamic>;
    final txMap = (decoded['transaction'] as Map<String, dynamic>? ?? {});
    final images = await _decodeImages(decoded['images']);

    final splitInfoMap = txMap['splitInfo'];
    final splitInfo = splitInfoMap is Map<String, dynamic>
        ? SplitInfo.fromMap(splitInfoMap)
        : null;

    final categoryIds = ((txMap['category_ids'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    final transaction = Transaction(
      id: txMap['id']?.toString() ?? '',
      title: txMap['title']?.toString() ?? '',
      category_ids: categoryIds,
      place: txMap['place']?.toString() ?? '',
      price: (txMap['price'] as num?)?.toDouble() ?? 0,
      date:
          DateTime.tryParse(txMap['date']?.toString() ?? '') ?? DateTime.now(),
      splitInfo: splitInfo,
      recurrent: txMap['recurrent'] == true,
      originalRecurrentId: txMap['originalRecurrentId']?.toString(),
      endDate: DateTime.tryParse(txMap['endDate']?.toString() ?? ''),
      imagePaths: const [],
    );

    return ImportedTransactionDraft(transaction: transaction, images: images);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Converts a [Transaction] to a JSON-serialisable map (images embedded).
  static Future<Map<String, dynamic>> _txToMap(Transaction tx) async {
    final images = <Map<String, String>>[];
    for (final path in tx.imagePaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      try {
        images.add({
          'fileName': p.basename(path),
          'base64': base64Encode(await file.readAsBytes()),
        });
      } catch (_) {}
    }
    return {
      'id': tx.id,
      'title': tx.title,
      'category_ids': tx.category_ids,
      'place': tx.place,
      'price': tx.price,
      'date': tx.date.toIso8601String(),
      'recurrent': tx.recurrent,
      'originalRecurrentId': tx.originalRecurrentId,
      'endDate': tx.endDate?.toIso8601String(),
      'splitInfo': tx.splitInfo?.toMap(),
      'images': images,
    };
  }

  /// Decodes base64 images to temp [XFile]s (used in single-tx import flow).
  static Future<List<XFile>> _decodeImages(dynamic imagesRaw) async {
    if (imagesRaw is! List) return [];
    final dir = await getTemporaryDirectory();
    final out = <XFile>[];
    var i = 0;
    for (final item in imagesRaw) {
      if (item is! Map) continue;
      final fileName = item['fileName']?.toString();
      final b64 = item['base64']?.toString();
      if (fileName == null || b64 == null) continue;
      try {
        final bytes = base64Decode(b64);
        final outFile = File(
            '${dir.path}/imported_${DateTime.now().millisecondsSinceEpoch}_${i}_${p.basename(fileName)}');
        await outFile.writeAsBytes(bytes, flush: true);
        out.add(XFile(outFile.path));
        i++;
      } catch (_) {}
    }
    return out;
  }

  /// Decodes base64 images and saves them permanently to the app documents dir.
  static Future<List<String>> _decodeAndSaveImages(
    String transactionId,
    dynamic imagesRaw,
  ) async {
    if (imagesRaw is! List || imagesRaw.isEmpty) return [];
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docsDir.path}/transaction_images');
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    final savedPaths = <String>[];
    var i = 0;
    for (final item in imagesRaw) {
      if (item is! Map) continue;
      final fileName = item['fileName']?.toString();
      final b64 = item['base64']?.toString();
      if (fileName == null || b64 == null) continue;
      try {
        final bytes = base64Decode(b64);
        final outFile = File(
            '${imagesDir.path}/${transactionId}_$i${p.extension(fileName)}');
        await outFile.writeAsBytes(bytes, flush: true);
        savedPaths.add(outFile.path);
        i++;
      } catch (_) {}
    }
    return savedPaths;
  }
}

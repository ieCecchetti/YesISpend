import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:monthly_count/services/transaction_share_service.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/screens/settings_screen.dart';
import 'package:monthly_count/screens/changelog_screen.dart';
import 'package:monthly_count/db/db_handler.dart';

class AppMenu extends ConsumerWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
      ),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
          tooltip: 'Show menu',
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            _exportToYiSj(context, ref);
          },
          child: const Row(
            children: [
              Icon(Icons.download),
              SizedBox(width: 8),
              Text("Export .yisj"),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            _importFromYiSj(context, ref);
          },
          child: const Row(
            children: [
              Icon(Icons.upload),
              SizedBox(width: 8),
              Text("Import .yisj"),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
          child: const Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text("Settings"),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangelogScreen(),
              ),
            );
          },
          child: const Row(
            children: [
              Icon(Icons.description),
              SizedBox(width: 8),
              Text("Patch Notes"),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Cleanup'),
                  content: const Text(
                      'Are you sure you want to delete all the data (transactions/categories)? This action cannot be undone.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteAll();
                        ref
                            .read(transactionsProvider.notifier)
                            .refreshTransactions();
                        ref
                            .read(categoriesProvider.notifier)
                            .refreshCategories();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text("Clean Up", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loadingDialog(String message) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      );

  Future<void> _exportToYiSj(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    final allTransactions = ref.read(transactionsProvider);
    if (allTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _loadingDialog('Exporting transactions...'),
    );

    try {
      final categories = ref.read(categoriesProvider);
      final filePath = await TransactionShareService.toYiSj(
          allTransactions, categories);

      if (context.mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'YesISpend Backup',
        subject: 'YesISpend Backup',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }

  Future<void> _importFromYiSj(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yisj'],
    );
    if (result == null || result.files.single.path == null) return;
    final filePath = result.files.single.path!;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _loadingDialog('Importing transactions...'),
    );

    YiSjImportResult importResult;
    try {
      importResult = await TransactionShareService.fromYiSj(filePath);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
      return;
    }

    if (context.mounted) Navigator.of(context).pop();

    if (importResult.transactions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions found in file')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Transactions'),
        content: Text(
          'Import ${importResult.transactions.length} transactions'
          '${importResult.categories.isNotEmpty ? ' and ${importResult.categories.length} categories' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Import categories first
    final catNotifier = ref.read(categoriesProvider.notifier);
    final existingCats = ref.read(categoriesProvider);
    for (final cat in importResult.categories) {
      final alreadyById = existingCats.any((c) => c.id == cat.id);
      final alreadyByName = existingCats.any(
          (c) => c.title.toLowerCase() == cat.title.toLowerCase());
      if (!alreadyById && !alreadyByName) catNotifier.addCategory(cat);
    }

    // Import transactions
    final txNotifier = ref.read(transactionsProvider.notifier);
    for (final tx in importResult.transactions) {
      txNotifier.addTransaction(tx);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Imported ${importResult.transactions.length} transactions'),
        ),
      );
    }
  }
}


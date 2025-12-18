import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:monthly_count/services/csv_service.dart';
import 'package:monthly_count/models/transaction.dart';
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
            _exportToCsv(context, ref);
          },
          child: const Row(
            children: [
              Icon(Icons.download),
              SizedBox(width: 8),
              Text("Export CSV"),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            _importFromCsv(context, ref);
          },
          child: const Row(
            children: [
              Icon(Icons.upload),
              SizedBox(width: 8),
              Text("Import CSV"),
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

  // Export transactions to CSV
  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    
    try {
      final allTransactions = ref.read(transactionsProvider);
      if (allTransactions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions to export')),
          );
        }
        return;
      }

      // Show loading dialog with proper background
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting transactions...'),
                ],
              ),
            ),
          ),
        ),
      );

      String? filePath;
      try {
        filePath = await CsvService.exportTransactionsToCsv(
          allTransactions,
          ref,
        );
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error exporting: $e')),
          );
        }
        return;
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (filePath != null) {
        try {
          // Share the file
          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Transactions Export',
            subject: 'Transactions Export',
          );
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transactions exported successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // If sharing fails, still show success message with file location
          if (context.mounted) {
            // Extract just the filename for cleaner display
            final fileName = filePath.split('/').last;
            final directory = filePath.substring(0, filePath.lastIndexOf('/'));
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File exported successfully: $fileName'),
                    const SizedBox(height: 4),
                    Text(
                      'Location: $directory',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () async {
                    await _openFileLocation(directory);
                  },
                ),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to export transactions')),
          );
        }
      }
    } catch (e) {
      // Ensure dialog is closed
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }

  // Import transactions from CSV
  Future<void> _importFromCsv(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final filePath = result.files.single.path!;

      // Show loading dialog with proper background
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Importing transactions...'),
                ],
              ),
            ),
          ),
        ),
      );

      List<Transaction> transactions;
      try {
        transactions = await CsvService.importTransactionsFromCsv(
          filePath,
          ref,
        );
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing: $e')),
          );
        }
        return;
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (transactions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions found in CSV file')),
          );
        }
        return;
      }

      // Show confirmation dialog
      if (!context.mounted) return;
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Transactions'),
          content: Text(
              'Do you want to import ${transactions.length} transactions?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (shouldImport == true) {
        // Import transactions
        final notifier = ref.read(transactionsProvider.notifier);
        for (var transaction in transactions) {
          notifier.addTransaction(transaction);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Imported ${transactions.length} transactions')),
          );
        }
      }
    } catch (e) {
      // Ensure dialog is closed
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing: $e')),
        );
      }
    }
  }

  // Open file location in system file manager
  Future<void> _openFileLocation(String directoryPath) async {
    try {
      if (Platform.isMacOS) {
        // On macOS, open the directory in Finder
        // This works even for iOS Simulator paths
        await Process.run('open', [directoryPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directoryPath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [directoryPath]);
      } else if (Platform.isAndroid) {
        // For Android, try to open with file manager intent
        // This would require platform-specific code or a package
        print('Opening directory on Android: $directoryPath');
      } else if (Platform.isIOS) {
        // For iOS Simulator on macOS, try to open Finder
        // The simulator path should be accessible from macOS
        await Process.run('open', [directoryPath]);
      }
    } catch (e) {
      // If opening fails, try alternative methods
      try {
        if (Platform.isMacOS || Platform.isIOS) {
          // Try opening parent directory if direct path fails
          final parentDir = directoryPath.substring(0, directoryPath.lastIndexOf('/'));
          await Process.run('open', [parentDir]);
        }
      } catch (e2) {
        print('Error opening file location: $e, $e2');
        // Last resort: copy to clipboard
        try {
          await Clipboard.setData(ClipboardData(text: directoryPath));
          print('Path copied to clipboard as fallback: $directoryPath');
        } catch (clipboardError) {
          print('Error copying to clipboard: $clipboardError');
        }
      }
    }
  }
}


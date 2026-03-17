import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/screens/opening_screen.dart';
import 'package:monthly_count/screens/create_transaction_screen.dart';
import 'package:monthly_count/services/transaction_share_service.dart';


final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const ProviderScope(child: MontlyCount()));
  });
}

class MontlyCount extends StatefulWidget {
  const MontlyCount({super.key});

  @override
  State<MontlyCount> createState() => _MontlyCountState();
}

class _MontlyCountState extends State<MontlyCount> {
  static const _fileChannel = MethodChannel('com.yesispend/file_handler');

  @override
  void initState() {
    super.initState();
    // Listen for files opened while the app is already running.
    _fileChannel.setMethodCallHandler((call) async {
      if (call.method == 'handleFile') {
        final path = call.arguments as String?;
        if (path != null) _openImportScreen(path);
      }
    });
    // Check for a file that triggered a cold launch.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final path =
          await _fileChannel.invokeMethod<String>('getPendingFile');
      if (path != null && mounted) _openImportScreen(path);
    });
  }

  Future<void> _openImportScreen(String filePath) async {
    try {
      final draft =
          await TransactionShareService.importFromJsonFile(filePath);
      final ctx = _navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => CreateTransactionScreen(importedDraft: draft),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedTheme = ref.watch(selectedThemeDataProvider);
        final themeMode = ref.watch(selectedThemeModeProvider);

        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'YesISpend',
          theme: selectedTheme,
          darkTheme: selectedTheme,
          themeMode: themeMode,
          home: const OpeningScreen(),
        );
      },
    );
  }
}

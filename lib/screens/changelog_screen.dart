import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  List<Map<String, dynamic>> _versions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      final String data = await rootBundle.loadString('assets/patchdetails.md');
      final List<Map<String, dynamic>> versions = _parseMarkdownChangelog(data);
      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load changelog: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseMarkdownChangelog(String data) {
    final List<Map<String, dynamic>> versions = [];
    final List<String> lines = data.split('\n');

    String? currentVersion;
    String? currentDate;
    List<String> currentFeatures = [];

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String trimmedLine = line.trim();

      // Check for version header: ## Version X.X.X - Date
      if (trimmedLine.startsWith('## Version ')) {
        // Save previous version if exists
        if (currentVersion != null && currentDate != null) {
          versions.add({
            'version': currentVersion,
            'date': currentDate,
            'features': List<String>.from(currentFeatures),
          });
        }

        // Parse version and date
        // Format: ## Version 1.0.1 - November 2024
        final versionMatch = RegExp(r'## Version (.+?)(?:\s*-\s*(.+))?$')
            .firstMatch(trimmedLine);
        if (versionMatch != null) {
          currentVersion = versionMatch.group(1)?.trim() ?? '';
          currentDate = versionMatch.group(2)?.trim() ?? 'Unknown';
          currentFeatures.clear();
        }
      }
      // Check for list items (features): - or * at start
      else if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
        if (currentVersion != null) {
          // Remove the list marker and trim
          final feature = trimmedLine.substring(2).trim();
          if (feature.isNotEmpty) {
            currentFeatures.add(feature);
          }
        }
      }
      // Ignore empty lines and other markdown elements
    }

    // Save last version if exists
    if (currentVersion != null && currentDate != null) {
      versions.add({
        'version': currentVersion,
        'date': currentDate,
        'features': List<String>.from(currentFeatures),
      });
    }

    return versions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _versions.isEmpty
                  ? Center(
                      child: Text(
                        'No changelog data available',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ..._versions.map((version) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildVersionCard(
                                context,
                                version: version['version'] as String,
                                date: version['date'] as String,
                                features: version['features'] as List<String>,
                              ),
                            )),
                      ],
                    ),
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required String version,
    required String date,
    required List<String> features,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version $version',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

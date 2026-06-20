import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:monthly_count/models/import_profile.dart';
import 'package:monthly_count/providers/import_profiles_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/services/bank_file_parser.dart';
import 'package:monthly_count/services/field_mapping.dart';
import 'package:monthly_count/services/import_service.dart';
import 'package:monthly_count/services/table_detector.dart';
import 'package:monthly_count/widgets/grid_table_preview.dart';
import 'package:monthly_count/widgets/info_card.dart';
import 'package:monthly_count/widgets/section_card.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  List<List<String>>? _grid;
  DetectedTable? _table;
  String? _error;

  // mapping form state
  AmountMode _amountMode = AmountMode.split;
  String? _nameHeader, _dateHeader, _amountHeader, _entrateHeader, _usciteHeader;
  String _decimalSeparator = '.';
  final _profileNameCtrl = TextEditingController();
  final _dateFormatCtrl = TextEditingController(text: 'dd/MM/yyyy');

  ImportResult? _result;

  @override
  void dispose() {
    _profileNameCtrl.dispose();
    _dateFormatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        withData: true,
      );
      if (res == null) return;
      final file = res.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _error = 'Could not read file bytes.');
        return;
      }
      final grid = parseGrid(bytes, file.extension ?? '');
      setState(() {
        _grid = grid;
        _table = detectTable(grid);
        _result = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to read file: $e');
    }
  }

  void _setHeaderRow(int index) {
    final grid = _grid;
    if (grid == null) return;
    setState(() {
      _table = tableFromHeaderRow(grid, index);
      final headers = _table!.headers;
      String? pick(String? h) => (h != null && headers.contains(h)) ? h : null;
      _nameHeader = pick(_nameHeader);
      _dateHeader = pick(_dateHeader);
      _amountHeader = pick(_amountHeader);
      _entrateHeader = pick(_entrateHeader);
      _usciteHeader = pick(_usciteHeader);
    });
  }

  void _applyProfile(ImportProfile p) {
    final headers = _table?.headers ?? const [];
    String? pick(String? h) => (h != null && headers.contains(h)) ? h : null;
    setState(() {
      _amountMode = p.amountMode;
      _nameHeader = pick(p.nameHeader);
      _dateHeader = pick(p.dateHeader);
      _amountHeader = pick(p.amountHeader);
      _entrateHeader = pick(p.entrateHeader);
      _usciteHeader = pick(p.usciteHeader);
      _dateFormatCtrl.text = p.dateFormat;
      _decimalSeparator = p.decimalSeparator;
      _profileNameCtrl.text = p.name;
    });
  }

  FieldMapping? _currentMapping() {
    if (_nameHeader == null || _dateHeader == null) {
      return null;
    }
    if (_amountMode == AmountMode.single && _amountHeader == null) {
      return null;
    }
    if (_amountMode == AmountMode.split &&
        _entrateHeader == null &&
        _usciteHeader == null) {
      return null;
    }
    return FieldMapping(
      amountMode: _amountMode,
      nameHeader: _nameHeader!,
      dateHeader: _dateHeader!,
      amountHeader: _amountHeader,
      entrateHeader: _entrateHeader,
      usciteHeader: _usciteHeader,
      dateFormat: _dateFormatCtrl.text,
      decimalSeparator: _decimalSeparator,
    );
  }

  Future<void> _saveProfile() async {
    final m = _currentMapping();
    final name = _profileNameCtrl.text.trim();
    if (m == null || name.isEmpty) return;
    final profiles = ref.read(importProfilesProvider);
    final existing =
        profiles.where((p) => p.name == name).cast<ImportProfile?>().firstOrNull;
    final profile = ImportProfile(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      amountMode: m.amountMode,
      nameHeader: m.nameHeader,
      dateHeader: m.dateHeader,
      amountHeader: m.amountHeader,
      entrateHeader: m.entrateHeader,
      usciteHeader: m.usciteHeader,
      dateFormat: m.dateFormat,
      decimalSeparator: m.decimalSeparator,
    );
    final notifier = ref.read(importProfilesProvider.notifier);
    if (existing == null) {
      await notifier.addProfile(profile);
    } else {
      await notifier.updateProfile(profile);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved profile "$name"')));
    }
  }

  Future<void> _runImport() async {
    final table = _table;
    final m = _currentMapping();
    if (table == null || m == null) return;
    final parsed = applyMapping(table, m);
    final txs = buildImportTransactions(parsed.payments);
    final result = await ref
        .read(transactionsProvider.notifier)
        .addImportedTransactions(txs);
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final table = _table;
    final profiles = ref.watch(importProfilesProvider);
    final mapping = _currentMapping();
    final preview =
        (table != null && mapping != null) ? applyMapping(table, mapping) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Import payments')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: '1. File',
              description: 'Pick a CSV or XLSX bank statement',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose file'),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (table != null) ...[
              SectionCard(
                title: '2. Detected table',
                description:
                    'Header row ${table.headerRowIndex + 1}. Adjust if wrong.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Header row: '),
                        IconButton(
                          onPressed: table.headerRowIndex > 0
                              ? () => _setHeaderRow(table.headerRowIndex - 1)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('${table.headerRowIndex + 1}'),
                        IconButton(
                          onPressed: (_grid != null &&
                                  table.headerRowIndex < _grid!.length - 1)
                              ? () => _setHeaderRow(table.headerRowIndex + 1)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    GridTablePreview(
                        headers: table.headers, rows: table.dataRows),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SectionCard(
                title: '3. Mapping',
                description: 'Use a saved profile or map columns manually',
                child: _buildMappingForm(table, profiles),
              ),
              const SizedBox(height: 4),
              if (preview != null)
                SectionCard(
                  title: '4. Review & import',
                  description:
                      '${preview.payments.length} payments, ${preview.invalidRows.length} skipped (unparseable)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridTablePreview(
                        headers: const ['Date', 'Title', 'Amount'],
                        rows: [
                          for (final p in preview.payments)
                            [
                              p.date.toIso8601String().split('T').first,
                              p.title,
                              p.price.toStringAsFixed(2),
                            ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _runImport,
                        icon: const Icon(Icons.download_done),
                        label: const Text('Import'),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 12),
                        InfoCard(
                          title: 'Import complete',
                          items: [
                            '${_result!.added} added',
                            '${_result!.skipped} skipped (already present)',
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMappingForm(DetectedTable table, List<ImportProfile> profiles) {
    final headerItems = [
      for (final h in table.headers)
        DropdownMenuItem(value: h, child: Text(h)),
    ];
    Widget headerDropdown(
            String label, String? value, ValueChanged<String?> onChanged) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            items: headerItems,
            onChanged: onChanged,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Use existing profile',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in profiles)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (id) {
                final p = profiles.firstWhere((x) => x.id == id);
                _applyProfile(p);
              },
            ),
          ),
        SegmentedButton<AmountMode>(
          segments: const [
            ButtonSegment(
                value: AmountMode.split, label: Text('Entrate / Uscite')),
            ButtonSegment(
                value: AmountMode.single, label: Text('Single amount')),
          ],
          selected: {_amountMode},
          onSelectionChanged: (s) => setState(() => _amountMode = s.first),
        ),
        const SizedBox(height: 12),
        headerDropdown(
            'Name', _nameHeader, (v) => setState(() => _nameHeader = v)),
        headerDropdown(
            'Date', _dateHeader, (v) => setState(() => _dateHeader = v)),
        if (_amountMode == AmountMode.single)
          headerDropdown('Amount (signed)', _amountHeader,
              (v) => setState(() => _amountHeader = v))
        else ...[
          headerDropdown('Entrate (income)', _entrateHeader,
              (v) => setState(() => _entrateHeader = v)),
          headerDropdown('Uscite (expense)', _usciteHeader,
              (v) => setState(() => _usciteHeader = v)),
        ],
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dateFormatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date format',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                initialValue: _decimalSeparator,
                decoration: const InputDecoration(
                  labelText: 'Decimal',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '.', child: Text('. (dot)')),
                  DropdownMenuItem(value: ',', child: Text(', (comma)')),
                ],
                onChanged: (v) =>
                    setState(() => _decimalSeparator = v ?? '.'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _profileNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Save as profile (name)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}

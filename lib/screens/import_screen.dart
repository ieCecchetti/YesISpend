import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:monthly_count/models/import_profile.dart';
import 'package:monthly_count/providers/categories_provider.dart';
import 'package:monthly_count/providers/import_profiles_provider.dart';
import 'package:monthly_count/providers/transactions_provider.dart';
import 'package:monthly_count/services/bank_file_parser.dart';
import 'package:monthly_count/services/transaction_share_service.dart';
import 'package:monthly_count/services/field_mapping.dart';
import 'package:monthly_count/services/import_service.dart';
import 'package:monthly_count/services/table_detector.dart';
import 'package:monthly_count/widgets/grid_table_preview.dart';
import 'package:monthly_count/widgets/info_card.dart';
import 'package:monthly_count/widgets/section_card.dart';

enum _Source { none, bank, yisj }

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  _Source _source = _Source.none;
  int _step = 0;
  String? _yisjSummary;

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

  List<String> get _steps {
    switch (_source) {
      case _Source.bank:
        return const ['Format', 'File', 'Map', 'Review'];
      case _Source.yisj:
        return const ['Format', 'File'];
      case _Source.none:
        return const ['Format'];
    }
  }

  void _selectSource(_Source s) {
    setState(() {
      _source = s;
      _step = s == _Source.none ? 0 : 1;
      _error = null;
      _grid = null;
      _table = null;
      _result = null;
      _yisjSummary = null;
    });
  }

  Future<void> _pickAndImportYisj() async {
    setState(() {
      _error = null;
      _yisjSummary = null;
    });
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['yisj'],
      );
      if (res == null || res.files.single.path == null) return;
      final imported =
          await TransactionShareService.fromYiSj(res.files.single.path!);
      if (imported.transactions.isEmpty) {
        setState(() => _error = 'No transactions found in file.');
        return;
      }
      // Categories first (dedup by id and by name), then transactions.
      final catNotifier = ref.read(categoriesProvider.notifier);
      final existingCats = ref.read(categoriesProvider);
      var addedCats = 0;
      for (final cat in imported.categories) {
        final byId = existingCats.any((c) => c.id == cat.id);
        final byName = existingCats
            .any((c) => c.title.toLowerCase() == cat.title.toLowerCase());
        if (!byId && !byName) {
          catNotifier.addCategory(cat);
          addedCats++;
        }
      }
      final txNotifier = ref.read(transactionsProvider.notifier);
      for (final tx in imported.transactions) {
        txNotifier.addTransaction(tx);
      }
      setState(() => _yisjSummary =
          'Imported ${imported.transactions.length} transactions'
          '${addedCats > 0 ? ', $addedCats new categories' : ''}');
    } catch (e) {
      setState(() => _error = 'Failed to import: $e');
    }
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
        _step = 2;
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BreadCrumb.builder(
              itemCount: _steps.length,
              builder: (index) {
                final active = index == _step;
                return BreadCrumbItem(
                  content: GestureDetector(
                    onTap: index <= _step
                        ? () => setState(() => _step = index)
                        : null,
                    child: Text(
                      _steps[index],
                      style: TextStyle(
                        color: active
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
              divider: Icon(Icons.chevron_right,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            _buildStepBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    if (_step == 0) return _buildFormatStep();
    if (_source == _Source.yisj) return _buildYisjStep();
    switch (_step) {
      case 1:
        return _buildBankFileStep();
      case 2:
        return _buildBankMapStep();
      case 3:
        return _buildBankReviewStep();
    }
    return const SizedBox.shrink();
  }

  Widget _buildFormatStep() {
    return SectionCard(
      title: 'Format',
      description: 'What are you importing?',
      child: SegmentedButton<_Source>(
        segments: const [
          ButtonSegment(
              value: _Source.bank,
              label: Text('CSV / XLSX'),
              icon: Icon(Icons.table_chart)),
          ButtonSegment(
              value: _Source.yisj,
              label: Text('YesISpend backup'),
              icon: Icon(Icons.backup)),
        ],
        selected: _source == _Source.none ? <_Source>{} : {_source},
        emptySelectionAllowed: true,
        onSelectionChanged: (s) =>
            _selectSource(s.isEmpty ? _Source.none : s.first),
      ),
    );
  }

  Widget _buildYisjStep() {
    return SectionCard(
      title: 'Backup file',
      description: 'Pick a .yisj backup — no mapping needed.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: _pickAndImportYisj,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose .yisj & import'),
          ),
          if (_yisjSummary != null) ...[
            const SizedBox(height: 12),
            InfoCard(title: 'Import complete', items: [_yisjSummary!]),
          ],
        ],
      ),
    );
  }

  Widget _buildBankFileStep() {
    return SectionCard(
      title: 'File',
      description: 'Pick a CSV or XLSX bank statement',
      child: FilledButton.icon(
        onPressed: _pickFile,
        icon: const Icon(Icons.upload_file),
        label: const Text('Choose file'),
      ),
    );
  }

  Widget _buildBankMapStep() {
    final table = _table;
    if (table == null) return _buildBankFileStep();
    final profiles = ref.watch(importProfilesProvider);
    final mapping = _currentMapping();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Detected table',
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
              GridTablePreview(headers: table.headers, rows: table.dataRows),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SectionCard(
          title: 'Mapping',
          description: 'Use a saved profile or map columns manually',
          child: _buildMappingForm(table, profiles),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: mapping == null ? null : () => setState(() => _step = 3),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildBankReviewStep() {
    final table = _table;
    final mapping = _currentMapping();
    if (table == null || mapping == null) return _buildBankMapStep();
    final preview = applyMapping(table, mapping);
    return SectionCard(
      title: 'Review & import',
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
            isExpanded: true,
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
              isExpanded: true,
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
              width: 140,
              child: DropdownButtonFormField<String>(
                initialValue: _decimalSeparator,
                isExpanded: true,
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

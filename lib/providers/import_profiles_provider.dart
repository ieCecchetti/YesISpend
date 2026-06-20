import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/db/db_handler.dart';
import 'package:monthly_count/models/import_profile.dart';

class ImportProfilesNotifier extends StateNotifier<List<ImportProfile>> {
  ImportProfilesNotifier() : super([]) {
    _load();
  }

  final _db = DatabaseHelper.instance;

  Future<void> _load() async {
    try {
      final rows = await _db.queryAll('import_profile');
      state = rows.map((r) => ImportProfile.fromMap(r)).toList();
    } catch (e) {
      print('Error loading import profiles: $e');
    }
  }

  Future<void> addProfile(ImportProfile p) async {
    await _db.insert('import_profile', p.toMap());
    state = [...state, p];
  }

  Future<void> updateProfile(ImportProfile p) async {
    await _db.update('import_profile', p.toMap());
    state = [for (final x in state) x.id == p.id ? p : x];
  }

  Future<void> deleteProfile(String id) async {
    await _db.delete('import_profile', id);
    state = state.where((x) => x.id != id).toList();
  }
}

final importProfilesProvider =
    StateNotifierProvider<ImportProfilesNotifier, List<ImportProfile>>(
        (ref) => ImportProfilesNotifier());

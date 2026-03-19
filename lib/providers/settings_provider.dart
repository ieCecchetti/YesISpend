import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/config/themes.dart';
import 'package:monthly_count/db/db_handler.dart';

/// Restores [AppThemePreference] from DB ([AppThemePreference.name]).
AppThemePreference appThemePreferenceFromStoredName(String? stored) {
  if (stored == null || stored.isEmpty) {
    return AppThemePreference.defaultTheme;
  }
  for (final AppThemePreference v in AppThemePreference.values) {
    if (v.name == stored) return v;
  }
  return AppThemePreference.defaultTheme;
}

enum Settings {
  expenseObjective,
  showResumeStats,
  showExpenseLineChart,
  showMonthlyInstogram,
  showCathegoryPieChart,
  showStatistics,
}

enum AppThemePreference {
  defaultTheme,
  dark,
  design,
  olive,
  summer,
  peachy,
  rose,
}

extension AppThemePreferenceX on AppThemePreference {
  ThemeMode toThemeModeForMaterialApp() {
    switch (this) {
      case AppThemePreference.defaultTheme:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.design:
      case AppThemePreference.olive:
      case AppThemePreference.summer:
      case AppThemePreference.peachy:
      case AppThemePreference.rose:
        return ThemeMode.light;
    }
  }

  String get label {
    switch (this) {
      case AppThemePreference.defaultTheme:
        return 'Default';
      case AppThemePreference.dark:
        return 'Dark';
      case AppThemePreference.design:
        return 'Design';
      case AppThemePreference.olive:
        return 'Olive';
      case AppThemePreference.summer:
        return 'Summer';
      case AppThemePreference.peachy:
        return 'Peachy';
      case AppThemePreference.rose:
        return 'Rose';
    }
  }
}

class SettingsNotifier extends StateNotifier<Map<Settings, Object>> {
  SettingsNotifier()
      : super({
          Settings.expenseObjective: 1500.00,
          Settings.showResumeStats: true,
          Settings.showExpenseLineChart: true,
          Settings.showMonthlyInstogram: true,
          Settings.showCathegoryPieChart: true,
          Settings.showStatistics: true,
        });

  void updateFilter(Settings filter, Object value) {
    state = {
      ...state,
      filter: value,
    };
  }

  void updateFilters(Map<Settings, Object> newFilters) {
    state = newFilters;
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<Settings, Object>>(
        (ref) => SettingsNotifier());

class ThemePreferenceNotifier extends StateNotifier<AppThemePreference> {
  ThemePreferenceNotifier(super.initial);

  /// Persists to SQLite (`app_setting`) so the choice survives restarts.
  Future<void> setTheme(AppThemePreference preference) async {
    state = preference;
    await DatabaseHelper.instance.setThemePreferenceName(preference.name);
  }
}

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, AppThemePreference>(
  (ref) => ThemePreferenceNotifier(AppThemePreference.defaultTheme),
);

final selectedThemeModeProvider = Provider<ThemeMode>((ref) {
  final themePreference = ref.watch(themePreferenceProvider);
  return themePreference.toThemeModeForMaterialApp();
});

final selectedThemeDataProvider = Provider<ThemeData>((ref) {
  final themePreference = ref.watch(themePreferenceProvider);
  switch (themePreference) {
    case AppThemePreference.defaultTheme:
      return AppThemes.defaultTheme;
    case AppThemePreference.dark:
      return AppThemes.darkTheme;
    case AppThemePreference.design:
      return AppThemes.designTheme;
    case AppThemePreference.olive:
      return AppThemes.oliveTheme;
    case AppThemePreference.summer:
      return AppThemes.summerTheme;
    case AppThemePreference.peachy:
      return AppThemes.peachyTheme;
    case AppThemePreference.rose:
      return AppThemes.roseTheme;
  }
});


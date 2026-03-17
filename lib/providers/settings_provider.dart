import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:monthly_count/config/themes.dart';

enum Settings {
  expenseObjective,
  showResumeStats,
  showExpenseLineChart,
  showMonthlyInstogram,
  showCathegoryPieChart,
  showStatistics,
}

enum AppThemePreference {
  light,
  dark,
  design,
  olive,
  summer,
}

extension AppThemePreferenceX on AppThemePreference {
  ThemeMode toThemeModeForMaterialApp() {
    switch (this) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.design:
      case AppThemePreference.olive:
      case AppThemePreference.summer:
        return ThemeMode.light;
    }
  }

  String get label {
    switch (this) {
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
      case AppThemePreference.design:
        return 'Design';
      case AppThemePreference.olive:
        return 'Olive';
      case AppThemePreference.summer:
        return 'Summer';
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
  ThemePreferenceNotifier() : super(AppThemePreference.light);

  void setTheme(AppThemePreference preference) {
    state = preference;
  }
}

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, AppThemePreference>(
  (ref) => ThemePreferenceNotifier(),
);

final selectedThemeModeProvider = Provider<ThemeMode>((ref) {
  final themePreference = ref.watch(themePreferenceProvider);
  return themePreference.toThemeModeForMaterialApp();
});

final selectedThemeDataProvider = Provider<ThemeData>((ref) {
  final themePreference = ref.watch(themePreferenceProvider);
  switch (themePreference) {
    case AppThemePreference.light:
      return AppThemes.lightTheme;
    case AppThemePreference.dark:
      return AppThemes.darkTheme;
    case AppThemePreference.design:
      return AppThemes.designTheme;
    case AppThemePreference.olive:
      return AppThemes.oliveTheme;
    case AppThemePreference.summer:
      return AppThemes.summerTheme;
  }
});


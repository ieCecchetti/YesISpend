import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Settings {
  expenseObjective,
  showResumeStats,
  showExpenseLineChart,
  showMonthlyInstogram,
  showCathegoryPieChart,
  showStatistics
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


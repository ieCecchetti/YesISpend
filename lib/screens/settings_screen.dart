import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/config/themes.dart';
import 'package:monthly_count/providers/settings_provider.dart';
import 'package:monthly_count/widgets/settings/budget_checker.dart';
import 'package:monthly_count/widgets/section_card.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var settings = ref.watch(settingsProvider);
    var actualFilters = settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Section
            SectionCard(
              title: 'Expense Budget',
              description: 'Set your monthly expense budget limit',
              child: budgetChecker(context, ref),
            ),
            const SizedBox(height: 4),

            SectionCard(
              title: 'Appearance',
              description: 'Choose your app theme',
              child: _buildThemeSelector(context, ref),
            ),
            const SizedBox(height: 4),

            // Analytics Display Section
            SectionCard(
              title: 'Analytics Display',
              description:
                  'Configure which analytics panels to show on the home screen',
              child: Column(
                children: [
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show main screen statistics',
                    'Show the income/outcome resume statistics on the main screen',
                    Settings.showResumeStats,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show income/expenses line chart',
                    'Show the income/expenses line chart on the home screen',
                    Settings.showExpenseLineChart,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show category pie chart',
                    'Show a category pie chart on the home screen',
                    Settings.showCathegoryPieChart,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show expenses daily histogram',
                    'Show expenses daily histogram on the home screen',
                    Settings.showMonthlyInstogram,
                    actualFilters,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    ref,
                    'Show expenses statistics',
                    'Show expenses statistics on the home screen',
                    Settings.showStatistics,
                    actualFilters,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    Settings setting,
    Map<Settings, Object> actualFilters,
  ) {
    return SwitchListTile(
      value: actualFilters[setting] as bool,
      onChanged: (isChecked) {
        ref.read(settingsProvider.notifier).updateFilter(setting, isChecked);
      },
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(themePreferenceProvider);
    final allThemes = AppThemePreference.values;
    final colorScheme = Theme.of(context).colorScheme;
    final inputFill =
        Theme.of(context).inputDecorationTheme.fillColor ?? colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AppThemePreference>(
          value: selectedTheme,
          dropdownColor: inputFill,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
          iconEnabledColor: colorScheme.onSurface,
          decoration: InputDecoration(
            labelText: 'Theme',
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
            floatingLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: allThemes.map((theme) {
            return DropdownMenuItem<AppThemePreference>(
              value: theme,
              child: Row(
                children: [
                  _themePreview(theme),
                  const SizedBox(width: 10),
                  Text(theme.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            ref.read(themePreferenceProvider.notifier).setTheme(value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Default, Dark, Design, Olive, and Summer palettes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _themePrimaryColor(AppThemePreference theme) {
    switch (theme) {
      case AppThemePreference.light:
        return AppThemes.lightTheme.colorScheme.primary;
      case AppThemePreference.dark:
        return AppThemes.darkTheme.colorScheme.primary;
      case AppThemePreference.design:
        return AppThemes.designTheme.colorScheme.primary;
      case AppThemePreference.olive:
        return AppThemes.oliveTheme.colorScheme.primary;
      case AppThemePreference.summer:
        return AppThemes.summerTheme.colorScheme.primary;
    }
  }

  Widget _themePreview(AppThemePreference theme) {
    final c1 = _themePrimaryColor(theme);
    final c2 = _themeSecondaryColor(theme);
    final c3 = _themeSurfaceColor(theme);

    return SizedBox(
      width: 30,
      height: 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, child: _dot(c1)),
          Positioned(left: 8, child: _dot(c2)),
          Positioned(left: 16, child: _dot(c3)),
        ],
      ),
    );
  }

  Color _themeSecondaryColor(AppThemePreference theme) {
    switch (theme) {
      case AppThemePreference.light:
        return AppThemes.lightTheme.colorScheme.secondary;
      case AppThemePreference.dark:
        return AppThemes.darkTheme.colorScheme.secondary;
      case AppThemePreference.design:
        return AppThemes.designTheme.colorScheme.secondary;
      case AppThemePreference.olive:
        return AppThemes.oliveTheme.colorScheme.secondary;
      case AppThemePreference.summer:
        return AppThemes.summerTheme.colorScheme.secondary;
    }
  }

  Color _themeSurfaceColor(AppThemePreference theme) {
    switch (theme) {
      case AppThemePreference.light:
        return AppThemes.lightTheme.colorScheme.surface;
      case AppThemePreference.dark:
        return AppThemes.darkTheme.colorScheme.surface;
      case AppThemePreference.design:
        return AppThemes.designTheme.colorScheme.surface;
      case AppThemePreference.olive:
        return AppThemes.oliveTheme.colorScheme.surface;
      case AppThemePreference.summer:
        return AppThemes.summerTheme.colorScheme.surface;
    }
  }

  Widget _dot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1),
      ),
    );
  }
}

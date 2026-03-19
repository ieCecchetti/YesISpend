import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monthly_count/providers/settings_provider.dart';

/// Monthly budget slider + value, styled like the search filter price range.
class BudgetChecker extends ConsumerStatefulWidget {
  const BudgetChecker({super.key});

  @override
  ConsumerState<BudgetChecker> createState() => _BudgetCheckerState();
}

class _BudgetCheckerState extends ConsumerState<BudgetChecker> {
  static const double _min = 0;
  static const double _max = 5000;

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final double b =
        ref.read(settingsProvider)[Settings.expenseObjective] as double;
    _controller = TextEditingController(text: b.toStringAsFixed(0));
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitControllerIfValid();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commitControllerIfValid() {
    final double? parsed = double.tryParse(_controller.text.trim());
    if (parsed != null && parsed >= _min && parsed <= _max) {
      ref
          .read(settingsProvider.notifier)
          .updateFilter(Settings.expenseObjective, parsed);
    } else {
      final double b =
          ref.read(settingsProvider)[Settings.expenseObjective] as double;
      _controller.text = b.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Map<Settings, Object>>(settingsProvider, (previous, next) {
      final double b = next[Settings.expenseObjective] as double;
      if (!_focusNode.hasFocus && mounted) {
        final String t = b.toStringAsFixed(0);
        if (_controller.text != t) {
          _controller.text = t;
        }
      }
    });

    final double budget =
        ref.watch(settingsProvider)[Settings.expenseObjective] as double;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    // Same as search price panel: card / elevated surface, not input fill (fixes olive mismatch).
    final Color sliderPanelBg = colorScheme.surfaceContainerHighest;
    final Color sliderInactiveTrack = Color.alphaBlend(
      colorScheme.onSurfaceVariant.withOpacity(0.35),
      sliderPanelBg,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: sliderPanelBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min €${_min.toInt()}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Max €${_max.toInt()}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: sliderInactiveTrack,
                  thumbColor: colorScheme.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 11,
                    elevation: 0,
                    pressedElevation: 0,
                  ),
                  trackShape: const RoundedRectSliderTrackShape(),
                  valueIndicatorColor: Colors.transparent,
                  valueIndicatorStrokeColor: Colors.transparent,
                  valueIndicatorTextStyle: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  showValueIndicator: ShowValueIndicator.onlyForDiscrete,
                ),
                child: Slider(
                  value: budget.clamp(_min, _max),
                  min: _min,
                  max: _max,
                  divisions: 100,
                  label: '€${budget.toStringAsFixed(0)}',
                  onChanged: (double value) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateFilter(Settings.expenseObjective, value);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '€',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 2, bottom: 4),
                  ),
                  onSubmitted: (_) => _commitControllerIfValid(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

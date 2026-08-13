import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.value,
    required this.onChanged,
    this.minimum = 0,
    this.maximum,
    this.step = 1,
    this.decimalPlaces = 0,
    this.unit,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double minimum;
  final double? maximum;
  final double step;
  final int decimalPlaces;
  final String? unit;

  bool get _canDecrease => value - step >= minimum;

  bool get _canIncrease {
    final max = maximum;
    return max == null || value + step <= max;
  }

  void _decrease() {
    if (_canDecrease) {
      onChanged(_normalize(value - step));
    }
  }

  void _increase() {
    if (_canIncrease) {
      onChanged(_normalize(value + step));
    }
  }

  double _normalize(double number) {
    return double.parse(number.toStringAsFixed(decimalPlaces));
  }

  String _formattedValue() {
    final formatted = value.toStringAsFixed(decimalPlaces);
    if (decimalPlaces == 0) {
      return value.toInt().toString();
    }
    return formatted.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.60),
            ),
          ),
          child: Column(
            children: [
              Text(
                _formattedValue(),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              if (unit != null && unit!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _canDecrease ? _decrease : null,
                icon: const Icon(Icons.remove_rounded),
                label: Text(_formatStep()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _canIncrease ? _increase : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(_formatStep()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatStep() {
    if (step == step.roundToDouble()) {
      return step.toInt().toString();
    }
    return step
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

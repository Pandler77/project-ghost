import 'package:flutter/material.dart';

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

  bool get _canDecrease {
    return value - step >= minimum;
  }

  bool get _canIncrease {
    final max = maximum;

    if (max == null) {
      return true;
    }

    return value + step <= max;
  }

  void _decrease() {
    if (!_canDecrease) {
      return;
    }

    onChanged(_normalize(value - step));
  }

  void _increase() {
    if (!_canIncrease) {
      return;
    }

    onChanged(_normalize(value + step));
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                _formattedValue(),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit != null && unit!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _canDecrease ? _decrease : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Icon(Icons.remove),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _canIncrease ? _increase : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

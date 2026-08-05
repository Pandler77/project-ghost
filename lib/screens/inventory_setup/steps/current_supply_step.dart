import 'package:flutter/material.dart';

import '../widgets/number_stepper.dart';
import '../widgets/step_header.dart';

class CurrentSupplyStep extends StatelessWidget {
  const CurrentSupplyStep({
    required this.containerType,
    required this.containerSize,
    required this.currentAmount,
    required this.unit,
    required this.onCurrentAmountChanged,
    super.key,
  });

  final String containerType;
  final double containerSize;
  final double currentAmount;
  final String unit;

  final ValueChanged<double> onCurrentAmountChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerName = containerType.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: 'How much is left?',
          subtitle:
              'Enter the amount remaining in your currently open $containerName.',
          currentStep: 3,
          totalSteps: 6,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How this works',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'If the $containerName is unopened, leave this at '
                '${_formatNumber(containerSize)} $unit.\n\n'
                'If it has already been used, enter the amount that remains.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        NumberStepper(
          value: currentAmount,
          onChanged: onCurrentAmountChanged,
          minimum: 0,
          maximum: containerSize,
          step: _stepForUnit(unit),
          decimalPlaces: _decimalPlacesForUnit(unit),
          unit: unit,
        ),
        const SizedBox(height: 16),
        Text(
          currentAmount <= 0
              ? 'No open $containerName is currently being tracked.'
              : '${_formatNumber(currentAmount)} of '
                    '${_formatNumber(containerSize)} $unit remains.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  static double _stepForUnit(String unit) {
    return switch (unit) {
      'mcg' => 50,
      'IU' => 1,
      'tablets' || 'capsules' || 'pills' || 'softgels' || 'drops' => 1,
      _ => 0.5,
    };
  }

  static int _decimalPlacesForUnit(String unit) {
    return switch (unit) {
      'tablets' ||
      'capsules' ||
      'pills' ||
      'softgels' ||
      'drops' ||
      'IU' ||
      'mcg' => 0,
      _ => 1,
    };
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

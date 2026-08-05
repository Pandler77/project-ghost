import 'package:flutter/material.dart';

import '../widgets/number_stepper.dart';
import '../widgets/step_header.dart';

class UnopenedStep extends StatelessWidget {
  const UnopenedStep({
    required this.containerType,
    required this.unopenedQuantity,
    required this.onUnopenedQuantityChanged,
    super.key,
  });

  final String containerType;
  final int unopenedQuantity;
  final ValueChanged<int> onUnopenedQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final singular = containerType.toLowerCase();
    final plural = _pluralize(singular);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: 'How many unopened $plural do you have?',
          subtitle:
              'Count only sealed containers in your inventory. Do not count the one currently open.',
          currentStep: 4,
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
                'Example',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'If you have 1 open $singular and 3 sealed $plural, enter 3.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        NumberStepper(
          value: unopenedQuantity.toDouble(),
          onChanged: (value) {
            onUnopenedQuantityChanged(value.round());
          },
          minimum: 0,
          step: 1,
          decimalPlaces: 0,
          unit: unopenedQuantity == 1 ? singular : plural,
        ),

        const SizedBox(height: 16),

        Text(
          unopenedQuantity == 0
              ? 'No unopened $plural are currently tracked.'
              : '$unopenedQuantity unopened '
                    '${unopenedQuantity == 1 ? singular : plural} tracked.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _pluralize(String value) {
    if (value == 'box') {
      return 'boxes';
    }

    if (value.endsWith('s')) {
      return value;
    }

    return '${value}s';
  }
}

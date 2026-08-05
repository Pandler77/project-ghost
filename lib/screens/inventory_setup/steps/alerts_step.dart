import 'package:flutter/material.dart';

import '../widgets/number_stepper.dart';
import '../widgets/step_header.dart';

class AlertsStep extends StatelessWidget {
  const AlertsStep({
    required this.containerType,
    required this.lowStockThreshold,
    required this.shippingDays,
    required this.onLowStockThresholdChanged,
    required this.onShippingDaysChanged,
    super.key,
  });

  final String containerType;
  final int lowStockThreshold;
  final int shippingDays;

  final ValueChanged<int> onLowStockThresholdChanged;
  final ValueChanged<int> onShippingDaysChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final singular = containerType.toLowerCase();
    final plural = _pluralize(singular);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'When should Ghost warn you?',
          subtitle: 'Set your low-supply threshold and typical shipping time.',
          currentStep: 5,
          totalSteps: 6,
        ),
        const SizedBox(height: 24),

        Text(
          'Low-supply alert',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Ghost will warn you when this many unopened $plural remain.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        NumberStepper(
          value: lowStockThreshold.toDouble(),
          onChanged: (value) {
            onLowStockThresholdChanged(value.round());
          },
          minimum: 0,
          step: 1,
          decimalPlaces: 0,
          unit: lowStockThreshold == 1 ? singular : plural,
        ),

        const SizedBox(height: 28),

        Text(
          'Typical shipping time',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Ghost will use this later to estimate when you should reorder.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        NumberStepper(
          value: shippingDays.toDouble(),
          onChanged: (value) {
            onShippingDaysChanged(value.round());
          },
          minimum: 0,
          step: 1,
          decimalPlaces: 0,
          unit: shippingDays == 1 ? 'day' : 'days',
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
          child: Text(
            _summaryText(plural: plural, singular: singular),
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  String _summaryText({required String singular, required String plural}) {
    final containerText = lowStockThreshold == 1
        ? '1 unopened $singular'
        : '$lowStockThreshold unopened $plural';

    final shippingText = shippingDays == 1 ? '1 day' : '$shippingDays days';

    return 'Ghost will warn you when $containerText remain. '
        'Your typical shipping time is $shippingText.';
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

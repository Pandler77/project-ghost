import 'package:flutter/material.dart';

import '../../../models/inventory_preset.dart';
import '../widgets/number_stepper.dart';
import '../widgets/step_header.dart';

class ContainerStep extends StatelessWidget {
  const ContainerStep({
    required this.protocolName,
    required this.preset,
    required this.containerType,
    required this.containerSize,
    required this.unit,
    required this.onContainerTypeChanged,
    required this.onContainerSizeChanged,
    required this.onUnitChanged,
    super.key,
  });

  final String protocolName;
  final InventoryPreset? preset;

  final String containerType;
  final double containerSize;
  final String unit;

  final ValueChanged<String> onContainerTypeChanged;
  final ValueChanged<double> onContainerSizeChanged;
  final ValueChanged<String> onUnitChanged;

  static const List<String> _containerTypes = [
    'Vial',
    'Bottle',
    'Box',
    'Pen',
    'Tube',
    'Package',
    'Container',
  ];

  static const List<String> _units = [
    'mg',
    'mcg',
    'g',
    'mL',
    'IU',
    'tablets',
    'capsules',
    'pills',
    'softgels',
    'drops',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'Confirm the container',
          subtitle:
              'Ghost filled in the most common setup. Change anything that does not match what you have.',
          currentStep: 2,
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
              Text(
                protocolName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                preset == null
                    ? 'No built-in preset found. Enter the setup that matches your supply.'
                    : 'Suggested from Ghost’s built-in preset.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Container type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final type in _containerTypes)
              ChoiceChip(
                label: Text(type),
                selected: containerType == type,
                onSelected: (_) {
                  onContainerTypeChanged(type);
                },
              ),
          ],
        ),

        const SizedBox(height: 28),

        Text(
          'How much fits in one ${containerType.toLowerCase()}?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'For example: 10 mg, 5 mL, or 60 tablets.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        NumberStepper(
          value: containerSize,
          onChanged: onContainerSizeChanged,
          minimum: 0.1,
          step: _stepForUnit(unit),
          decimalPlaces: _decimalPlacesForUnit(unit),
          unit: unit,
        ),

        const SizedBox(height: 28),

        const Text(
          'Unit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in _units)
              ChoiceChip(
                label: Text(option),
                selected: unit == option,
                onSelected: (_) {
                  onUnitChanged(option);
                },
              ),
          ],
        ),
      ],
    );
  }

  double _stepForUnit(String unit) {
    return switch (unit) {
      'mcg' => 50,
      'IU' => 1,
      'tablets' || 'capsules' || 'pills' || 'softgels' || 'drops' => 1,
      _ => 0.5,
    };
  }

  int _decimalPlacesForUnit(String unit) {
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
}

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

import '../../../models/inventory_batch.dart';
import '../inventory_setup_screen.dart';
import '../widgets/step_header.dart';
import '../../../theme/arctic_icons.dart';

class CurrentSupplyStep extends StatelessWidget {
  const CurrentSupplyStep({
    required this.containerType,
    required this.containerSize,
    required this.currentAmount,
    required this.unit,
    required this.source,
    required this.existingBatches,
    required this.selectedExistingBatchId,
    required this.separateContainerSize,
    required this.onSeparateContainerSizeChanged,
    required this.onSourceChanged,
    required this.onExistingBatchSelected,
    super.key,
  });

  final String containerType;
  final double containerSize;
  final double currentAmount;
  final String unit;

  final ActiveContainerSource source;

  final List<InventoryBatch> existingBatches;
  final String? selectedExistingBatchId;

  final double? separateContainerSize;
  final ValueChanged<double> onSeparateContainerSizeChanged;

  final ValueChanged<ActiveContainerSource> onSourceChanged;
  final ValueChanged<String> onExistingBatchSelected;

  List<InventoryBatch> get _availableBatches {
    return existingBatches
        .where((batch) => batch.quantity > 0)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = containerType.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: 'Do you currently have one open?',
          subtitle:
              'If you are already using a $name, tell ArcticDose where it came from.',
          currentStep: 3,
          totalSteps: 7,
        ),
        const SizedBox(height: AppSpacing.lg),

        _SourceCard(
          title: 'No active $name',
          subtitle: 'Everything being added is unopened.',
          icon: ArcticIcons.inventory_2_outlined,
          selected: source == ActiveContainerSource.none,
          onTap: () {
            onSourceChanged(ActiveContainerSource.none);
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        _SourceCard(
          title: 'From this inventory',
          subtitle:
              'One of the ${_pluralize(name)} you are adding is already open.',
          icon: ArcticIcons.science_outlined,
          selected: source == ActiveContainerSource.thisBatch,
          onTap: () {
            onSourceChanged(ActiveContainerSource.thisBatch);
          },
        ),

        if (_availableBatches.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),

          _SourceCard(
            title: 'From existing ArcticDose Supply',
            subtitle:
                'The active $name came from inventory you already tracked.',
            icon: ArcticIcons.inventory_outlined,
            selected: source == ActiveContainerSource.existingBatch,
            onTap: () {
              onSourceChanged(ActiveContainerSource.existingBatch);
            },
          ),
        ],

        const SizedBox(height: AppSpacing.sm),

        _SourceCard(
          title: 'A separate / older $name',
          subtitle:
              'The active $name is not part of the inventory you are adding.',
          icon: ArcticIcons.call_split_outlined,
          selected: source == ActiveContainerSource.separate,
          onTap: () {
            onSourceChanged(ActiveContainerSource.separate);
          },
        ),

        if (source == ActiveContainerSource.separate) ...[
          const SizedBox(height: AppSpacing.lg),

          Text(
            'What size is the older $name?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          Text(
            'Enter the full capacity of the active $name, not how much is left.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: AppSpacing.sm),

          TextFormField(
            initialValue: separateContainerSize == null
                ? ''
                : _formatNumber(separateContainerSize!),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '$name size',
              suffixText: unit,
              hintText: 'Example: 150',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value.trim());

              if (parsed != null && parsed > 0) {
                onSeparateContainerSizeChanged(parsed);
              }
            },
          ),
        ],

        if (source == ActiveContainerSource.existingBatch) ...[
          const SizedBox(height: AppSpacing.lg),

          const Text(
            'Which inventory did it come from?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          Text(
            'Select the batch that supplied the active $name.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: 14),

          for (final batch in _availableBatches) ...[
            _ExistingBatchCard(
              batch: batch,
              selected: selectedExistingBatchId == batch.id,
              onTap: () {
                onExistingBatchSelected(batch.id);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],

        if (source != ActiveContainerSource.none) ...[
          const SizedBox(height: AppSpacing.lg),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (Theme.of(context).cardTheme.color ?? colors.surface),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_forward, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _sourceExplanation(name),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _sourceExplanation(String name) {
    switch (source) {
      case ActiveContainerSource.none:
        return '';

      case ActiveContainerSource.thisBatch:
        return 'ArcticDose will count one of these ${_pluralize(name)} '
            'as the active $name and the rest as unopened inventory.';

      case ActiveContainerSource.existingBatch:
        return 'ArcticDose will take one $name from the selected existing batch. '
            'All of the new inventory you are adding will remain unopened.';

      case ActiveContainerSource.separate:
        return 'ArcticDose will keep all of this new inventory unopened and '
            'track the active $name separately.';
    }
  }

  static String _pluralize(String value) {
    if (value == 'box') {
      return 'boxes';
    }

    if (value.endsWith('s')) {
      return value;
    }

    return '${value}s';
  }
}

class _ExistingBatchCard extends StatelessWidget {
  const _ExistingBatchCard({
    required this.batch,
    required this.selected,
    required this.onTap,
  });

  final InventoryBatch batch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final vendor = batch.vendor?.trim();
    final lot = batch.batch?.trim();

    final details = <String>[
      '${_formatNumber(batch.containerSize)} ${batch.unit}',
      '${batch.quantity} unopened',
    ];

    if (vendor != null && vendor.isNotEmpty) {
      details.add(vendor);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.10)
                : (Theme.of(context).cardTheme.color ?? colors.surface),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                ArcticIcons.inventory_2_outlined,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      details.join(' • '),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),

                    if (lot != null && lot.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Lot $lot',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.10)
                : (Theme.of(context).cardTheme.color ?? colors.surface),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

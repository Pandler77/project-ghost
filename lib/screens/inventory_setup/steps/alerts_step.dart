import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/number_stepper.dart';
import '../widgets/step_header.dart';
import '../../../theme/arctic_icons.dart';

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
    final colors = Theme.of(context).colorScheme;
    final singular = containerType.toLowerCase();
    final plural = _pluralize(singular);
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'When should MODOSE warn you?',
          subtitle: 'Set your low-supply threshold and typical shipping time.',
          currentStep: 6,
          totalSteps: 7,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Low-supply alert',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'MODOSE will warn you when this many unopened $plural remain.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Typical shipping time',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'MODOSE uses this to estimate when you should reorder.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.60),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ArcticIcons.notifications_active_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _summaryText(plural: plural, singular: singular),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    height: 1.4,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _summaryText({
    required String singular,
    required String plural,
  }) {
    final containerText = lowStockThreshold == 1
        ? '1 unopened $singular'
        : '$lowStockThreshold unopened $plural';

    final shippingText = shippingDays == 1
        ? '1 day'
        : '$shippingDays days';

    return 'MODOSE will warn you when $containerText remain. '
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


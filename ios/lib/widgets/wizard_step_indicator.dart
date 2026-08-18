import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WizardStepIndicator extends StatelessWidget {
  const WizardStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    this.label,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < totalSteps; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == currentStep ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index <= currentStep
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            label!,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

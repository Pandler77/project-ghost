import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class StepHeader extends StatelessWidget {
  const StepHeader({
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = totalSteps <= 0
        ? 0.0
        : (currentStep / totalSteps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: colors.primary.withValues(alpha: 0.10),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.pageTitle,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypography.body,
            height: 1.35,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

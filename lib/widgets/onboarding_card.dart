import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    required this.hasWeight,
    required this.onAddProtocol,
    required this.onLogWeight,
    super.key,
  });

  final bool hasWeight;
  final VoidCallback onAddProtocol;
  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Let’s get you tracking in under a minute.',
              style: TextStyle(
                fontSize: AppTypography.body,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SetupStep(
              number: 1,
              label: 'Add your first protocol',
              isComplete: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SetupStep(
              number: 2,
              label: 'Log your starting weight',
              isComplete: hasWeight,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddProtocol,
                icon: const Icon(Icons.add),
                label: const Text('Add First Protocol'),
              ),
            ),
            if (!hasWeight) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogWeight,
                  icon: const Icon(Icons.monitor_weight_outlined),
                  label: const Text('Log Starting Weight'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.label,
    required this.isComplete,
  });

  final int number;
  final String label;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isComplete
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: isComplete
              ? Icon(Icons.check, size: 17, color: colorScheme.onPrimary)
              : Text(
                  '$number',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
              decoration: isComplete ? TextDecoration.lineThrough : null,
              color: isComplete
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyTodayCard extends StatelessWidget {
  const EmptyTodayCard({
    required this.onAddProtocol,
    required this.onOpenTutorial,
    super.key,
  });

  final VoidCallback onAddProtocol;
  final VoidCallback onOpenTutorial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get Started',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your first protocol to begin tracking your schedule.',
            style: TextStyle(
              fontSize: AppTypography.body,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              onPressed: onOpenTutorial,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('View Quick Walkthrough'),
            ),
          ),
        ],
      ),
    );
  }
}

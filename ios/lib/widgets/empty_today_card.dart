import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyTodayCard extends StatelessWidget {
  const EmptyTodayCard({required this.onAddProtocol, super.key});

  final VoidCallback onAddProtocol;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                color: colorScheme.onSurfaceVariant,
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
          ],
        ),
      ),
    );
  }
}

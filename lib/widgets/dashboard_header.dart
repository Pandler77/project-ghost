import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.name,
    required this.remainingDoses,
    required this.totalDoses,
    super.key,
  });

  final String name;
  final int remainingDoses;
  final int totalDoses;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = switch (hour) {
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };

    final subtitle = switch ((totalDoses, remainingDoses)) {
      (0, _) => 'Let’s get you set up.',
      (_, 0) => 'All doses complete',
      (_, 1) => '1 dose today',
      _ => '$remainingDoses doses today',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypography.body,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

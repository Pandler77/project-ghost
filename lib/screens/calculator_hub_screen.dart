import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'reconstitution_calculator_screen.dart';
import 'dose_from_units_calculator_screen.dart';
import 'bac_water_calculator_screen.dart';

class CalculatorHubScreen extends StatelessWidget {
  const CalculatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Ghost Calculator',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose the calculation you need.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _CalculatorTile(
              icon: Icons.science_outlined,
              title: 'Reconstitution',
              subtitle: 'Calculate how many syringe units to draw.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReconstitutionCalculatorScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            _CalculatorTile(
              icon: Icons.vaccines_outlined,
              title: 'Dose from Units',
              subtitle: 'Calculate the dose contained in syringe units.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoseFromUnitsCalculatorScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            _CalculatorTile(
              icon: Icons.water_drop_outlined,
              title: 'BAC Water',
              subtitle: 'Calculate how much BAC water to add.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BacWaterCalculatorScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            _CalculatorTile(
              icon: Icons.calculate_outlined,
              title: 'Empty',
              subtitle: 'This Tile will be removed or set to something if I can think of it',
              onTap: () {
                _showComingSoon(context, 'Concentration');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: AppIcon.sm,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Always verify vial strength, liquid volume, and syringe '
                      'size before using a result.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String calculatorName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$calculatorName calculator is being built next.'),
      ),
    );
  }
}

class _CalculatorTile extends StatelessWidget {
  const _CalculatorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, color: colorScheme.primary, size: AppIcon.md),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

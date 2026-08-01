import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.onGetStarted, super.key});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),

              Icon(
                Icons.health_and_safety_outlined,
                size: 84,
                color: colorScheme.onPrimary,
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Project Ghost',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Track protocols, doses, weight, and progress in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.body,
                  height: 1.4,
                  color: colorScheme.onPrimary.withValues(alpha: 0.82),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onPressed: onGetStarted,
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

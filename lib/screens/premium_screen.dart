import 'package:flutter/material.dart';

import '../services/app_data_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({required this.dataService, super.key});

  final AppDataService dataService;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPremium = dataService.hasPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Ghost Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            40,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      size: 38,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hasPremium
                        ? 'Ghost Premium is active'
                        : 'Unlock the full Ghost experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    hasPremium
                        ? 'You have access to all current premium features.'
                        : 'Track without limits, manage supplies, use multiple profiles, and unlock deeper insights.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Included with Premium',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            const _PremiumFeatureCard(
              icon: Icons.all_inclusive,
              title: 'Unlimited dose logging',
              description:
                  'Continue tracking after the first 10 free completed doses.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: Icons.inventory_2_outlined,
              title: 'Ghost Supply™',
              description:
                  'Track inventory, remaining doses, open containers, low stock, vendors, and reorder timing.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: Icons.people_outline,
              title: 'Multiple profiles',
              description:
                  'Keep protocols, history, weight, inventory, and schedules separated for each person or dependent.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: Icons.insights_outlined,
              title: 'Weight analytics',
              description:
                  'Unlock detailed trends, date ranges, weekly changes, records, goals, and projections.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: Icons.analytics_outlined,
              title: 'Advanced statistics',
              description:
                  'See adherence, missed doses, streaks, total usage, and protocol performance.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: Icons.file_download_outlined,
              title: 'Data export',
              description:
                  'Export dose, protocol, weight, and inventory data when this feature launches.',
              badge: 'Coming later',
            ),

            const SizedBox(height: AppSpacing.lg),

            if (!hasPremium) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Premium subscription',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pricing and free-trial details will appear here once store purchases are connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          _showPurchasesNotReady(context);
                        },
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: const Text('Unlock Ghost Premium'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _showPurchasesNotReady(context);
                        },
                        child: const Text('Restore Purchases'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Subscriptions will be managed through the App Store or Google Play. Ghost will not process payment information directly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: colors.primary),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Your Premium features are unlocked.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPurchasesNotReady(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Purchases not connected yet'),
          content: const Text(
            'The Premium screen is ready, but App Store and Google Play purchases will be connected during store preparation.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

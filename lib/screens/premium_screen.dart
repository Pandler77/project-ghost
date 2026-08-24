import 'package:flutter/material.dart';

import '../services/app_data_service.dart';
import '../services/usage_analytics_service.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({required this.dataService, super.key});

  final AppDataService dataService;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.premiumScreenViewed,
      properties: {
        'premium_active': widget.dataService.hasPremium,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPremium = widget.dataService.hasPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('MODOSE Premium')),
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
                gradient: LinearGradient(
                  colors: hasPremium
                      ? [
                          const Color(0xFFE3AA22).withValues(alpha: 0.20),
                          const Color(0xFFE3AA22).withValues(alpha: 0.07),
                        ]
                      : [
                          colors.primary.withValues(alpha: 0.18),
                          colors.primary.withValues(alpha: 0.06),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: hasPremium
                      ? const Color(0xFFE3AA22).withValues(alpha: 0.70)
                      : colors.primary.withValues(alpha: 0.45),
                  width: hasPremium ? 1.5 : 1.25,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          hasPremium ? const Color(0xFFE3AA22) : colors.primary,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/branding/modose_premium_mark.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hasPremium
                        ? 'MODOSE Premium is active'
                        : 'Unlock the full MODOSE experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: hasPremium
                          ? const Color(0xFFB77A00)
                          : colors.primary,
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
              icon: ArcticIcons.all_inclusive,
              title: 'Unlimited dose logging',
              description:
                  'Continue tracking after the first 10 free completed doses.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.inventory_2_outlined,
              title: 'MODOSE Supply™',
              description:
                  'Track inventory, remaining doses, open containers, low stock, vendors, and reorder timing.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.people_outline,
              title: 'Multiple profiles',
              description:
                  'Keep protocols, history, weight, inventory, and schedules separated for each person or dependent.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.insights_outlined,
              title: 'Weight analytics',
              description:
                  'Unlock detailed trends, date ranges, weekly changes, records, goals, and projections.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.compare_outlined,
              title: 'Progress photo comparison',
              description:
                  'Compare progress sessions side by side to see visual changes over time.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.analytics_outlined,
              title: 'Advanced statistics',
              description:
                  'See adherence, missed doses, streaks, total usage, and protocol performance.',
            ),

            const SizedBox(height: AppSpacing.sm),

            const _PremiumFeatureCard(
              icon: ArcticIcons.calculate_outlined,
              title: 'Advanced calculators',
              description:
                  'Unlock specialized dosing calculators including Dose from Units and BAC Water.',
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
                    Icon(
                      ArcticIcons.verified_outlined,
                      size: 30,
                      color: colors.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Premium subscription',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Subscription options will appear here when store purchases are enabled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Subscriptions will be managed through the App Store or Google Play. MODOSE will not process payment information directly.',
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
                  color: const Color(0xFFE3AA22).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: const Color(0xFFE3AA22).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      ArcticIcons.verified_outlined,
                      color: Color(0xFFB77A00),
                    ),
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
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

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

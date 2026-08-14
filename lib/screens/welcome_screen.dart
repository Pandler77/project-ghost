import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.onGetStarted, super.key});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? [
            const Color(0xFF111114),
            Color.alphaBlend(
              colors.primary.withValues(alpha: 0.12),
              const Color(0xFF111114),
            ),
          ]
        : [
            colors.surface,
            Color.alphaBlend(
              colors.primary.withValues(alpha: 0.08),
              colors.surface,
            ),
          ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha: isDark ? 0.10 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.28),
                                width: 1.25,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.blur_on_rounded,
                              size: 52,
                              color: colors.primary,
                            ),
                          ),

                          const SizedBox(height: 28),

                          Text(
                            'GHOST',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                              color: colors.primary,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Everything you track.\nOne place.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: colors.onSurface,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          Text(
                            'Protocols, doses, progress, reminders, inventory, '
                            'and tools — organized around your routine.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTypography.body,
                              height: 1.55,
                              color: colors.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 30),

                          _FeatureStrip(
                            items: const [
                              _FeatureItem(
                                icon: Icons.medication_outlined,
                                label: 'Protocols',
                              ),
                              _FeatureItem(
                                icon: Icons.insights_outlined,
                                label: 'Progress',
                              ),
                              _FeatureItem(
                                icon: Icons.inventory_2_outlined,
                                label: 'Supply',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.60),
                    ),
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        child: InkWell(
                          onTap: onGetStarted,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Center(
                              child: Text(
                                'Set Up Ghost',
                                style: TextStyle(
                                  fontSize: AppTypography.primary,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        'Takes about a minute. You can change everything later.',
                        textAlign: TextAlign.center,
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
          ),
        ),
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.items});

  final List<_FeatureItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _FeatureTile(item: items[index])),
          if (index < items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});

  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Icon(item.icon, size: AppIcon.md, color: colors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

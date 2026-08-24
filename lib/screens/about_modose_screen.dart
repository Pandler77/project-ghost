import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/arcticdose_logo.dart';
import '../theme/arctic_icons.dart';

class AboutMODOSEScreen extends StatelessWidget {
  const AboutMODOSEScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About MODOSE',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            60,
          ),
          children: [
            _BrandHero(colors: colors, isDark: isDark),

            const SizedBox(height: AppSpacing.lg),

            const _SectionLabel(title: 'APPLICATION'),

            const SizedBox(height: AppSpacing.sm),

            _AboutCard(
              children: [
                _AboutRow(
                  icon: ArcticIcons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                  accent: colors.primary,
                ),

                const _AboutDivider(),

                _AboutRow(
                  icon: ArcticIcons.phone_iphone_rounded,
                  title: 'Platforms',
                  subtitle: 'Built for iOS and Android',
                  accent: ArcticPalette.ice,
                ),

                const _AboutDivider(),

                _AboutRow(
                  icon: ArcticIcons.shield_outlined,
                  title: 'Your Data',
                  subtitle:
                      'Tracking data stays associated with your MODOSE profiles.',
                  accent: ArcticPalette.lavender,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SectionLabel(title: 'LEGAL'),

            const SizedBox(height: AppSpacing.sm),

            _AboutCard(
              children: [
                _AboutActionRow(
                  icon: ArcticIcons.description_outlined,
                  title: 'Open Source Licenses',
                  subtitle: 'View licenses for packages used by MODOSE.',
                  accent: colors.primary,
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'MODOSE',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? ArcticPalette.darkRaised.withValues(alpha: 0.62)
                    : ArcticPalette.lightRaised,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return ArcticPalette.accentGradient(
                        context,
                      ).createShader(bounds);
                    },
                    child: const Icon(
                      ArcticIcons.medication_outlined,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    'PLAN. TRACK. ACHIEVE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'MODOSE helps keep your protocols, doses, '
                    'progress, reminders, inventory, and tracking '
                    'organized in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      height: 1.45,
                      color: colors.onSurfaceVariant,
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
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.colors, required this.isDark});

  final ColorScheme colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 26, AppSpacing.lg, 26),
      decoration: BoxDecoration(
        gradient: ArcticPalette.headerGradient(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark
              ? ArcticPalette.lavender.withValues(alpha: 0.22)
              : ArcticPalette.purple.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : ArcticPalette.purple.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const MODOSELogo(size: 92, borderRadius: 24),

          const SizedBox(height: AppSpacing.md),

          const Text(
            'MODOSE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Protocol tracking, reminders, progress, inventory, and tools in one place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              gradient: ArcticPalette.accentGradient(context),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        fontSize: AppTypography.caption,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppCardDecoration.standard(context),
      child: Column(children: children),
    );
  }
}

class _AboutDivider extends StatelessWidget {
  const _AboutDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 66);
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 13,
      ),
      child: Row(
        children: [
          _AboutIcon(icon: icon, accent: accent),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    height: 1.35,
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

class _AboutActionRow extends StatelessWidget {
  const _AboutActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          child: Row(
            children: [
              _AboutIcon(icon: icon, accent: accent),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutIcon extends StatelessWidget {
  const _AboutIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, size: 21, color: accent),
    );
  }
}

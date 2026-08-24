import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.onGetStarted, super.key});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondary = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFF334155);

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Transform.scale(
              scale: 1.06,
              child: Image.asset(
                isDark
                    ? 'assets/branding/welcome_bg_dark.png'
                    : 'assets/branding/welcome_bg_light.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.12),
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.04),
                        const Color(0xFF07101F).withValues(alpha: 0.18),
                        const Color(0xFF07101F).withValues(alpha: 0.72),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.02),
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.62),
                      ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                8,
                AppSpacing.lg,
                8,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            isDark
                                ? 'assets/branding/arcticdose_brandmark_dark.png'
                                : 'assets/branding/arcticdose_brandmark_light.png',
                            width: 265,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(height: 12),
                          Image.asset(
                            isDark
                                ? 'assets/branding/welcome_tagline_dark.png'
                                : 'assets/branding/welcome_tagline_light.png',
                            width: 250,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF07101F).withValues(alpha: 0.48)
                              : Colors.white.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark
                                ? ArcticPalette.lavender.withValues(alpha: 0.22)
                                : ArcticPalette.purple.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Everything you track.',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: foreground,
                              ),
                            ),
                            const SizedBox(height: 1),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  ArcticPalette.accentGradient(
                                    context,
                                  ).createShader(bounds),
                              child: const Text(
                                'One place.',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Protocols, doses, progress, reminders, inventory, '
                              'and tools — organized around your routine.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppTypography.body,
                                height: 1.35,
                                color: secondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Column(
                              children: [
                                _FeatureRow(
                                  icon: LucideIcons.syringe,
                                  title: 'Protocols',
                                  description:
                                      'Build schedules, track doses, and stay on top of your routine.',
                                ),
                                SizedBox(height: 8),
                                _FeatureRow(
                                  icon: LucideIcons.chartNoAxesCombined,
                                  title: 'Progress',
                                  description:
                                      'See trends, weight changes, history, and long-term progress.',
                                ),
                                SizedBox(height: 8),
                                _FeatureRow(
                                  icon: LucideIcons.package,
                                  title: 'Supply',
                                  description:
                                      'Track inventory, monitor what you have, and stay prepared.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: ArcticPalette.accentGradient(context),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onGetStarted,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.button,
                                  ),
                                  child: const SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: Center(
                                      child: Text(
                                        'Set Up MODOSE',
                                        style: TextStyle(
                                          fontSize: AppTypography.primary,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Takes about a minute.\n'
                              'You can change everything later.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                height: 1.25,
                                color: secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);

    final secondary = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF475569);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.035)
            : Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ArcticPalette.lavender.withValues(alpha: isDark ? 0.16 : 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.68),
              shape: BoxShape.circle,
              border: Border.all(
                color: ArcticPalette.lavender.withValues(alpha: 0.24),
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  ArcticPalette.accentGradient(context).createShader(bounds),
              child: Icon(icon, size: 23, color: Colors.white),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    height: 1.3,
                    color: secondary,
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

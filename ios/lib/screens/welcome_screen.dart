import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/arcticdose_logo.dart';
import '../theme/arctic_icons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.onGetStarted, super.key});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondary = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF334155);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            isDark
                ? 'assets/branding/welcome_bg_dark.png'
                : 'assets/branding/welcome_bg_light.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  const ArcticDoseLogo(size: 118, borderRadius: 30),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                        color: foreground,
                      ),
                      children: const [
                        TextSpan(text: 'Arctic'),
                        TextSpan(
                          text: 'Dose',
                          style: TextStyle(color: Color(0xFF6E50F5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PLAN. TRACK. ACHIEVE.',
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: secondary,
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF07101F).withValues(alpha: 0.80)
                              : Colors.white.withValues(alpha: 0.84),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark
                                ? ArcticPalette.lavender.withValues(alpha: 0.22)
                                : ArcticPalette.purple.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Everything you track.',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  ArcticPalette.accentGradient(context)
                                      .createShader(bounds),
                              child: const Text(
                                'One place.',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Protocols, doses, progress, reminders, inventory, '
                              'and tools — organized around your routine.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppTypography.body,
                                height: 1.45,
                                color: secondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: const [
                                Expanded(
                                  child: _Feature(
                                    icon: ArcticIcons.medication_outlined,
                                    label: 'Protocols',
                                  ),
                                ),
                                Expanded(
                                  child: _Feature(
                                    icon: ArcticIcons.bar_chart_rounded,
                                    label: 'Progress',
                                  ),
                                ),
                                Expanded(
                                  child: _Feature(
                                    icon: ArcticIcons.inventory_2_outlined,
                                    label: 'Supply',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient:
                                    ArcticPalette.accentGradient(context),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onGetStarted,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.button),
                                  child: const SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: Center(
                                      child: Text(
                                        'Set Up ArcticDose',
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
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Takes about a minute.\n'
                              'You can change everything later.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                height: 1.35,
                                color: secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.58),
            shape: BoxShape.circle,
            border: Border.all(
              color: ArcticPalette.lavender.withValues(alpha: 0.24),
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) =>
                ArcticPalette.accentGradient(context).createShader(bounds),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

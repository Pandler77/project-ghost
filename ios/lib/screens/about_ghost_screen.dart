import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class AboutGhostScreen extends StatelessWidget {
  const AboutGhostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About ArcticDose',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Icon(
                      ArcticIcons.blur_on_rounded,
                      size: 38,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'ArcticDose',
                    style: TextStyle(
                      fontSize: AppTypography.pageTitle,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Protocol tracking, progress, reminders, inventory, and tools in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      height: 1.4,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AboutCard(
              children: [
                ListTile(
                  leading: Icon(
                    ArcticIcons.info_outline,
                    color: colors.primary,
                  ),
                  title: const Text(
                    'Version',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Development build'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    ArcticIcons.code_outlined,
                    color: colors.primary,
                  ),
                  title: const Text(
                    'Built with Flutter',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Cross-platform application for iOS and Android.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    ArcticIcons.description_outlined,
                    color: colors.primary,
                  ),
                  title: const Text(
                    'Open Source Licenses',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'View licenses for packages used by ArcticDose.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'ArcticDose',
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
                color: Theme.of(context).cardTheme.color ?? colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.60),
                ),
              ),
              child: Text(
                'The final release should replace “Development build” with the actual application version and build number.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(children: children),
    );
  }
}

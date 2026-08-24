import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy',
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
            _InfoHero(
              icon: ArcticIcons.privacy_tip_outlined,
              title: 'Your data stays under your control',
              subtitle:
                  'MODOSE is designed around local-first tracking. This page explains what the app stores and which device permissions it may use.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _Section(
              title: 'Local App Data',
              body:
                  'Protocol details, dose history, weight logs, tracking preferences, MODOSE Supply data, notes, and other app settings are stored locally on your device unless a future backup or cloud feature is explicitly enabled by you.',
            ),
            const _Section(
              title: 'Progress Photos',
              body:
                  'Progress photos are selected or captured by you and are used only for your progress tracking experience inside MODOSE. MODOSE does not upload them through the current local-only implementation.',
            ),
            const _Section(
              title: 'Notifications',
              body:
                  'MODOSE may request notification permission so it can deliver reminders you configure. Notification settings can be changed at any time from MODOSE Settings or your device settings.',
            ),
            const _Section(
              title: 'Device Permissions',
              body:
                  'MODOSE only requests permissions needed for features you choose to use, such as notifications, photos, or camera access. Denying an optional permission may limit the related feature but should not prevent unrelated features from working.',
            ),
            const _Section(
              title: 'Analytics & Tracking',
              body:
                  'The current app does not require advertising trackers or cross-app tracking for core functionality. If analytics, crash reporting, cloud backup, or other external services are added later, this privacy information should be updated before release.',
            ),
            const _Section(
              title: 'Deleting Your Data',
              body:
                  'Local MODOSE data can be removed from the app through Reset App Data once that action is enabled, or by uninstalling the app. Platform-level backups may be controlled separately by your device or operating system.',
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                'This in-app summary should match the final published privacy policy before App Store or Google Play release.',
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

class _InfoHero extends StatelessWidget {
  const _InfoHero({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    height: 1.4,
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: TextStyle(
              fontSize: AppTypography.caption,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


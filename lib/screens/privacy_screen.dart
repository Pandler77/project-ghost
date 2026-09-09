import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          children: const [
            _InfoHero(
              icon: ArcticIcons.privacy_tip_outlined,
              title: 'Your data stays under your control',
              subtitle:
                  'MODOSE is designed around local-first tracking. This page explains what information the app stores, which services it uses, and how your data is handled.',
            ),
            SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Local App Data',
              body:
                  'Protocol details, dose history, weight logs, tracking preferences, MODOSE Supply data, notes, injection-site information, and other app settings are stored locally on your device unless a future backup or cloud feature is explicitly enabled by you.',
            ),
            _Section(
              title: 'Progress Photos',
              body:
                  'Progress photos are selected or captured by you and are used only for your progress tracking experience inside MODOSE. In the current implementation, MODOSE does not upload your progress photos to MODOSE servers.',
            ),
            _Section(
              title: 'Anonymous Usage Analytics',
              body:
                  'MODOSE uses Aptabase to collect limited anonymous usage analytics, such as app opens and feature usage. These analytics are used to understand how the app is used and improve reliability and usability. MODOSE does not use this analytics data for advertising or cross-app tracking.',
            ),
            _Section(
              title: 'Crash Reporting',
              body:
                  'MODOSE uses Firebase Crashlytics to help identify app crashes and technical failures. Crash reports may include technical information such as device type, operating-system version, app version, and diagnostic details related to the crash. This information is used to improve app stability.',
            ),
            _Section(
              title: 'Notifications',
              body:
                  'MODOSE may request notification permission so it can deliver reminders you configure. Notification settings can be changed at any time from MODOSE Settings or your device settings. Notification delivery depends on your device, operating system, and platform services and is not guaranteed.',
            ),
            _Section(
              title: 'Device Permissions',
              body:
                  'MODOSE only requests permissions needed for features you choose to use, such as notifications, photos, or camera access. Denying an optional permission may limit the related feature but should not prevent unrelated features from working.',
            ),
            _Section(
              title: 'Purchases & Subscriptions',
              body:
                  'If you purchase MODOSE Premium, payment and subscription processing is handled by Apple App Store or Google Play. MODOSE may use RevenueCat to help determine subscription and entitlement status. MODOSE does not directly receive or store your full payment-card information.',
            ),
            _Section(
              title: 'Support Communications',
              body:
                  'If you contact MODOSE support, information you provide such as your name, email address, subject, and message may be processed so we can respond to your request. Support messages may be delivered through third-party email infrastructure used by MODOSE.',
            ),
            _Section(
              title: 'Advertising & Sale of Personal Information',
              body:
                  'MODOSE does not sell your personal information and does not use your health or medication-tracking information for advertising. MODOSE does not require advertising trackers or cross-app tracking for core functionality.',
            ),
            _Section(
              title: 'Data Retention & Deletion',
              body:
                  'Local MODOSE data remains on your device until you delete it, reset app data, or uninstall the app. Support communications and technical service records may be retained only as reasonably necessary for support, security, legal, or operational purposes. Platform-level backups may be controlled separately by your device or operating system.',
            ),
            _Section(
              title: 'Children',
              body:
                  'MODOSE is not intended for children under 13, and MODOSE does not knowingly collect personal information from children under 13.',
            ),
            _Section(
              title: 'Security',
              body:
                  'MODOSE uses reasonable safeguards designed to protect information handled by the app and its service providers. No method of electronic storage or transmission can be guaranteed to be completely secure.',
            ),
            _Section(
              title: 'Changes to This Privacy Policy',
              body:
                  'This privacy information may be updated as MODOSE changes or adds features and services. Material updates will be reflected in the published Privacy Policy.',
            ),
            _Section(
              title: 'Contact',
              body:
                  'Questions about privacy or data handling can be sent to support@modose.app.',
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
        border: Border.all(color: colors.primary.withValues(alpha: 0.14)),
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
  const _Section({required this.title, required this.body});

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

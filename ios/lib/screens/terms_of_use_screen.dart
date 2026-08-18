import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Use',
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ArcticDose Terms of Use',
                    style: TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Draft in-app terms for the current pre-release version of ArcticDose.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _TermsSection(
              title: '1. Personal Tracking Tool',
              body:
                  'ArcticDose is a personal organization and tracking application. It is not a medical provider, pharmacy, diagnostic service, or substitute for professional medical advice.',
            ),
            const _TermsSection(
              title: '2. User Responsibility',
              body:
                  'You are responsible for verifying any information you enter into ArcticDose, including protocol schedules, dose amounts, inventory values, calculator inputs, reminders, and other tracked information.',
            ),
            const _TermsSection(
              title: '3. Calculators',
              body:
                  'Calculator outputs are based entirely on the values you provide. You should independently verify vial strength, liquid volume, syringe type, units, and any other relevant input before relying on a result.',
            ),
            const _TermsSection(
              title: '4. Notifications',
              body:
                  'Reminder delivery is not guaranteed. Device settings, operating-system restrictions, battery settings, permissions, time-zone changes, or other technical conditions may delay or prevent notifications.',
            ),
            const _TermsSection(
              title: '5. Data',
              body:
                  'You are responsible for maintaining any backups you require. Local data may be lost if the app is deleted, device storage is cleared, the device is damaged, or a reset function is used.',
            ),
            const _TermsSection(
              title: '6. Premium Features',
              body:
                  'Premium features, pricing, subscriptions, restoration behavior, and purchase terms will be governed by the final store listing and applicable App Store or Google Play purchase terms.',
            ),
            const _TermsSection(
              title: '7. Changes',
              body:
                  'ArcticDose features and these terms may change before or after release. The published release version should include the final terms that apply to users.',
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.error.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                'These are product-development draft terms, not final legal review. Replace or review them before public release.',
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

class _TermsSection extends StatelessWidget {
  const _TermsSection({
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

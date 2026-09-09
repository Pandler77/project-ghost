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
                    'MODOSE Terms of Use',
                    style: TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'These Terms govern your use of MODOSE and its tracking, reminder, calculator, inventory, and subscription features.',
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
              title: '1. Acceptance of Terms',
              body:
                  'By downloading, accessing, or using MODOSE, you agree to these Terms of Use and the MODOSE Privacy Policy. If you do not agree, do not use the app.',
            ),
            const _TermsSection(
              title: '2. Personal Tracking Tool',
              body:
                  'MODOSE is a personal organization and tracking application. It is not a medical provider, pharmacy, diagnostic service, or substitute for professional medical advice, diagnosis, or treatment.',
            ),
            const _TermsSection(
              title: '3. User Responsibility',
              body:
                  'You are responsible for verifying any information you enter into MODOSE, including protocol schedules, dose amounts, inventory values, calculator inputs, reminders, medication details, and other tracked information. You are also responsible for deciding whether and how to act on information shown in the app.',
            ),
            const _TermsSection(
              title: '4. Calculators & Dose-Related Tools',
              body:
                  'Calculator and dose-related outputs are based entirely on the values you provide and may be affected by incorrect or incomplete inputs. You should independently verify vial strength, concentration, liquid volume, syringe type, units, dose amounts, and any other relevant information before relying on a result.',
            ),
            const _TermsSection(
              title: '5. Notifications',
              body:
                  'Reminder delivery is not guaranteed. Device settings, operating-system restrictions, battery settings, permissions, network conditions, time-zone changes, app updates, or other technical conditions may delay or prevent notifications. MODOSE should not be your only method for remembering important medication or protocol events.',
            ),
            const _TermsSection(
              title: '6. Local Data & Backups',
              body:
                  'Most MODOSE tracking data is stored locally on your device. You are responsible for maintaining any backups you require. Local data may be lost if the app is deleted, device storage is cleared, the device is damaged or replaced, or a reset function is used. Future backup or cloud features, if offered, may be subject to separate terms or limitations.',
            ),
            const _TermsSection(
              title: '7. Premium Subscriptions',
              body:
                  'MODOSE may offer optional Premium subscriptions through Apple App Store or Google Play. Pricing, billing frequency, trial terms if any, renewal, cancellation, refunds, and payment processing are governed by the applicable store and the subscription information shown at purchase. Subscriptions may renew automatically unless canceled through the applicable store before renewal.',
            ),
            const _TermsSection(
              title: '8. Restore Purchases & Entitlements',
              body:
                  'MODOSE may use platform purchase services and RevenueCat to determine whether Premium access is active and to support purchase restoration. Access to Premium features depends on the entitlement information returned by those services and may be delayed by platform or network issues.',
            ),
            const _TermsSection(
              title: '9. Changes to Premium Features',
              body:
                  'MODOSE may add, modify, replace, or remove Premium features over time. Any material subscription changes will be handled in accordance with applicable store rules and law.',
            ),
            const _TermsSection(
              title: '10. Acceptable Use',
              body:
                  'You may not use MODOSE to violate applicable law, interfere with the app or its services, attempt unauthorized access, distribute malicious code, abuse support systems, or use the app in a way that could harm MODOSE, its services, or other users.',
            ),
            const _TermsSection(
              title: '11. Third-Party Services',
              body:
                  'MODOSE may rely on third-party services such as Apple, Google, Firebase, Aptabase, RevenueCat, Cloudflare, and email-delivery providers. Those services may have their own terms and privacy practices, and MODOSE is not responsible for outages, delays, or changes caused by third-party services.',
            ),
            const _TermsSection(
              title: '12. Availability',
              body:
                  'MODOSE may be updated, changed, suspended, or discontinued at any time. We do not guarantee uninterrupted access to every feature or compatibility with every device, operating system, or platform version.',
            ),
            const _TermsSection(
              title: '13. Disclaimer of Warranties',
              body:
                  'MODOSE is provided on an "as is" and "as available" basis to the maximum extent permitted by law. We make no warranty that the app will be error-free, uninterrupted, medically accurate, or suitable for any particular purpose.',
            ),
            const _TermsSection(
              title: '14. Limitation of Liability',
              body:
                  'To the maximum extent permitted by law, MODOSE and its operators will not be liable for indirect, incidental, special, consequential, or punitive damages, or for losses arising from reliance on app data, calculations, reminders, missed notifications, local data loss, subscription interruptions, or third-party services.',
            ),
            const _TermsSection(
              title: '15. Indemnification',
              body:
                  'To the extent permitted by law, you agree to indemnify and hold harmless MODOSE and its operators from claims, damages, losses, liabilities, and expenses arising from your misuse of the app, violation of these Terms, or violation of applicable law or third-party rights.',
            ),
            const _TermsSection(
              title: '16. Termination',
              body:
                  'You may stop using MODOSE at any time. MODOSE may restrict or terminate access where reasonably necessary to protect the app, its services, users, or legal rights, subject to applicable law and platform rules.',
            ),
            const _TermsSection(
              title: '17. Changes to These Terms',
              body:
                  'These Terms may be updated as MODOSE changes or as legal, platform, or operational requirements evolve. Updated Terms will be published with a revised effective date where appropriate. Continued use of MODOSE after an update may constitute acceptance of the revised Terms to the extent permitted by law.',
            ),
            const _TermsSection(
              title: '18. Contact',
              body:
                  'Questions about these Terms can be sent to support@modose.app.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});

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

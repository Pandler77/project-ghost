import 'package:flutter/material.dart';

import '../core/repository/ghost_repository.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

const int kDoseSafetyAcknowledgementVersion = 1;
const String kDoseSafetyAcknowledgementType = 'medication_dose_calculation';

Future<bool> ensureDoseSafetyAcknowledged(BuildContext context) async {
  final settings = SettingsService();
  final repository = GhostRepository();

  final savedVersion = await settings.getDoseSafetyAcknowledgementVersion();
  final durableRecordExists = await repository.hasDoseSafetyAcknowledgement(
    acknowledgementType: kDoseSafetyAcknowledgementType,
    version: kDoseSafetyAcknowledgementVersion,
  );

  if (savedVersion >= kDoseSafetyAcknowledgementVersion &&
      durableRecordExists) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  final accepted = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    builder: (sheetContext) => const _DoseSafetyAcknowledgementSheet(),
  );

  if (accepted != true) {
    return false;
  }

  final acceptedAt = DateTime.now();

  // Write the durable audit record first. The local setting is only a fast
  // cache; access is considered acknowledged only when the database record
  // also exists for this profile/type/version.
  await repository.saveDoseSafetyAcknowledgement(
    acknowledgementType: kDoseSafetyAcknowledgementType,
    version: kDoseSafetyAcknowledgementVersion,
    acceptedAt: acceptedAt,
  );

  await settings.saveDoseSafetyAcknowledgementVersion(
    kDoseSafetyAcknowledgementVersion,
  );

  return true;
}

class DoseCalculationVerificationNotice extends StatelessWidget {
  const DoseCalculationVerificationNotice({
    this.compact = false,
    super.key,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: colors.tertiary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ArcticIcons.warning_amber_outlined,
            size: AppIcon.sm,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Calculated from the information you entered. Independently '
              'verify the medication, concentration, intended dose, and '
              'syringe measurement before administering.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: colors.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseSafetyAcknowledgementSheet extends StatefulWidget {
  const _DoseSafetyAcknowledgementSheet();

  @override
  State<_DoseSafetyAcknowledgementSheet> createState() =>
      _DoseSafetyAcknowledgementSheetState();
}

class _DoseSafetyAcknowledgementSheetState
    extends State<_DoseSafetyAcknowledgementSheet> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    ArcticIcons.warning_amber_outlined,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Medication & Dose Calculation Safety',
                    style: TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'MODOSE is a tracking and calculation aid. It does not provide '
              'medical advice, prescribe medication, determine your dose, or '
              'verify that the information you enter is correct.',
              style: TextStyle(
                fontSize: AppTypography.body,
                height: 1.45,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Dose and syringe-unit calculations are based entirely on the '
              'information you enter. Incorrect medication strength, '
              'reconstitution volume, intended dose, syringe type, or other '
              'input can produce an incorrect result.',
              style: TextStyle(
                fontSize: AppTypography.body,
                height: 1.45,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Always independently verify the medication, concentration, '
              'intended dose, and syringe measurement before administering. '
              'If you are unsure, confirm with a qualified healthcare '
              'professional.',
              style: TextStyle(
                fontSize: AppTypography.body,
                height: 1.45,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'You are responsible for independently verifying your medication, '
              'concentration, intended dose, syringe type, and measurement '
              'before administration. Do not rely on MODOSE as the sole source '
              'for determining or administering a medication dose.',
              style: TextStyle(
                fontSize: AppTypography.body,
                height: 1.45,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _understood,
              onChanged: (value) {
                setState(() => _understood = value ?? false);
              },
              title: const Text(
                'I understand and want to continue.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _understood
                    ? () => Navigator.pop(context, true)
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

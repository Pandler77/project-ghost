import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/dose_record.dart';
import '../models/injection_log.dart';
import '../theme/app_theme.dart';
import '../models/injection_site.dart';

class CompletedDoseSheet extends StatelessWidget {
  const CompletedDoseSheet({
    required this.dose,
    required this.record,
    required this.injectionLog,
    super.key,
  });

  final Dose dose;
  final DoseRecord record;
  final InjectionLog? injectionLog;

  static Future<bool> show({
    required BuildContext context,
    required Dose dose,
    required DoseRecord record,
    required InjectionLog? injectionLog,
  }) async {
    final shouldUndo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return CompletedDoseSheet(
          dose: dose,
          record: record,
          injectionLog: injectionLog,
        );
      },
    );

    return shouldUndo ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completedAt = record.completedAt ?? dose.completedAt;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Dose Details',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              dose.protocolName,
              style: TextStyle(
                fontSize: AppTypography.body,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailCard(
              children: [
                _DetailRow(
                  label: 'Actual dose',
                  value: record.actualAmount ?? record.scheduledAmount,
                ),
                _DetailRow(
                  label: 'Scheduled dose',
                  value: record.scheduledAmount,
                ),
                if (injectionLog != null)
                  _DetailRow(
                    label: 'Injection site',
                    value: injectionLog!.site.label,
                  ),
                if (completedAt != null)
                  _DetailRow(
                    label: 'Completed',
                    value: _formatDateTime(completedAt),
                  ),
                if (injectionLog?.notes?.trim().isNotEmpty == true)
                  _DetailRow(
                    label: 'Notes',
                    value: injectionLog!.notes!.trim(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.undo),
                label: const Text('Undo Dose'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${months[dateTime.month - 1]} ${dateTime.day}, '
        '${dateTime.year} at $hour:$minute $period';
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

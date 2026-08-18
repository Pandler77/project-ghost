import 'package:flutter/material.dart';

import '../../../models/dose_record.dart';
import '../../../models/protocol.dart';
import '../../../theme/app_theme.dart';
import '../calendar_helpers.dart';

class ScheduledDoseItem {
  const ScheduledDoseItem({
    required this.protocol,
    required this.scheduledFor,
    required this.record,
  });

  final Protocol protocol;
  final DateTime scheduledFor;
  final DoseRecord? record;
}

class DayScheduleSheet extends StatelessWidget {
  const DayScheduleSheet({required this.date, required this.items, super.key});

  final DateTime date;
  final List<ScheduledDoseItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.80,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatSelectedDate(date),
                style: const TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                scheduleCountText(items.length),
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'Nothing scheduled for this date.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return _ScheduledDoseRow(
                        item: items[index],
                        selectedDate: date,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledDoseRow extends StatelessWidget {
  const _ScheduledDoseRow({required this.item, required this.selectedDate});

  final ScheduledDoseItem item;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(item.protocol.colorValue);

    final record = item.record;
    final status = record?.status;

    final statusText = switch (status) {
      DoseRecordStatus.taken =>
        record?.completedAt == null
            ? 'Taken'
            : 'Taken at '
                  '${formatCalendarTime(record!.completedAt!)}',
      DoseRecordStatus.skipped => 'Skipped',
      DoseRecordStatus.missed => 'Missed',
      null => unrecordedStatusText(selectedDate),
    };

    final actualAmount = record?.actualAmount ?? item.protocol.dose;

    final amountChanged =
        record != null && actualAmount != record.scheduledAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: protocolColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: protocolColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 52,
            decoration: BoxDecoration(
              color: protocolColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.protocol.name,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (amountChanged) ...[
                  Text(
                    'Actual: $actualAmount',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Scheduled: ${record.scheduledAmount}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else
                  Text(
                    item.protocol.dose,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$statusText • '
                  '${formatCalendarTime(item.scheduledFor)}',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colorScheme.onSurfaceVariant,
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

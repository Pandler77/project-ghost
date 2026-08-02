import 'package:flutter/material.dart';

import '../models/cycle_status.dart';
import '../models/cycle_unit.dart';
import '../models/protocol.dart';
import '../services/cycle_status_service.dart';
import '../theme/app_theme.dart';

class ProtocolCycleTimelineCard extends StatelessWidget {
  const ProtocolCycleTimelineCard({required this.protocol, super.key});

  static const CycleStatusService _cycleStatusService = CycleStatusService();

  final Protocol protocol;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(protocol.colorValue);

    final status = _cycleStatusService.statusForDate(protocol, DateTime.now());

    if (!protocol.useCycle || !status.isCycled) {
      return _ContinuousCycleCard(protocolColor: protocolColor);
    }

    final progress = _progress(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: protocolColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: protocolColor.withValues(alpha: 0.40),
          width: 1.25,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _sectionTitle(status),
                  style: const TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PhaseBadge(
                label: _phaseBadgeLabel(status),
                protocolColor: protocolColor,
                isActive: status.isActive,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            _primaryProgressLabel(status),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),

          if (_cycleNumberLabel(status).isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              _cycleNumberLabel(status),
              style: TextStyle(
                fontSize: AppTypography.caption,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: protocolColor,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          _TimelineDetails(protocol: protocol, status: status),
        ],
      ),
    );
  }

  double _progress(CycleStatus status) {
    final total = status.totalDaysInCurrentPhase;

    if (total <= 0) {
      return status.isBeforeStart ? 0 : 1;
    }

    final current = status.dayInCurrentPhase.clamp(0, total);

    return (current / total).clamp(0.0, 1.0);
  }

  String _sectionTitle(CycleStatus status) {
    if (status.isBeforeStart) {
      return 'Upcoming Cycle';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'Cycle Complete';
    }

    return status.isActive ? 'Current Cycle' : 'Off Cycle';
  }

  String _phaseBadgeLabel(CycleStatus status) {
    if (status.isBeforeStart) {
      return 'Not Started';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'Complete';
    }

    return status.isActive ? 'On Cycle' : 'Off Cycle';
  }

  String _cycleNumberLabel(CycleStatus status) {
    if (!protocol.repeatCycle || status.currentCycleNumber <= 0) {
      return '';
    }

    return 'Cycle ${status.currentCycleNumber}';
  }

  String _primaryProgressLabel(CycleStatus status) {
    if (status.isBeforeStart) {
      return 'Starts ${_formatDate(status.nextTransitionDate)}';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'Protocol cycle finished';
    }

    final currentDay = status.dayInCurrentPhase;
    final totalDays = status.totalDaysInCurrentPhase;

    final unit = status.isActive ? protocol.cycleOnUnit : protocol.cycleOffUnit;

    return _phaseProgressLabel(
      currentDay: currentDay,
      totalDays: totalDays,
      unit: unit,
    );
  }

  String _phaseProgressLabel({
    required int currentDay,
    required int totalDays,
    required CycleUnit unit,
  }) {
    switch (unit) {
      case CycleUnit.days:
        return 'Day $currentDay of $totalDays';

      case CycleUnit.weeks:
        final currentWeek = ((currentDay - 1) ~/ 7) + 1;

        final totalWeeks = (totalDays / 7).ceil();

        return 'Week $currentWeek of $totalWeeks';

      case CycleUnit.months:
        final currentMonth = ((currentDay - 1) ~/ 30) + 1;

        final totalMonths = (totalDays / 30).ceil();

        return 'Month $currentMonth of $totalMonths';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '—';
    }

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

    return '${months[date.month - 1]} ${date.day}';
  }
}

class _TimelineDetails extends StatelessWidget {
  const _TimelineDetails({required this.protocol, required this.status});

  final Protocol protocol;
  final CycleStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.isBeforeStart) {
      return Column(
        children: [
          _TimelineDetailRow(
            label: 'Starts',
            value: _formatDate(status.nextTransitionDate),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TimelineDetailRow(
            label: 'Time Until Start',
            value: _remainingText(status.daysRemainingInCurrentPhase),
          ),
        ],
      );
    }

    if (status.phaseLabel == 'Cycle complete') {
      return Column(
        children: [
          _TimelineDetailRow(
            label: 'Started',
            value: _formatDate(protocol.cycleStartDate),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _TimelineDetailRow(
            label: 'Status',
            value: 'This cycle has ended',
          ),
        ],
      );
    }

    if (status.isActive) {
      final transitionDate = status.nextTransitionDate;

      final endDate = transitionDate?.subtract(const Duration(days: 1));

      return Column(
        children: [
          _TimelineDetailRow(
            label: 'Started',
            value: _formatDate(protocol.cycleStartDate),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TimelineDetailRow(label: 'Ends', value: _formatDate(endDate)),
          const SizedBox(height: AppSpacing.sm),
          _TimelineDetailRow(
            label: 'Remaining',
            value: _remainingText(status.daysRemainingInCurrentPhase),
          ),
          if (protocol.repeatCycle && transitionDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TimelineDetailRow(
              label: 'Next Break',
              value: _formatDate(transitionDate),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        _TimelineDetailRow(
          label: 'Resumes',
          value: _formatDate(status.nextTransitionDate),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TimelineDetailRow(
          label: 'Remaining',
          value: _remainingText(status.daysRemainingInCurrentPhase),
        ),
      ],
    );
  }

  String _remainingText(int days) {
    if (days <= 0) {
      return 'Last Day';
    }

    return '$days ${days == 1 ? 'Day' : 'Days'} Remaining';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '—';
    }

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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}

class _TimelineDetailRow extends StatelessWidget {
  const _TimelineDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
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

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({
    required this.label,
    required this.protocolColor,
    required this.isActive,
  });

  final String label;
  final Color protocolColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? protocolColor.withValues(alpha: 0.18)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? protocolColor : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ContinuousCycleCard extends StatelessWidget {
  const _ContinuousCycleCard({required this.protocolColor});

  final Color protocolColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: protocolColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: protocolColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.all_inclusive, color: protocolColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continuous Protocol',
                  style: TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'No cycle or off period is configured.',
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

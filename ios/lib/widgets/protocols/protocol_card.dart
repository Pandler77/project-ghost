import 'package:flutter/material.dart';

import '../../models/cycle_status.dart';
import '../../models/display_preferences.dart';
import '../../models/protocol.dart';
import '../../models/protocol_status.dart';
import '../../models/schedule_type.dart';
import '../../services/cycle_status_formatter.dart';
import '../../services/cycle_status_service.dart';
import '../../theme/app_theme.dart';

class ProtocolCard extends StatelessWidget {
  const ProtocolCard({
    required this.protocol,
    required this.onPressed,
    required this.displayPreferences,
    super.key,
  });

  static const CycleStatusService _cycleStatusService = CycleStatusService();
  static const CycleStatusFormatter _cycleStatusFormatter =
      CycleStatusFormatter();

  final Protocol protocol;
  final VoidCallback onPressed;
  final DisplayPreferences displayPreferences;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(protocol.colorValue);

    final useProtocolColor = displayPreferences.showProtocolColors;

    final background = switch (protocol.status) {
      ProtocolStatus.active => useProtocolColor
          ? protocolColor.withValues(alpha: 0.10)
          : Theme.of(context).cardTheme.color ?? colorScheme.surface,
      ProtocolStatus.paused => Colors.amber.withValues(alpha: 0.12),
      ProtocolStatus.archived => colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.65,
        ),
    };

    final contentOpacity = protocol.status == ProtocolStatus.archived
        ? 0.65
        : 1.0;

    final cycleStatus = _cycleStatusService.statusForDate(
      protocol,
      DateTime.now(),
    );

    final horizontalPadding = displayPreferences.compactMode
        ? AppSpacing.sm
        : AppSpacing.md;

    final verticalPadding = displayPreferences.compactMode ? 9.0 : 14.0;

    final cardRadius = displayPreferences.compactMode
        ? AppRadius.sm
        : AppRadius.button;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color:
                  protocol.status == ProtocolStatus.active && useProtocolColor
                  ? protocolColor.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant.withValues(
                      alpha: protocol.status == ProtocolStatus.active
                          ? 0.55
                          : 0.0,
                    ),
              width: 1.25,
            ),
          ),
          child: Opacity(
            opacity: contentOpacity,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          protocol.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: displayPreferences.compactMode ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (protocol.status != ProtocolStatus.active)
                        _StatusBadge(status: protocol.status),
                    ],
                  ),
                  SizedBox(
                    height: displayPreferences.compactMode
                        ? 2
                        : AppSpacing.xs,
                  ),
                  Text(
                    protocol.dose,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatSchedule(protocol),
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (protocol.useCycle &&
                      displayPreferences.showCycleStatus) ...[
                    SizedBox(
                      height: displayPreferences.compactMode
                          ? AppSpacing.xs
                          : AppSpacing.sm,
                    ),
                    Text(
                      'Cycle: ${_cycleStatusFormatter.primaryLabel(cycleStatus)}',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (_cycleSecondaryText(cycleStatus).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _cycleSecondaryText(cycleStatus),
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _cycleSecondaryText(CycleStatus status) {
    if (!status.isCycled) return '';

    final parts = <String>[];

    if (status.isBeforeStart) {
      final startDate = status.nextTransitionDate;

      if (startDate != null && displayPreferences.showCycleResumeDate) {
        parts.add('Starts ${_formatShortDate(startDate)}');
      }

      if (displayPreferences.showCycleRemainingDays) {
        parts.add(_remainingText(status.daysRemainingInCurrentPhase));
      }

      return parts.join(' • ');
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'This cycle has ended';
    }

    if (status.isActive) {
      final transitionDate = status.nextTransitionDate;
      final days = status.daysRemainingInCurrentPhase;

      if (transitionDate != null && displayPreferences.showCycleEndDate) {
        final endDate = transitionDate.subtract(const Duration(days: 1));
        parts.add('Ends: ${_formatShortDate(endDate)}');
      }

      if (displayPreferences.showCycleRemainingDays) {
        parts.add(days > 0 ? _remainingText(days) : 'Active');
      }

      return parts.join(' • ');
    }

    final resumeDate = status.nextTransitionDate;

    if (resumeDate != null && displayPreferences.showCycleResumeDate) {
      parts.add('Resumes ${_formatShortDate(resumeDate)}');
    }

    if (displayPreferences.showCycleRemainingDays) {
      parts.add(_remainingText(status.daysRemainingInCurrentPhase));
    }

    return parts.join(' • ');
  }

  String _remainingText(int days) {
    if (days <= 0) return 'Last Day';
    return '$days ${days == 1 ? 'Day' : 'Days'} Remaining';
  }

  String _formatShortDate(DateTime date) {
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

  String _formatSchedule(Protocol protocol) {
    final schedule = protocol.schedule;
    final time = _formatTime(schedule.hour, schedule.minute);

    switch (schedule.type) {
      case ScheduleType.daily:
        return 'Daily • $time';
      case ScheduleType.weekly:
        return '${_weekdayName(schedule.weekday!)} • $time';
      case ScheduleType.everyXDays:
        return 'Every ${schedule.intervalDays} days • $time';
      case ScheduleType.specificDays:
        final days = schedule.specificWeekdays.toList()..sort();
        return '${days.map(_shortWeekdayName).join(' • ')} • $time';
      case ScheduleType.monthly:
        return 'Monthly on day ${schedule.monthlyDay} • $time';
    }
  }

  String _weekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => '',
    };
  }

  String _shortWeekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => '',
    };
  }

  String _formatTime(int hour, int minute) {
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    final formattedMinute = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:$formattedMinute $period';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ProtocolStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final label = switch (status) {
      ProtocolStatus.active => 'Active',
      ProtocolStatus.paused => 'Paused',
      ProtocolStatus.archived => 'Archived',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

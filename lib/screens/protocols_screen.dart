import 'package:flutter/material.dart';

import '../models/cycle_status.dart';
import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../models/schedule_type.dart';
import '../services/cycle_status_formatter.dart';
import '../services/cycle_status_service.dart';
import '../theme/app_theme.dart';
import 'add_protocol_screen.dart';
import 'protocol_details_screen.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({
    required this.protocols,
    required this.onProtocolsChanged,
    required this.onProtocolAdded,
    required this.onProtocolUpdated,
    super.key,
  });

  final List<Protocol> protocols;
  final VoidCallback onProtocolsChanged;
  final Future<void> Function(Protocol protocol) onProtocolAdded;
  final Future<void> Function(Protocol protocol) onProtocolUpdated;

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  Future<void> _openAddProtocol() async {
    final protocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(builder: (_) => const AddProtocolScreen()),
    );

    if (protocol == null || !mounted) {
      return;
    }

    await widget.onProtocolAdded(protocol);

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openProtocolDetails(Protocol protocol) async {
    final updatedProtocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolDetailsScreen(protocol: protocol),
      ),
    );

    if (updatedProtocol == null || !mounted) {
      return;
    }

    final index = widget.protocols.indexWhere(
      (item) => item.id == updatedProtocol.id,
    );

    if (index == -1) {
      return;
    }

    widget.protocols[index] = updatedProtocol;

    await widget.onProtocolUpdated(updatedProtocol);

    if (!mounted) {
      return;
    }

    setState(() {});
    widget.onProtocolsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Manage what you are currently tracking.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAddProtocol,
              icon: const Icon(Icons.add),
              label: const Text('Add Protocol'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.protocols.isEmpty)
            const _EmptyProtocolsState()
          else
            for (var index = 0; index < widget.protocols.length; index++) ...[
              _ProtocolRow(
                protocol: widget.protocols[index],
                onPressed: () {
                  _openProtocolDetails(widget.protocols[index]);
                },
              ),
              if (index < widget.protocols.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow({required this.protocol, required this.onPressed});

  static const CycleStatusService _cycleStatusService = CycleStatusService();

  static const CycleStatusFormatter _cycleStatusFormatter =
      CycleStatusFormatter();

  final Protocol protocol;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final protocolColor = Color(protocol.colorValue);

    final background = switch (protocol.status) {
      ProtocolStatus.active => protocolColor.withValues(alpha: 0.10),

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: protocol.status == ProtocolStatus.active
                  ? protocolColor.withValues(alpha: .45)
                  : Colors.transparent,
              width: 1.25,
            ),
          ),
          child: Opacity(
            opacity: contentOpacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (protocol.status != ProtocolStatus.active)
                              _StatusBadge(status: protocol.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
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
                        if (protocol.useCycle) ...[
                          const SizedBox(height: AppSpacing.sm),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _cycleSecondaryText(CycleStatus status) {
    if (!status.isCycled) {
      return '';
    }

    if (status.isBeforeStart) {
      final startDate = status.nextTransitionDate;

      if (startDate == null) {
        return '';
      }

      final days = status.daysRemainingInCurrentPhase;

      return 'Starts ${_formatShortDate(startDate)}'
          ' • ${_remainingText(days)}';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'This cycle has ended';
    }

    if (status.isActive) {
      final transitionDate = status.nextTransitionDate;
      final days = status.daysRemainingInCurrentPhase;

      if (transitionDate == null) {
        return days > 0 ? _remainingText(days) : 'Active';
      }

      final endDate = transitionDate.subtract(const Duration(days: 1));

      return 'Ends: ${_formatShortDate(endDate)}'
          ' • ${_remainingText(days)}';
    }

    final resumeDate = status.nextTransitionDate;

    if (resumeDate == null) {
      return '';
    }

    final days = status.daysRemainingInCurrentPhase;

    return 'Resumes ${_formatShortDate(resumeDate)}'
        ' • ${_remainingText(days)}';
  }

  String _remainingText(int days) {
    if (days <= 0) {
      return 'Last Day';
    }

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

        return '${days.map(_shortWeekdayName).join(' • ')}'
            ' • $time';

      case ScheduleType.monthly:
        return 'Monthly on day '
            '${schedule.monthlyDay} • $time';
    }
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _shortWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
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

class _EmptyProtocolsState extends StatelessWidget {
  const _EmptyProtocolsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No protocols yet',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Use Add Protocol',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

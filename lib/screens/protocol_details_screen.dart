import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../models/schedule_type.dart';
import '../theme/app_theme.dart';
import 'edit_protocol_screen.dart';

class ProtocolDetailsScreen extends StatefulWidget {
  const ProtocolDetailsScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<ProtocolDetailsScreen> createState() => _ProtocolDetailsScreenState();
}

class _ProtocolDetailsScreenState extends State<ProtocolDetailsScreen> {
  late Protocol _protocol;

  @override
  void initState() {
    super.initState();
    _protocol = widget.protocol;
  }

  void _closeScreen() {
    Navigator.pop(context, _protocol);
  }

  Future<void> _openEditProtocol() async {
    final updatedProtocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProtocolScreen(protocol: _protocol),
      ),
    );

    if (updatedProtocol == null || !mounted) {
      return;
    }

    setState(() {
      _protocol = updatedProtocol;
    });
  }

  void _togglePauseResume() {
    final newStatus = _protocol.status == ProtocolStatus.active
        ? ProtocolStatus.paused
        : ProtocolStatus.active;

    setState(() {
      _protocol = _protocol.copyWith(status: newStatus);
    });
  }

  Future<void> _archiveProtocol() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archive Protocol?'),
          content: const Text(
            'Archived protocols will stop appearing in '
            'your active schedule and calendar. Their '
            'saved history will remain available.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _protocol = _protocol.copyWith(status: ProtocolStatus.archived);
    });
  }

  void _restoreProtocol() {
    setState(() {
      _protocol = _protocol.copyWith(status: ProtocolStatus.paused);
    });
  }

  @override
  Widget build(BuildContext context) {
    final protocolColor = Color(_protocol.colorValue);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _closeScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _closeScreen,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(_protocol.name),
          actions: [
            IconButton(
              onPressed: _openEditProtocol,
              tooltip: 'Edit protocol',
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ProtocolIdentityCard(protocol: _protocol, color: protocolColor),

              const SizedBox(height: AppSpacing.md),

              _StatusBanner(status: _protocol.status),

              const SizedBox(height: AppSpacing.md),

              _DetailTile(label: 'Dose', value: _protocol.dose),

              const Divider(height: AppSpacing.lg),

              _DetailTile(label: 'Schedule', value: _formatSchedule(_protocol)),

              const Divider(height: AppSpacing.lg),

              _DetailTile(
                label: 'Start Date',
                value: _formatDate(_protocol.schedule.startDate),
              ),

              const Divider(height: AppSpacing.lg),

              _DetailTile(
                label: 'Status',
                value: _statusLabel(_protocol.status),
              ),

              const SizedBox(height: AppSpacing.lg),

              _ProtocolActions(
                status: _protocol.status,
                onPauseResume: _togglePauseResume,
                onArchive: _archiveProtocol,
                onRestore: _restoreProtocol,
              ),
            ],
          ),
        ),
      ),
    );
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

        final dayNames = days.map(_shortWeekdayName).join(' • ');

        return '$dayNames • $time';

      case ScheduleType.monthly:
        return 'Monthly on day '
            '${schedule.monthlyDay} • $time';
    }
  }

  String _statusLabel(ProtocolStatus status) {
    switch (status) {
      case ProtocolStatus.active:
        return 'Active';

      case ProtocolStatus.paused:
        return 'Paused';

      case ProtocolStatus.archived:
        return 'Archived';
    }
  }

  String _formatDate(DateTime date) {
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

  String _weekdayName(int weekday) {
    const weekdays = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    return weekdays[weekday] ?? '';
  }

  String _shortWeekdayName(int weekday) {
    const weekdays = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    return weekdays[weekday] ?? '';
  }
}

class _ProtocolIdentityCard extends StatelessWidget {
  const _ProtocolIdentityCard({required this.protocol, required this.color});

  final Protocol protocol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  protocol.name,
                  style: const TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  protocol.dose,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final ProtocolStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = switch (status) {
      ProtocolStatus.active => colorScheme.primary.withValues(alpha: 0.10),
      ProtocolStatus.paused => Colors.amber.withValues(alpha: 0.14),
      ProtocolStatus.archived => colorScheme.surfaceContainerHighest,
    };

    final icon = switch (status) {
      ProtocolStatus.active => Icons.check_circle_outline,
      ProtocolStatus.paused => Icons.pause_circle_outline,
      ProtocolStatus.archived => Icons.archive_outlined,
    };

    final text = switch (status) {
      ProtocolStatus.active => 'Active protocol',
      ProtocolStatus.paused => 'Protocol is paused',
      ProtocolStatus.archived => 'Protocol is archived',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcon.sm),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

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
      ),
    );
  }
}

class _ProtocolActions extends StatelessWidget {
  const _ProtocolActions({
    required this.status,
    required this.onPauseResume,
    required this.onArchive,
    required this.onRestore,
  });

  final ProtocolStatus status;
  final VoidCallback onPauseResume;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    if (status == ProtocolStatus.archived) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onRestore,
          icon: const Icon(Icons.restore),
          label: const Text('Restore as Paused'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPauseResume,
            icon: Icon(
              status == ProtocolStatus.active ? Icons.pause : Icons.play_arrow,
            ),
            label: Text(
              status == ProtocolStatus.active
                  ? 'Pause Protocol'
                  : 'Resume Protocol',
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive Protocol'),
          ),
        ),
      ],
    );
  }
}

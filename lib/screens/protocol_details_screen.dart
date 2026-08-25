import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../models/schedule_type.dart';
import '../theme/app_theme.dart';
import '../widgets/protocol_cycle_timeline_card.dart';
import 'edit_protocol_screen.dart';
import '../theme/arctic_icons.dart';

enum ProtocolDetailsAction { updated, deleted }

class ProtocolDetailsResult {
  const ProtocolDetailsResult.updated(this.protocol)
    : action = ProtocolDetailsAction.updated;

  const ProtocolDetailsResult.deleted()
    : action = ProtocolDetailsAction.deleted,
      protocol = null;

  final ProtocolDetailsAction action;
  final Protocol? protocol;
}

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
    Navigator.pop(context, ProtocolDetailsResult.updated(_protocol));
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

  Future<void> _deleteProtocol() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Protocol?'),
          content: const Text(
            'This will remove the protocol from MODOSE and cancel its reminders. '
            'Logged dose and injection history will remain available. '
            'Any linked MODOSE Supply tracking will be removed. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.pop(context, const ProtocolDetailsResult.deleted());
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
              icon: const Icon(ArcticIcons.edit_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              100,
            ),
            children: [
              _ProtocolHeroCard(protocol: _protocol, color: protocolColor),

              const SizedBox(height: AppSpacing.md),

              ProtocolCycleTimelineCard(protocol: _protocol),

              const SizedBox(height: AppSpacing.md),

              _ProtocolInformationCard(
                dose: _protocol.dose,
                schedule: _formatSchedule(_protocol),
                startDate: _formatDate(_protocol.schedule.startDate),
              ),

              const SizedBox(height: AppSpacing.md),

              _ProtocolControlsCard(
                status: _protocol.status,
                onPauseResume: _togglePauseResume,
                onArchive: _archiveProtocol,
                onRestore: _restoreProtocol,
                onDelete: _deleteProtocol,
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

class _ProtocolHeroCard extends StatelessWidget {
  const _ProtocolHeroCard({required this.protocol, required this.color});

  final Protocol protocol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            color.withValues(alpha: 0.26),
            colors.primaryContainer.withValues(alpha: 0.12),
          ]
        : [
            color.withValues(alpha: 0.14),
            colors.primaryContainer.withValues(alpha: 0.42),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 74,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  protocol.dose,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                _ProtocolStatusPill(status: protocol.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolStatusPill extends StatelessWidget {
  const _ProtocolStatusPill({required this.status});

  final ProtocolStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final config = switch (status) {
      ProtocolStatus.active => (
        'Active',
        Icons.check_circle_outline,
        colors.primary,
      ),
      ProtocolStatus.paused => (
        'Paused',
        Icons.pause_circle_outline,
        Colors.amber.shade700,
      ),
      ProtocolStatus.archived => (
        'Archived',
        ArcticIcons.archive_outlined,
        colors.onSurfaceVariant,
      ),
    };

    final (label, icon, color) = config;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcon.xs, color: color),

          const SizedBox(width: 6),

          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolInformationCard extends StatelessWidget {
  const _ProtocolInformationCard({
    required this.dose,
    required this.schedule,
    required this.startDate,
  });

  final String dose;
  final String schedule;
  final String startDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final cardColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Protocol Details'),

          const SizedBox(height: AppSpacing.md),

          _InformationRow(
            icon: LucideIcons.syringe,
            label: 'Dose',
            value: dose,
          ),

          const _InformationDivider(),

          _InformationRow(
            icon: ArcticIcons.schedule_outlined,
            label: 'Schedule',
            value: schedule,
          ),

          const _InformationDivider(),

          _InformationRow(
            icon: ArcticIcons.event_outlined,
            label: 'Start Date',
            value: startDate,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: AppIcon.sm, color: colors.primary),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationDivider extends StatelessWidget {
  const _InformationDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(height: 1),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: AppTypography.caption,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

class _ProtocolControlsCard extends StatelessWidget {
  const _ProtocolControlsCard({
    required this.status,
    required this.onPauseResume,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  final ProtocolStatus status;
  final VoidCallback onPauseResume;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final cardColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Protocol Controls'),

          const SizedBox(height: AppSpacing.md),

          if (status == ProtocolStatus.archived)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRestore,
                icon: const Icon(ArcticIcons.restore),
                label: const Text('Restore as Paused'),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPauseResume,
                icon: Icon(
                  status == ProtocolStatus.active
                      ? Icons.pause
                      : Icons.play_arrow,
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
                icon: const Icon(ArcticIcons.archive_outlined),
                label: const Text('Archive Protocol'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.65),
            ),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete Protocol'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.55)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

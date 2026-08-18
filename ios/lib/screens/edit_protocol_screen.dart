import 'package:flutter/material.dart';

import '../models/cycle_unit.dart';
import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../models/schedule_type.dart';
import '../theme/app_theme.dart';

import 'editors/edit_appearance_status_screen.dart';
import 'editors/edit_cycle_screen.dart';
import 'editors/edit_protocol_details_screen.dart';
import 'editors/edit_reminder_screen.dart';
import 'editors/edit_injection_rotation_screen.dart';
import 'editors/edit_schedule_screen.dart';
import '../theme/arctic_icons.dart';

class EditProtocolScreen extends StatefulWidget {
  const EditProtocolScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditProtocolScreen> createState() => _EditProtocolScreenState();
}

class _EditProtocolScreenState extends State<EditProtocolScreen> {
  late Protocol _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.protocol;
  }

  Future<void> _openEditor(Widget screen) async {
    final updated = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _draft = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final protocolColor = Color(_draft.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Protocol',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                children: [
                  _EditProtocolHeader(protocol: _draft, color: protocolColor),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Update one section at a time.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _EditSectionTile(
                    icon: ArcticIcons.medication_outlined,
                    title: 'Protocol',
                    subtitle: '${_draft.name} • ${_draft.dose}',
                    onTap: () {
                      _openEditor(EditProtocolDetailsScreen(protocol: _draft));
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _EditSectionTile(
                    icon: ArcticIcons.schedule_outlined,
                    title: 'Schedule',
                    subtitle: _scheduleSummary(_draft),
                    onTap: () {
                      _openEditor(EditScheduleScreen(protocol: _draft));
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _EditSectionTile(
                    icon: ArcticIcons.autorenew_outlined,
                    title: 'Cycle',
                    subtitle: _cycleSummary(_draft),
                    onTap: () {
                      _openEditor(EditCycleScreen(protocol: _draft));
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (_draft.isInjection) ...[
                    _EditSectionTile(
                      icon: ArcticIcons.location_on_outlined,
                      title: 'Injection Site Rotation',
                      subtitle: _rotationSummary(_draft),
                      onTap: () {
                        _openEditor(
                          EditInjectionRotationScreen(protocol: _draft),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  _EditSectionTile(
                    icon: ArcticIcons.notifications_outlined,
                    title: 'Dose Reminder',
                    subtitle: _reminderSummary(_draft),
                    onTap: () {
                      _openEditor(EditReminderScreen(protocol: _draft));
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _EditSectionTile(
                    icon: ArcticIcons.palette_outlined,
                    title: 'Appearance & Status',
                    subtitle: _statusLabel(_draft.status),
                    onTap: () {
                      _openEditor(EditAppearanceStatusScreen(protocol: _draft));
                    },
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context, _draft);
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _scheduleSummary(Protocol protocol) {
    final schedule = protocol.schedule;

    final time = _formatTime(
      TimeOfDay(hour: schedule.hour, minute: schedule.minute),
    );

    return switch (schedule.type) {
      ScheduleType.daily => 'Daily • $time',
      ScheduleType.weekly =>
        'Weekly on ${_weekdayName(schedule.weekday!)} • $time',
      ScheduleType.everyXDays => 'Every ${schedule.intervalDays} days • $time',
      ScheduleType.specificDays =>
        '${(schedule.specificWeekdays.toList()..sort()).map(_shortWeekdayName).join(' • ')} • $time',
      ScheduleType.monthly => 'Monthly on day ${schedule.monthlyDay} • $time',
    };
  }

  String _cycleSummary(Protocol protocol) {
    if (!protocol.useCycle) {
      return 'No cycle';
    }

    final onText =
        '${protocol.cycleOnDuration} '
        '${protocol.cycleOnUnit.label.toLowerCase()} on';

    if (!protocol.repeatCycle) {
      return onText;
    }

    return '$onText • '
        '${protocol.cycleOffDuration} '
        '${protocol.cycleOffUnit.label.toLowerCase()} off';
  }

  String _rotationSummary(Protocol protocol) {
    if (!protocol.rotationEnabled) {
      return 'Off';
    }

    final mode = protocol.rotationMode.name == 'random'
        ? 'Random'
        : 'Sequential';

    return '$mode • ${protocol.enabledInjectionSites.length} sites';
  }

  String _reminderSummary(Protocol protocol) {
    if (!protocol.reminderEnabled) {
      return 'Off';
    }

    final primary = protocol.reminderMinutesBefore == 0
        ? 'At scheduled time'
        : protocol.reminderMinutesBefore == 60
        ? '1 hour before'
        : '${protocol.reminderMinutesBefore} minutes before';

    if (!protocol.missedDoseReminderEnabled) {
      return primary;
    }

    final followUp = protocol.missedDoseReminderMinutesAfter == 60
        ? '1 hour follow-up'
        : protocol.missedDoseReminderMinutesAfter == 120
        ? '2 hour follow-up'
        : '${protocol.missedDoseReminderMinutesAfter} minute follow-up';

    return '$primary • $followUp';
  }

  String _statusLabel(ProtocolStatus status) => switch (status) {
    ProtocolStatus.active => 'Active',
    ProtocolStatus.paused => 'Paused',
    ProtocolStatus.archived => 'Archived',
  };

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  String _weekdayName(int weekday) => switch (weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => '',
  };

  String _shortWeekdayName(int weekday) => switch (weekday) {
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

class _EditProtocolHeader extends StatelessWidget {
  const _EditProtocolHeader({required this.protocol, required this.color});

  final Protocol protocol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            color.withValues(alpha: 0.24),
            colors.primaryContainer.withValues(alpha: 0.12),
          ]
        : [
            color.withValues(alpha: 0.12),
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
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 64,
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
                  maxLines: 1,
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

                _StatusPill(status: protocol.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

class _EditSectionTile extends StatelessWidget {
  const _EditSectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.60),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: AppIcon.md, color: colors.primary),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
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
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.3,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

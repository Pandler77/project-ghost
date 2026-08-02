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
import 'editors/edit_schedule_screen.dart';

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

    if (updated == null || !mounted) return;

    setState(() => _draft = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Protocol')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Update one section at a time.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _EditSectionTile(
              icon: Icons.medication_outlined,
              title: 'Protocol',
              subtitle: '${_draft.name} • ${_draft.dose}',
              onTap: () =>
                  _openEditor(EditProtocolDetailsScreen(protocol: _draft)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EditSectionTile(
              icon: Icons.schedule_outlined,
              title: 'Schedule',
              subtitle: _scheduleSummary(_draft),
              onTap: () => _openEditor(EditScheduleScreen(protocol: _draft)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EditSectionTile(
              icon: Icons.autorenew_outlined,
              title: 'Cycle',
              subtitle: _cycleSummary(_draft),
              onTap: () => _openEditor(EditCycleScreen(protocol: _draft)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EditSectionTile(
              icon: Icons.notifications_outlined,
              title: 'Dose Reminder',
              subtitle: _reminderSummary(_draft),
              onTap: () => _openEditor(EditReminderScreen(protocol: _draft)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EditSectionTile(
              icon: Icons.palette_outlined,
              title: 'Appearance & Status',
              subtitle: _statusLabel(_draft.status),
              onTap: () =>
                  _openEditor(EditAppearanceStatusScreen(protocol: _draft)),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _draft),
                child: const Text('Save Changes'),
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
    if (!protocol.useCycle) return 'No cycle';

    final onText =
        '${protocol.cycleOnDuration} ${protocol.cycleOnUnit.label.toLowerCase()} on';

    if (!protocol.repeatCycle) return onText;

    return '$onText • ${protocol.cycleOffDuration} '
        '${protocol.cycleOffUnit.label.toLowerCase()} off';
  }

  String _reminderSummary(Protocol protocol) {
    if (!protocol.reminderEnabled) return 'Off';

    final primary = protocol.reminderMinutesBefore == 0
        ? 'At scheduled time'
        : protocol.reminderMinutesBefore == 60
        ? '1 hour before'
        : '${protocol.reminderMinutesBefore} minutes before';

    if (!protocol.missedDoseReminderEnabled) return primary;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

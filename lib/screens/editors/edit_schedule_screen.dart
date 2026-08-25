import 'package:flutter/material.dart';

import '../../widgets/app_select_field.dart';

import '../../models/protocol.dart';
import '../../models/protocol_schedule.dart';
import '../../models/schedule_type.dart';
import '../../theme/app_theme.dart';
import '../../theme/arctic_icons.dart';
import '../../widgets/ios_time_picker.dart';

class EditScheduleScreen extends StatefulWidget {
  const EditScheduleScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late final TextEditingController _intervalController;
  late final TextEditingController _monthlyDayController;

  late ScheduleType _selectedType;
  late DateTime _startDate;
  late TimeOfDay _time;
  late int _weekday;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();

    final schedule = widget.protocol.schedule;

    _intervalController = TextEditingController(
      text: schedule.intervalDays?.toString() ?? '7',
    );

    _monthlyDayController = TextEditingController(
      text:
          schedule.monthlyDay?.toString() ?? schedule.startDate.day.toString(),
    );

    _selectedType = schedule.type;
    _startDate = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    _time = TimeOfDay(hour: schedule.hour, minute: schedule.minute);
    _weekday = schedule.weekday ?? schedule.startDate.weekday;
    _weekdays = Set<int>.from(schedule.specificWeekdays);

    if (_weekdays.isEmpty) {
      _weekdays.add(schedule.startDate.weekday);
    }
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _monthlyDayController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    FocusScope.of(context).unfocus();

    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(selected.year, selected.month, selected.day);

      // When changing the anchor date on a weekly schedule, keep the schedule
      // intuitive by moving the weekly weekday with the newly selected date.
      if (_selectedType == ScheduleType.weekly) {
        _weekday = _startDate.weekday;
      }

      // For a newly-created monthly configuration, use the selected start
      // date's day as the sensible default.
      if (_selectedType == ScheduleType.monthly &&
          int.tryParse(_monthlyDayController.text.trim()) == null) {
        _monthlyDayController.text = _startDate.day.toString();
      }
    });
  }

  Future<void> _selectTime() async {
    FocusScope.of(context).unfocus();

    final selected = await showIosTimePicker(
      context: context,
      initialTime: _time,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _time = selected);
  }

  void _changeScheduleType(ScheduleType value) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedType = value;

      if (value == ScheduleType.weekly) {
        _weekday = _startDate.weekday;
      }

      if (value == ScheduleType.specificDays && _weekdays.isEmpty) {
        _weekdays.add(_startDate.weekday);
      }

      if (value == ScheduleType.monthly) {
        final currentDay = int.tryParse(_monthlyDayController.text.trim());

        if (currentDay == null || currentDay < 1 || currentDay > 31) {
          _monthlyDayController.text = _startDate.day.toString();
        }
      }
    });
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_weekdays.contains(weekday)) {
        if (_weekdays.length > 1) {
          _weekdays.remove(weekday);
        }
      } else {
        _weekdays.add(weekday);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  ProtocolSchedule? _createSchedule() {
    final normalizedStartDate = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );

    switch (_selectedType) {
      case ScheduleType.daily:
        return ProtocolSchedule.daily(
          startDate: normalizedStartDate,
          hour: _time.hour,
          minute: _time.minute,
        );

      case ScheduleType.weekly:
        return ProtocolSchedule.weekly(
          startDate: normalizedStartDate,
          hour: _time.hour,
          minute: _time.minute,
          weekday: _weekday,
        );

      case ScheduleType.everyXDays:
        final interval = int.tryParse(_intervalController.text.trim());

        if (interval == null || interval < 1) {
          _showMessage('Enter a valid interval of at least 1 day.');
          return null;
        }

        return ProtocolSchedule.everyXDays(
          startDate: normalizedStartDate,
          hour: _time.hour,
          minute: _time.minute,
          intervalDays: interval,
        );

      case ScheduleType.specificDays:
        if (_weekdays.isEmpty) {
          _showMessage('Select at least one weekday.');
          return null;
        }

        return ProtocolSchedule.specificDays(
          startDate: normalizedStartDate,
          hour: _time.hour,
          minute: _time.minute,
          weekdays: Set<int>.from(_weekdays),
        );

      case ScheduleType.monthly:
        final day = int.tryParse(_monthlyDayController.text.trim());

        if (day == null || day < 1 || day > 31) {
          _showMessage('Enter a monthly day between 1 and 31.');
          return null;
        }

        return ProtocolSchedule.monthly(
          startDate: normalizedStartDate,
          hour: _time.hour,
          minute: _time.minute,
          day: day,
        );
    }
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final schedule = _createSchedule();

    if (schedule == null) {
      return;
    }

    Navigator.pop(context, widget.protocol.copyWith(schedule: schedule));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Change when this protocol is scheduled. Existing completed '
              'dose history is not changed.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppSelectField<ScheduleType>(
              value: _selectedType,
              values: const [
                ScheduleType.daily,
                ScheduleType.weekly,
                ScheduleType.everyXDays,
                ScheduleType.specificDays,
                ScheduleType.monthly,
              ],
              label: 'Schedule type',
              labelBuilder: (value) => switch (value) {
                ScheduleType.daily => 'Daily',
                ScheduleType.weekly => 'Weekly',
                ScheduleType.everyXDays => 'Every X days',
                ScheduleType.specificDays => 'Specific weekdays',
                ScheduleType.monthly => 'Monthly',
              },
              onChanged: _changeScheduleType,
            ),

            if (_selectedType == ScheduleType.weekly) ...[
              const SizedBox(height: AppSpacing.md),
              AppSelectField<int>(
                value: _weekday,
                values: const [
                  DateTime.monday,
                  DateTime.tuesday,
                  DateTime.wednesday,
                  DateTime.thursday,
                  DateTime.friday,
                  DateTime.saturday,
                  DateTime.sunday,
                ],
                label: 'Weekday',
                labelBuilder: (value) => switch (value) {
                  DateTime.monday => 'Monday',
                  DateTime.tuesday => 'Tuesday',
                  DateTime.wednesday => 'Wednesday',
                  DateTime.thursday => 'Thursday',
                  DateTime.friday => 'Friday',
                  DateTime.saturday => 'Saturday',
                  DateTime.sunday => 'Sunday',
                  _ => '',
                },
                onChanged: (value) {
                  setState(() => _weekday = value);
                },
              ),
            ],

            if (_selectedType == ScheduleType.everyXDays) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _intervalController,
                autofocus: false,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval',
                  suffixText: 'days',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            if (_selectedType == ScheduleType.specificDays) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final item in const [
                    (DateTime.monday, 'Mon'),
                    (DateTime.tuesday, 'Tue'),
                    (DateTime.wednesday, 'Wed'),
                    (DateTime.thursday, 'Thu'),
                    (DateTime.friday, 'Fri'),
                    (DateTime.saturday, 'Sat'),
                    (DateTime.sunday, 'Sun'),
                  ])
                    FilterChip(
                      label: Text(item.$2),
                      selected: _weekdays.contains(item.$1),
                      onSelected: (_) => _toggleWeekday(item.$1),
                    ),
                ],
              ),
            ],

            if (_selectedType == ScheduleType.monthly) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _monthlyDayController,
                autofocus: false,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Day of month',
                  helperText:
                      'For shorter months, MODOSE uses the final day.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            _SelectionTile(
              label: 'Start date',
              value: _formatDate(_startDate),
              icon: ArcticIcons.calendar_today_outlined,
              onTap: _selectStartDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SelectionTile(
              label: 'Dose time',
              value: _formatTime(_time),
              icon: ArcticIcons.schedule_outlined,
              onTap: _selectTime,
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
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


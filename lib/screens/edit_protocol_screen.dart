import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../models/protocol_schedule.dart';
import '../models/protocol_status.dart';
import '../models/schedule_type.dart';
import '../theme/app_theme.dart';
import '../theme/protocol_colors.dart';

class EditProtocolScreen extends StatefulWidget {
  const EditProtocolScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditProtocolScreen> createState() => _EditProtocolScreenState();
}

class _EditProtocolScreenState extends State<EditProtocolScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _intervalController;
  late final TextEditingController _monthlyDayController;

  late int _selectedColorValue;
  late ProtocolStatus _selectedStatus;
  late ScheduleType _selectedScheduleType;
  late DateTime _selectedStartDate;
  late TimeOfDay _selectedTime;
  late int _selectedWeekday;
  late Set<int> _selectedWeekdays;

  @override
  void initState() {
    super.initState();

    final schedule = widget.protocol.schedule;

    _nameController = TextEditingController(text: widget.protocol.name);

    _doseController = TextEditingController(text: widget.protocol.dose);

    _intervalController = TextEditingController(
      text: schedule.intervalDays?.toString() ?? '7',
    );

    _monthlyDayController = TextEditingController(
      text: schedule.monthlyDay?.toString() ?? '1',
    );

    _selectedColorValue = widget.protocol.colorValue;
    _selectedStatus = widget.protocol.status;
    _selectedScheduleType = schedule.type;
    _selectedStartDate = schedule.startDate;

    _selectedTime = TimeOfDay(hour: schedule.hour, minute: schedule.minute);

    _selectedWeekday = schedule.weekday ?? schedule.startDate.weekday;

    _selectedWeekdays = Set<int>.from(schedule.specificWeekdays);

    if (_selectedWeekdays.isEmpty) {
      _selectedWeekdays.add(schedule.startDate.weekday);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _intervalController.dispose();
    _monthlyDayController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedStartDate = selectedDate;
    });
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = selectedTime;
    });
  }

  void _toggleSpecificWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(weekday);
        }
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  ProtocolSchedule? _createSchedule() {
    switch (_selectedScheduleType) {
      case ScheduleType.daily:
        return ProtocolSchedule.daily(
          startDate: _selectedStartDate,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        );

      case ScheduleType.weekly:
        return ProtocolSchedule.weekly(
          startDate: _selectedStartDate,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          weekday: _selectedWeekday,
        );

      case ScheduleType.everyXDays:
        final intervalDays = int.tryParse(_intervalController.text.trim());

        if (intervalDays == null || intervalDays < 1) {
          _showValidationMessage('Enter a valid interval of at least 1 day.');

          return null;
        }

        return ProtocolSchedule.everyXDays(
          startDate: _selectedStartDate,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          intervalDays: intervalDays,
        );

      case ScheduleType.specificDays:
        if (_selectedWeekdays.isEmpty) {
          _showValidationMessage('Select at least one weekday.');

          return null;
        }

        return ProtocolSchedule.specificDays(
          startDate: _selectedStartDate,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          weekdays: _selectedWeekdays,
        );

      case ScheduleType.monthly:
        final monthlyDay = int.tryParse(_monthlyDayController.text.trim());

        if (monthlyDay == null || monthlyDay < 1 || monthlyDay > 31) {
          _showValidationMessage('Enter a monthly day between 1 and 31.');

          return null;
        }

        return ProtocolSchedule.monthly(
          startDate: _selectedStartDate,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          day: monthlyDay,
        );
    }
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();

    if (name.isEmpty || dose.isEmpty) {
      _showValidationMessage('Name and dose are required.');

      return;
    }

    final schedule = _createSchedule();

    if (schedule == null) {
      return;
    }

    final updatedProtocol = widget.protocol.copyWith(
      name: name,
      dose: dose,
      colorValue: _selectedColorValue,
      status: _selectedStatus,
      schedule: schedule,
    );

    Navigator.pop(context, updatedProtocol);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Protocol')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _SectionTitle('Protocol'),

            const SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Protocol name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dose',
                hintText: '3 mg',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SectionTitle('Schedule'),

            const SizedBox(height: AppSpacing.sm),

            DropdownButtonFormField<ScheduleType>(
              initialValue: _selectedScheduleType,
              decoration: const InputDecoration(
                labelText: 'Schedule type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ScheduleType.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: ScheduleType.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: ScheduleType.everyXDays,
                  child: Text('Every X days'),
                ),
                DropdownMenuItem(
                  value: ScheduleType.specificDays,
                  child: Text('Specific weekdays'),
                ),
                DropdownMenuItem(
                  value: ScheduleType.monthly,
                  child: Text('Monthly'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedScheduleType = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.md),

            if (_selectedScheduleType == ScheduleType.weekly)
              DropdownButtonFormField<int>(
                initialValue: _selectedWeekday,
                decoration: const InputDecoration(
                  labelText: 'Weekday',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: DateTime.monday,
                    child: Text('Monday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.tuesday,
                    child: Text('Tuesday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.wednesday,
                    child: Text('Wednesday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.thursday,
                    child: Text('Thursday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.friday,
                    child: Text('Friday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.saturday,
                    child: Text('Saturday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.sunday,
                    child: Text('Sunday'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedWeekday = value;
                  });
                },
              ),

            if (_selectedScheduleType == ScheduleType.everyXDays)
              TextField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval',
                  suffixText: 'days',
                  border: OutlineInputBorder(),
                ),
              ),

            if (_selectedScheduleType == ScheduleType.specificDays)
              _SpecificWeekdaySelector(
                selectedWeekdays: _selectedWeekdays,
                onWeekdayPressed: _toggleSpecificWeekday,
              ),

            if (_selectedScheduleType == ScheduleType.monthly)
              TextField(
                controller: _monthlyDayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Day of month',
                  helperText: 'For shorter months, Ghost uses the final day.',
                  border: OutlineInputBorder(),
                ),
              ),

            if (_selectedScheduleType != ScheduleType.daily)
              const SizedBox(height: AppSpacing.md),

            _SelectionTile(
              label: 'Start date',
              value: _formatDate(_selectedStartDate),
              icon: Icons.calendar_today_outlined,
              onTap: _selectStartDate,
            ),

            const SizedBox(height: AppSpacing.sm),

            _SelectionTile(
              label: 'Dose time',
              value: _formatTime(_selectedTime),
              icon: Icons.schedule_outlined,
              onTap: _selectTime,
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SectionTitle('Protocol color'),

            const SizedBox(height: AppSpacing.xs),

            Text(
              'This color identifies the protocol throughout Ghost.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final colorValue in ProtocolColors.available)
                  _ProtocolColorChoice(
                    colorValue: colorValue,
                    isSelected: _selectedColorValue == colorValue,
                    onTap: () {
                      setState(() {
                        _selectedColorValue = colorValue;
                      });
                    },
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SectionTitle('Status'),

            const SizedBox(height: AppSpacing.sm),

            DropdownButtonFormField<ProtocolStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Protocol status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ProtocolStatus.active,
                  child: Text('Active'),
                ),
                DropdownMenuItem(
                  value: ProtocolStatus.paused,
                  child: Text('Paused'),
                ),
                DropdownMenuItem(
                  value: ProtocolStatus.archived,
                  child: Text('Archived'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedStatus = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppTypography.body,
        fontWeight: FontWeight.w600,
      ),
    );
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

class _SpecificWeekdaySelector extends StatelessWidget {
  const _SpecificWeekdaySelector({
    required this.selectedWeekdays,
    required this.onWeekdayPressed,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<int> onWeekdayPressed;

  @override
  Widget build(BuildContext context) {
    const weekdays = [
      (DateTime.monday, 'Mon'),
      (DateTime.tuesday, 'Tue'),
      (DateTime.wednesday, 'Wed'),
      (DateTime.thursday, 'Thu'),
      (DateTime.friday, 'Fri'),
      (DateTime.saturday, 'Sat'),
      (DateTime.sunday, 'Sun'),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final weekday in weekdays)
          FilterChip(
            label: Text(weekday.$2),
            selected: selectedWeekdays.contains(weekday.$1),
            onSelected: (_) {
              onWeekdayPressed(weekday.$1);
            },
          ),
      ],
    );
  }
}

class _ProtocolColorChoice extends StatelessWidget {
  const _ProtocolColorChoice({
    required this.colorValue,
    required this.isSelected,
    required this.onTap,
  });

  final int colorValue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select protocol color',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}

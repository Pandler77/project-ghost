import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/daily_protocol_item.dart';
import '../../models/measurement_system.dart';
import '../../models/schedule_type.dart';
import '../../models/protocol.dart';
import '../../widgets/app_select_field.dart';
import '../../models/weight_record.dart';
import '../../theme/app_theme.dart';
import '../../utils/weight_display.dart';
import '../../theme/arctic_icons.dart';

class EditDaySheet extends StatefulWidget {
  const EditDaySheet({
    required this.date,
    required this.protocolItems,
    required this.allProtocols,
    required this.weightRecord,
    required this.measurementSystem,
    required this.onSave,
    super.key,
  });

  final DateTime date;
  final List<DailyProtocolItem> protocolItems;
  final List<Protocol> allProtocols;
  final WeightRecord? weightRecord;
  final MeasurementSystem measurementSystem;

  final ValueChanged<EditDayResult> onSave;

  @override
  State<EditDaySheet> createState() => _EditDaySheetState();
}

class _EditDaySheetState extends State<EditDaySheet> {
  late final TextEditingController _weightController;

  late final List<_EditableProtocolState> _protocolStates;
  final List<_ExtraOccurrenceState> _extraOccurrences = [];

  bool _deleteWeight = false;

  @override
  void initState() {
    super.initState();

    final storedWeight = widget.weightRecord?.weight;

    _weightController = TextEditingController(
      text: storedWeight == null
          ? ''
          : WeightDisplay.displayValue(
              storedWeight,
              widget.measurementSystem,
            ).toStringAsFixed(1),
    );

    _protocolStates = widget.protocolItems.map((item) {
      return _EditableProtocolState(
        item: item,
        isTaken: item.isTaken,
        amountController: TextEditingController(text: item.displayedAmount),
        completedTime: item.record?.completedAt == null
            ? TimeOfDay.fromDateTime(item.scheduledFor)
            : TimeOfDay.fromDateTime(item.record!.completedAt!),
        shiftFutureSchedule: false,
        shiftedDate: DateTime(
          item.scheduledFor.year,
          item.scheduledFor.month,
          item.scheduledFor.day,
        ),
        shiftedTime: TimeOfDay.fromDateTime(item.scheduledFor),
        oneOffAction: OneOffAction.none,
        oneOffDate: DateTime(
          item.scheduledFor.year,
          item.scheduledFor.month,
          item.scheduledFor.day,
        ),
        oneOffTime: TimeOfDay.fromDateTime(item.scheduledFor),
      );
    }).toList();
  }

  @override
  void dispose() {
    _weightController.dispose();

    for (final state in _protocolStates) {
      state.amountController.dispose();
    }

    super.dispose();
  }

  Future<void> _selectCompletionTime(
    _EditableProtocolState protocolState,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: protocolState.completedTime,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      protocolState.completedTime = selectedTime;
    });
  }

  Future<void> _selectShiftedDate(
    _EditableProtocolState protocolState,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: protocolState.shiftedDate,
      firstDate: DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
      ),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      protocolState.shiftedDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  Future<void> _selectShiftedTime(
    _EditableProtocolState protocolState,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: protocolState.shiftedTime,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      protocolState.shiftedTime = selectedTime;
    });
  }

  Future<void> _selectOneOffDate(
    _EditableProtocolState protocolState,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: protocolState.oneOffDate,
      firstDate: DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
      ),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      protocolState.oneOffDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  Future<void> _selectOneOffTime(
    _EditableProtocolState protocolState,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: protocolState.oneOffTime,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      protocolState.oneOffTime = selectedTime;
    });
  }

  void _addExtraOccurrence() {
    if (widget.allProtocols.isEmpty) {
      return;
    }

    final protocol = widget.allProtocols.first;

    setState(() {
      _extraOccurrences.add(
        _ExtraOccurrenceState(
          protocol: protocol,
          time: TimeOfDay(
            hour: protocol.schedule.hour,
            minute: protocol.schedule.minute,
          ),
        ),
      );
    });
  }

  Future<void> _selectExtraTime(_ExtraOccurrenceState state) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: state.time,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      state.time = selectedTime;
    });
  }

  void _save() {
    final weightText = _weightController.text.trim();

    double? weight;

    if (!_deleteWeight && weightText.isNotEmpty) {
      final enteredWeight = double.tryParse(weightText);

      if (enteredWeight == null || enteredWeight <= 0) {
        _showValidationMessage('Enter a valid weight.');

        return;
      }

      weight = _weightToStoredPounds(enteredWeight, widget.measurementSystem);
    }

    final protocolChanges = <EditDayProtocolResult>[];

    for (final state in _protocolStates) {
      final amount = state.amountController.text.trim();

      if (amount.isEmpty) {
        _showValidationMessage(
          'Enter an amount for ${state.item.protocol.name}.',
        );

        return;
      }

      protocolChanges.add(
        EditDayProtocolResult(
          item: state.item,
          isTaken: state.isTaken,
          actualAmount: amount,
          completedTime: state.completedTime,
          shiftFutureSchedule: state.shiftFutureSchedule,
          shiftedDate: state.shiftedDate,
          shiftedTime: state.shiftedTime,
          oneOffAction: state.oneOffAction,
          oneOffDate: state.oneOffDate,
          oneOffTime: state.oneOffTime,
        ),
      );
    }

    widget.onSave(
      EditDayResult(
        weight: weight,
        deleteWeight: _deleteWeight,
        protocolChanges: protocolChanges,
        extraOccurrences: _extraOccurrences
            .map(
              (state) => EditDayExtraOccurrenceResult(
                protocol: state.protocol,
                time: state.time,
              ),
            )
            .toList(),
      ),
    );
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final weightUnit = WeightDisplay.unit(widget.measurementSystem);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit ${_formatDate(widget.date)}',
                      style: const TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const _SectionTitle(
                    title: 'Protocols',
                    icon: LucideIcons.syringe,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_protocolStates.isEmpty)
                    const _EmptySectionMessage(
                      message: 'No protocols are scheduled for this date.',
                    )
                  else
                    for (
                      var index = 0;
                      index < _protocolStates.length;
                      index++
                    ) ...[
                      _ProtocolEditor(
                        state: _protocolStates[index],
                        onTakenChanged: (value) {
                          setState(() {
                            _protocolStates[index].isTaken = value;
                          });
                        },
                        onTimePressed: () {
                          _selectCompletionTime(_protocolStates[index]);
                        },
                        onShiftFutureChanged: (value) {
                          setState(() {
                            _protocolStates[index].shiftFutureSchedule = value;
                          });
                        },
                        onShiftDatePressed: () {
                          _selectShiftedDate(_protocolStates[index]);
                        },
                        onShiftTimePressed: () {
                          _selectShiftedTime(_protocolStates[index]);
                        },
                        onOneOffActionChanged: (value) {
                          setState(() {
                            final state = _protocolStates[index];
                            state.oneOffAction = value;

                            if (value != OneOffAction.none) {
                              state.shiftFutureSchedule = false;
                            }
                          });
                        },
                        onOneOffDatePressed: () {
                          _selectOneOffDate(_protocolStates[index]);
                        },
                        onOneOffTimePressed: () {
                          _selectOneOffTime(_protocolStates[index]);
                        },
                      ),
                      if (index < _protocolStates.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: widget.allProtocols.isEmpty
                        ? null
                        : _addExtraOccurrence,
                    icon: const Icon(Icons.add),
                    label: const Text('Add one-off scheduled dose'),
                  ),
                  for (var index = 0;
                      index < _extraOccurrences.length;
                      index++) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ExtraOccurrenceEditor(
                      state: _extraOccurrences[index],
                      protocols: widget.allProtocols,
                      onProtocolChanged: (protocol) {
                        setState(() {
                          _extraOccurrences[index].protocol = protocol;
                        });
                      },
                      onTimePressed: () {
                        _selectExtraTime(_extraOccurrences[index]);
                      },
                      onRemove: () {
                        setState(() {
                          _extraOccurrences.removeAt(index);
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionTitle(
                    title: 'Weight',
                    icon: ArcticIcons.monitor_weight_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _weightController,
                    enabled: !_deleteWeight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: weightUnit,
                      hintText:
                          widget.measurementSystem == MeasurementSystem.metric
                          ? '158.8'
                          : '350.0',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (widget.weightRecord != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CheckboxListTile(
                      value: _deleteWeight,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Delete weight entry for this date'),
                      onChanged: (value) {
                        setState(() {
                          _deleteWeight = value ?? false;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolEditor extends StatelessWidget {
  const _ProtocolEditor({
    required this.state,
    required this.onTakenChanged,
    required this.onTimePressed,
    required this.onShiftFutureChanged,
    required this.onShiftDatePressed,
    required this.onShiftTimePressed,
    required this.onOneOffActionChanged,
    required this.onOneOffDatePressed,
    required this.onOneOffTimePressed,
  });

  final _EditableProtocolState state;
  final ValueChanged<bool> onTakenChanged;
  final VoidCallback onTimePressed;
  final ValueChanged<bool> onShiftFutureChanged;
  final VoidCallback onShiftDatePressed;
  final VoidCallback onShiftTimePressed;
  final ValueChanged<OneOffAction> onOneOffActionChanged;
  final VoidCallback onOneOffDatePressed;
  final VoidCallback onOneOffTimePressed;

  @override
  Widget build(BuildContext context) {
    final protocolColor = Color(state.item.protocol.colorValue);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: protocolColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: protocolColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(
                  color: protocolColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  state.item.protocol.name,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(value: state.isTaken, onChanged: onTakenChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: state.amountController,
            decoration: const InputDecoration(
              labelText: 'Actual amount',
              border: OutlineInputBorder(),
            ),
          ),
          if (state.isTaken) ...[
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.button),
                onTap: onTimePressed,
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
                      const Icon(ArcticIcons.schedule_outlined),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completion time',
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(state.completedTime),
                              style: const TextStyle(
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
            ),
          ],
          if (state.canShiftFutureSchedule) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.shiftFutureSchedule,
              onChanged: state.item.record == null &&
                      state.oneOffAction == OneOffAction.none
                  ? onShiftFutureChanged
                  : null,
              title: const Text(
                'Shift future schedule from this dose',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                state.item.record == null
                    ? 'Move this scheduled dose and keep the same interval going forward.'
                    : 'Completed or logged doses cannot re-anchor the schedule.',
              ),
            ),
            if (state.shiftFutureSchedule) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShiftDatePressed,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_formatDate(state.shiftedDate)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShiftTimePressed,
                      icon: const Icon(ArcticIcons.schedule_outlined),
                      label: Text(_formatTime(state.shiftedTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The next dose will remain ${state.intervalDays} days after the moved dose.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          if (state.item.record == null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            Text(
              'This occurrence only',
              style: TextStyle(
                fontSize: AppTypography.caption,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<OneOffAction>(
              segments: const [
                ButtonSegment(
                  value: OneOffAction.none,
                  label: Text('Normal'),
                ),
                ButtonSegment(
                  value: OneOffAction.move,
                  label: Text('Move'),
                ),
                ButtonSegment(
                  value: OneOffAction.suppress,
                  label: Text('Remove'),
                ),
              ],
              selected: {state.oneOffAction},
              onSelectionChanged: (selection) {
                onOneOffActionChanged(selection.first);
              },
            ),
            if (state.oneOffAction == OneOffAction.move) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOneOffDatePressed,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_formatDate(state.oneOffDate)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOneOffTimePressed,
                      icon: const Icon(ArcticIcons.schedule_outlined),
                      label: Text(_formatTime(state.oneOffTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Only this dose moves. The recurring schedule after it stays unchanged.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (state.oneOffAction == OneOffAction.suppress) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This scheduled occurrence will be removed without marking it skipped.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ExtraOccurrenceEditor extends StatelessWidget {
  const _ExtraOccurrenceEditor({
    required this.state,
    required this.protocols,
    required this.onProtocolChanged,
    required this.onTimePressed,
    required this.onRemove,
  });

  final _ExtraOccurrenceState state;
  final List<Protocol> protocols;
  final ValueChanged<Protocol> onProtocolChanged;
  final VoidCallback onTimePressed;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: AppSelectField<Protocol>(
              value: state.protocol,
              values: protocols,
              label: 'Protocol',
              labelBuilder: (protocol) => protocol.name,
              onChanged: onProtocolChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: onTimePressed,
              child: Text(_formatTime(state.time)),
            ),
          ),
          IconButton(
            tooltip: 'Remove one-off dose',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIcon.sm),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _EditableProtocolState {
  _EditableProtocolState({
    required this.item,
    required this.isTaken,
    required this.amountController,
    required this.completedTime,
    required this.shiftFutureSchedule,
    required this.shiftedDate,
    required this.shiftedTime,
    required this.oneOffAction,
    required this.oneOffDate,
    required this.oneOffTime,
  });

  final DailyProtocolItem item;
  final TextEditingController amountController;

  bool isTaken;
  TimeOfDay completedTime;
  bool shiftFutureSchedule;
  DateTime shiftedDate;
  TimeOfDay shiftedTime;
  OneOffAction oneOffAction;
  DateTime oneOffDate;
  TimeOfDay oneOffTime;

  bool get canShiftFutureSchedule =>
      item.protocol.schedule.type == ScheduleType.everyXDays &&
      (item.protocol.schedule.intervalDays ?? 0) > 0;

  int get intervalDays => item.protocol.schedule.intervalDays ?? 0;
}

class EditDayResult {
  const EditDayResult({
    required this.weight,
    required this.deleteWeight,
    required this.protocolChanges,
    required this.extraOccurrences,
  });

  /// Always returned in pounds for canonical database storage.
  final double? weight;

  final bool deleteWeight;
  final List<EditDayProtocolResult> protocolChanges;
  final List<EditDayExtraOccurrenceResult> extraOccurrences;
}

class EditDayProtocolResult {
  const EditDayProtocolResult({
    required this.item,
    required this.isTaken,
    required this.actualAmount,
    required this.completedTime,
    required this.shiftFutureSchedule,
    required this.shiftedDate,
    required this.shiftedTime,
    required this.oneOffAction,
    required this.oneOffDate,
    required this.oneOffTime,
  });

  final DailyProtocolItem item;
  final bool isTaken;
  final String actualAmount;
  final TimeOfDay completedTime;

  final bool shiftFutureSchedule;
  final DateTime shiftedDate;
  final TimeOfDay shiftedTime;

  final OneOffAction oneOffAction;
  final DateTime oneOffDate;
  final TimeOfDay oneOffTime;
}

class EditDayExtraOccurrenceResult {
  const EditDayExtraOccurrenceResult({
    required this.protocol,
    required this.time,
  });

  final Protocol protocol;
  final TimeOfDay time;
}

class _ExtraOccurrenceState {
  _ExtraOccurrenceState({
    required this.protocol,
    required this.time,
  });

  Protocol protocol;
  TimeOfDay time;
}

enum OneOffAction { none, move, suppress }

double _weightToStoredPounds(
  double displayedWeight,
  MeasurementSystem measurementSystem,
) {
  if (measurementSystem == MeasurementSystem.metric) {
    return displayedWeight / 0.45359237;
  }

  return displayedWeight;
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

  return '${months[date.month - 1]} ${date.day}';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

  final minute = time.minute.toString().padLeft(2, '0');

  final period = time.period == DayPeriod.am ? 'AM' : 'PM';

  return '$hour:$minute $period';
}

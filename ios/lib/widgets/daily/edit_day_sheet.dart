import 'package:flutter/material.dart';

import '../../models/daily_protocol_item.dart';
import '../../models/measurement_system.dart';
import '../../models/weight_record.dart';
import '../../theme/app_theme.dart';
import '../../utils/weight_display.dart';
import '../../theme/arctic_icons.dart';

class EditDaySheet extends StatefulWidget {
  const EditDaySheet({
    required this.date,
    required this.protocolItems,
    required this.weightRecord,
    required this.measurementSystem,
    required this.onSave,
    super.key,
  });

  final DateTime date;
  final List<DailyProtocolItem> protocolItems;
  final WeightRecord? weightRecord;
  final MeasurementSystem measurementSystem;

  final ValueChanged<EditDayResult> onSave;

  @override
  State<EditDaySheet> createState() => _EditDaySheetState();
}

class _EditDaySheetState extends State<EditDaySheet> {
  late final TextEditingController _weightController;

  late final List<_EditableProtocolState> _protocolStates;

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
        ),
      );
    }

    widget.onSave(
      EditDayResult(
        weight: weight,
        deleteWeight: _deleteWeight,
        protocolChanges: protocolChanges,
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
                    icon: ArcticIcons.medication_outlined,
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
                      ),
                      if (index < _protocolStates.length - 1)
                        const SizedBox(height: AppSpacing.sm),
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
  });

  final _EditableProtocolState state;
  final ValueChanged<bool> onTakenChanged;
  final VoidCallback onTimePressed;

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
  });

  final DailyProtocolItem item;
  final TextEditingController amountController;

  bool isTaken;
  TimeOfDay completedTime;
}

class EditDayResult {
  const EditDayResult({
    required this.weight,
    required this.deleteWeight,
    required this.protocolChanges,
  });

  /// Always returned in pounds for canonical database storage.
  final double? weight;

  final bool deleteWeight;
  final List<EditDayProtocolResult> protocolChanges;
}

class EditDayProtocolResult {
  const EditDayProtocolResult({
    required this.item,
    required this.isTaken,
    required this.actualAmount,
    required this.completedTime,
  });

  final DailyProtocolItem item;
  final bool isTaken;
  final String actualAmount;
  final TimeOfDay completedTime;
}

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

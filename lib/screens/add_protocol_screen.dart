import 'package:flutter/material.dart';

import '../models/cycle_unit.dart';
import '../models/protocol.dart';
import '../models/protocol_category.dart';
import '../models/protocol_preset.dart';
import '../models/protocol_schedule.dart';
import '../services/protocol_preset_service.dart';
import '../theme/app_theme.dart';
import '../theme/protocol_colors.dart';
import '../widgets/ios_time_picker.dart';
import '../widgets/protocol_editor/protocol_editor.dart';
import '../widgets/wizard_step_indicator.dart';

enum ScheduleOption { daily, weekly, everyXDays, specificDays, monthly }

class AddProtocolScreen extends StatefulWidget {
  const AddProtocolScreen({super.key});

  @override
  State<AddProtocolScreen> createState() => _AddProtocolScreenState();
}

class _AddProtocolScreenState extends State<AddProtocolScreen> {
  final ProtocolPresetService _presetService = ProtocolPresetService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _doseController = TextEditingController();

  final TextEditingController _customUnitController = TextEditingController();

  final TextEditingController _intervalDaysController = TextEditingController();

  final TextEditingController _cycleOnDurationController =
      TextEditingController(text: '12');

  final TextEditingController _cycleOffDurationController =
      TextEditingController(text: '4');

  static const List<String> _commonUnits = [
    'mg',
    'mcg',
    'g',
    'IU',
    'mL',
    'units',
    'tablet',
    'capsule',
    'drop',
    'patch',
    'serving',
  ];

  int _currentStep = 0;

  ProtocolCategory? _selectedCategory;
  ProtocolPreset? _selectedPreset;

  String? _selectedUnit;
  bool _useCustomUnit = false;

  ScheduleOption? _selectedSchedule;
  int? _selectedWeeklyDay;
  int? _selectedMonthlyDay;

  final Set<int> _selectedSpecificDays = {};

  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  DateTime _selectedStartDate = DateTime.now();
  int _selectedColorValue = Protocol.defaultColorValue;

  bool _useCycle = false;
  DateTime _cycleStartDate = DateTime.now();
  CycleUnit _cycleOnUnit = CycleUnit.weeks;
  CycleUnit _cycleOffUnit = CycleUnit.weeks;
  bool _repeatCycle = true;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _customUnitController.dispose();
    _intervalDaysController.dispose();
    _cycleOnDurationController.dispose();
    _cycleOffDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Protocol'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WizardStepIndicator(
                currentStep: _currentStep,
                totalSteps: 7,
                label: 'Step ${_currentStep + 1} of 7',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: switch (_currentStep) {
                  0 => _buildCategoryStep(context),
                  1 => _buildNameStep(context),
                  2 => _buildDoseStep(context),
                  3 => _buildScheduleStep(context),
                  4 => _buildTimeStep(context),
                  5 => _buildCycleStep(context),
                  6 => _buildReviewStep(context),
                  _ => const SizedBox.shrink(),
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue() ? _handleContinue : null,
                  child: Text(
                    _currentStep == 0
                        ? 'Continue'
                        : _currentStep == 6
                        ? 'Save Protocol'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _handleContinue() {
    if (_currentStep < 6) {
      setState(() {
        _currentStep++;
      });

      return;
    }

    final protocol = _createProtocol();

    Navigator.pop(context, protocol);
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedCategory != null;

      case 1:
        return _nameController.text.trim().isNotEmpty;

      case 2:
        final dose = double.tryParse(_doseController.text.trim());

        return dose != null && dose > 0 && _currentUnit.isNotEmpty;

      case 3:
        switch (_selectedSchedule) {
          case ScheduleOption.daily:
            return true;

          case ScheduleOption.weekly:
            return _selectedWeeklyDay != null;

          case ScheduleOption.everyXDays:
            final interval = int.tryParse(_intervalDaysController.text.trim());

            return interval != null && interval > 0;

          case ScheduleOption.specificDays:
            return _selectedSpecificDays.isNotEmpty;

          case ScheduleOption.monthly:
            return _selectedMonthlyDay != null;

          case null:
            return false;
        }

      case 4:
        return true;

      case 5:
        if (!_useCycle) {
          return true;
        }

        final onDuration = int.tryParse(_cycleOnDurationController.text.trim());

        final offDuration = int.tryParse(
          _cycleOffDurationController.text.trim(),
        );

        return onDuration != null &&
            onDuration > 0 &&
            offDuration != null &&
            offDuration >= 0;

      case 6:
        return true;

      default:
        return false;
    }
  }

  String get _currentUnit {
    if (_useCustomUnit) {
      return _customUnitController.text.trim();
    }

    return _selectedUnit?.trim() ?? '';
  }

  String get _formattedDose {
    return '${_doseController.text.trim()} $_currentUnit';
  }

  Widget _buildCategoryStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you adding?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose the option that best matches what you want to track.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView(
            children: [
              _CategoryTile(
                title: 'Peptide',
                subtitle: 'Peptides and research compounds',
                icon: Icons.science_outlined,
                isSelected: _selectedCategory == ProtocolCategory.peptide,
                onTap: () {
                  _selectCategory(ProtocolCategory.peptide);
                },
              ),
              _CategoryTile(
                title: 'Prescription',
                subtitle: 'Prescribed medications',
                icon: Icons.medication_outlined,
                isSelected: _selectedCategory == ProtocolCategory.prescription,
                onTap: () {
                  _selectCategory(ProtocolCategory.prescription);
                },
              ),
              _CategoryTile(
                title: 'Supplement',
                subtitle: 'Supplements and over-the-counter products',
                icon: Icons.local_florist_outlined,
                isSelected: _selectedCategory == ProtocolCategory.supplement,
                onTap: () {
                  _selectCategory(ProtocolCategory.supplement);
                },
              ),
              _CategoryTile(
                title: 'Vitamin',
                subtitle: 'Vitamins and minerals',
                icon: Icons.health_and_safety_outlined,
                isSelected: _selectedCategory == ProtocolCategory.vitamin,
                onTap: () {
                  _selectCategory(ProtocolCategory.vitamin);
                },
              ),
              _CategoryTile(
                title: 'Custom',
                subtitle: 'Create a tracker your own way',
                icon: Icons.tune_outlined,
                isSelected: _selectedCategory == ProtocolCategory.custom,
                onTap: () {
                  _selectCategory(ProtocolCategory.custom);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep(BuildContext context) {
    final category = _selectedCategory;

    if (category == null) {
      return const SizedBox.shrink();
    }

    final query = _nameController.text;

    final presets = category == ProtocolCategory.custom
        ? <ProtocolPreset>[]
        : _presetService.search(category: category, query: query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is it called?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          category == ProtocolCategory.custom
              ? 'Enter the name you want Ghost to display.'
              : 'Search the list or enter your own name.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            setState(() {
              final exactMatch = _presetService.findByName(
                category: category,
                name: value,
              );

              _selectedPreset = exactMatch;

              if (exactMatch != null) {
                _applyPresetUnit(exactMatch.defaultUnit);
              }
            });
          },
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: _searchHint(category),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _nameController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      setState(() {
                        _nameController.clear();
                        _selectedPreset = null;
                        _selectedUnit = null;
                        _useCustomUnit = false;
                        _customUnitController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (category != ProtocolCategory.custom) ...[
          Text(
            query.trim().isEmpty ? 'Common options' : 'Matches',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: presets.isEmpty
                ? _CustomNameMessage(name: query.trim())
                : ListView.separated(
                    itemCount: presets.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final preset = presets[index];

                      return _PresetTile(
                        preset: preset,
                        isSelected: _selectedPreset?.name == preset.name,
                        onTap: () {
                          setState(() {
                            _selectedPreset = preset;
                            _nameController.text = preset.name;

                            _nameController.selection = TextSelection.collapsed(
                              offset: preset.name.length,
                            );

                            _applyPresetUnit(preset.defaultUnit);
                          });
                        },
                      );
                    },
                  ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }

  Widget _buildDoseStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final dropdownValue = _useCustomUnit
        ? 'Other'
        : _commonUnits.contains(_selectedUnit)
        ? _selectedUnit
        : null;

    return ListView(
      children: [
        const Text(
          'How much?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Enter the amount for each scheduled dose.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _doseController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) {
            setState(() {});
          },
          decoration: const InputDecoration(
            labelText: 'Dose',
            hintText: '3',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          key: ValueKey(dropdownValue),
          initialValue: dropdownValue,
          decoration: const InputDecoration(
            labelText: 'Unit',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Choose a unit'),
          items: [
            for (final unit in _commonUnits)
              DropdownMenuItem(value: unit, child: Text(unit)),
            const DropdownMenuItem(value: 'Other', child: Text('Other...')),
          ],
          onChanged: (value) {
            setState(() {
              if (value == 'Other') {
                _useCustomUnit = true;
                _selectedUnit = null;
              } else {
                _useCustomUnit = false;
                _selectedUnit = value;
                _customUnitController.clear();
              }
            });
          },
        ),
        if (_useCustomUnit) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _customUnitController,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Custom unit',
              hintText: 'pump, scoop, spray...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (_selectedPreset?.defaultUnit != null && !_useCustomUnit) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Suggested unit based on '
            '${_selectedPreset!.name}.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const Text(
          'How often?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose when this protocol should appear.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ScheduleTile(
          title: 'Daily',
          subtitle: 'Every day',
          icon: Icons.today_outlined,
          isSelected: _selectedSchedule == ScheduleOption.daily,
          onTap: () {
            _selectSchedule(ScheduleOption.daily);
          },
        ),
        _ScheduleTile(
          title: 'Weekly',
          subtitle: 'Once each week',
          icon: Icons.date_range_outlined,
          isSelected: _selectedSchedule == ScheduleOption.weekly,
          onTap: () {
            _selectSchedule(ScheduleOption.weekly);
          },
        ),
        if (_selectedSchedule == ScheduleOption.weekly) ...[
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<int>(
            key: ValueKey(_selectedWeeklyDay),
            initialValue: _selectedWeeklyDay,
            decoration: const InputDecoration(
              labelText: 'Day of the week',
              border: OutlineInputBorder(),
            ),
            items: _weekdayItems(),
            onChanged: (value) {
              setState(() {
                _selectedWeeklyDay = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _ScheduleTile(
          title: 'Every X Days',
          subtitle: 'Repeat after a custom number of days',
          icon: Icons.repeat_outlined,
          isSelected: _selectedSchedule == ScheduleOption.everyXDays,
          onTap: () {
            _selectSchedule(ScheduleOption.everyXDays);
          },
        ),
        if (_selectedSchedule == ScheduleOption.everyXDays) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _intervalDaysController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Repeat every',
              hintText: '6',
              suffixText: 'days',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _ScheduleTile(
          title: 'Specific Days',
          subtitle: 'Choose multiple days of the week',
          icon: Icons.calendar_view_week_outlined,
          isSelected: _selectedSchedule == ScheduleOption.specificDays,
          onTap: () {
            _selectSchedule(ScheduleOption.specificDays);
          },
        ),
        if (_selectedSchedule == ScheduleOption.specificDays) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _dayChip('Mon', DateTime.monday),
              _dayChip('Tue', DateTime.tuesday),
              _dayChip('Wed', DateTime.wednesday),
              _dayChip('Thu', DateTime.thursday),
              _dayChip('Fri', DateTime.friday),
              _dayChip('Sat', DateTime.saturday),
              _dayChip('Sun', DateTime.sunday),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _ScheduleTile(
          title: 'Monthly',
          subtitle: 'Once each month',
          icon: Icons.calendar_month_outlined,
          isSelected: _selectedSchedule == ScheduleOption.monthly,
          onTap: () {
            _selectSchedule(ScheduleOption.monthly);
          },
        ),
        if (_selectedSchedule == ScheduleOption.monthly) ...[
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<int>(
            key: ValueKey(_selectedMonthlyDay),
            initialValue: _selectedMonthlyDay,
            decoration: const InputDecoration(
              labelText: 'Day of the month',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var day = 1; day <= 31; day++)
                DropdownMenuItem(value: day, child: Text('Day $day')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMonthlyDay = value;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTimeStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const Text(
          'When should it start?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose a time and starting date.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Time',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _QuickChoiceChip(
              label: 'Morning',
              detail: '8:00 AM',
              isSelected: _selectedTime.hour == 8 && _selectedTime.minute == 0,
              onTap: () {
                setState(() {
                  _selectedTime = const TimeOfDay(hour: 8, minute: 0);
                });
              },
            ),
            _QuickChoiceChip(
              label: 'Afternoon',
              detail: '2:00 PM',
              isSelected: _selectedTime.hour == 14 && _selectedTime.minute == 0,
              onTap: () {
                setState(() {
                  _selectedTime = const TimeOfDay(hour: 14, minute: 0);
                });
              },
            ),
            _QuickChoiceChip(
              label: 'Evening',
              detail: '8:00 PM',
              isSelected: _selectedTime.hour == 20 && _selectedTime.minute == 0,
              onTap: () {
                setState(() {
                  _selectedTime = const TimeOfDay(hour: 20, minute: 0);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _chooseCustomTime,
          icon: const Icon(Icons.schedule),
          label: Text('Custom time: ${_formatTime(_selectedTime)}'),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Start date',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DateChoiceTile(
          title: 'Today',
          subtitle: _formatDate(DateTime.now()),
          isSelected: _isSameDay(_selectedStartDate, DateTime.now()),
          onTap: () {
            setState(() {
              _selectedStartDate = DateTime.now();
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _DateChoiceTile(
          title: 'Tomorrow',
          subtitle: _formatDate(DateTime.now().add(const Duration(days: 1))),
          isSelected: _isSameDay(
            _selectedStartDate,
            DateTime.now().add(const Duration(days: 1)),
          ),
          onTap: () {
            setState(() {
              _selectedStartDate = DateTime.now().add(const Duration(days: 1));
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _chooseStartDate,
          icon: const Icon(Icons.calendar_month),
          label: Text('Choose date: ${_formatDate(_selectedStartDate)}'),
        ),
      ],
    );
  }

  Widget _buildCycleStep(BuildContext context) {
    return ListView(
      children: [
        ProtocolCycleEditor(
          useCycle: _useCycle,
          cycleStartDate: _cycleStartDate,
          onDurationController: _cycleOnDurationController,
          onUnit: _cycleOnUnit,
          offDurationController: _cycleOffDurationController,
          offUnit: _cycleOffUnit,
          repeatCycle: _repeatCycle,
          onUseCycleChanged: (value) {
            setState(() {
              _useCycle = value;

              if (value) {
                _cycleStartDate = _selectedStartDate;
              }
            });
          },
          onCycleStartDateChanged: (date) {
            setState(() {
              _cycleStartDate = date;
            });
          },
          onOnUnitChanged: (unit) {
            setState(() {
              _cycleOnUnit = unit;
            });
          },
          onOffUnitChanged: (unit) {
            setState(() {
              _cycleOffUnit = unit;
            });
          },
          onRepeatCycleChanged: (value) {
            setState(() {
              _repeatCycle = value;
            });
          },
          onValuesChanged: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Review protocol',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Confirm everything looks correct before saving.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewCard(
          title: _nameController.text.trim(),
          category: _categoryLabel(_selectedCategory!),
          rows: [
            _ReviewRowData(label: 'Dose', value: _formattedDose),
            _ReviewRowData(label: 'Schedule', value: _scheduleSummary()),
            _ReviewRowData(label: 'Time', value: _formatTime(_selectedTime)),
            _ReviewRowData(
              label: 'Starts',
              value: _formatDate(_selectedStartDate),
            ),
            _ReviewRowData(label: 'Cycle', value: _cycleReviewSummary()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Protocol color',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Used for Calendar and schedule markers. Colors may be reused.',
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
        const SizedBox(height: AppSpacing.md),
        Text(
          'You can pause or edit this protocol later from the Protocols tab.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _chooseCustomTime() async {
    final selected = await showIosTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = selected;
    });
  }

  Future<void> _chooseStartDate() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(today.year - 5, today.month, today.day),
      lastDate: DateTime(today.year + 10, today.month, today.day),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedStartDate = selected;
    });
  }

  Protocol _createProtocol() {
    return Protocol(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dose: _formattedDose,
      schedule: _createSchedule(),
      colorValue: _selectedColorValue,
      useCycle: _useCycle,
      cycleStartDate: _useCycle
          ? DateTime(
              _cycleStartDate.year,
              _cycleStartDate.month,
              _cycleStartDate.day,
            )
          : null,
      cycleOnDuration: _useCycle
          ? int.parse(_cycleOnDurationController.text.trim())
          : 1,
      cycleOnUnit: _cycleOnUnit,
      cycleOffDuration: _useCycle
          ? int.parse(_cycleOffDurationController.text.trim())
          : 0,
      cycleOffUnit: _cycleOffUnit,
      repeatCycle: _useCycle && _repeatCycle,
    );
  }

  ProtocolSchedule _createSchedule() {
    final commonArguments = (
      startDate: DateTime(
        _selectedStartDate.year,
        _selectedStartDate.month,
        _selectedStartDate.day,
      ),
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
    );

    switch (_selectedSchedule!) {
      case ScheduleOption.daily:
        return ProtocolSchedule.daily(
          startDate: commonArguments.startDate,
          hour: commonArguments.hour,
          minute: commonArguments.minute,
        );

      case ScheduleOption.weekly:
        return ProtocolSchedule.weekly(
          startDate: commonArguments.startDate,
          hour: commonArguments.hour,
          minute: commonArguments.minute,
          weekday: _selectedWeeklyDay!,
        );

      case ScheduleOption.everyXDays:
        return ProtocolSchedule.everyXDays(
          startDate: commonArguments.startDate,
          hour: commonArguments.hour,
          minute: commonArguments.minute,
          intervalDays: int.parse(_intervalDaysController.text.trim()),
        );

      case ScheduleOption.specificDays:
        return ProtocolSchedule.specificDays(
          startDate: commonArguments.startDate,
          hour: commonArguments.hour,
          minute: commonArguments.minute,
          weekdays: Set<int>.from(_selectedSpecificDays),
        );

      case ScheduleOption.monthly:
        return ProtocolSchedule.monthly(
          startDate: commonArguments.startDate,
          hour: commonArguments.hour,
          minute: commonArguments.minute,
          day: _selectedMonthlyDay!,
        );
    }
  }

  void _selectCategory(ProtocolCategory category) {
    setState(() {
      if (_selectedCategory != category) {
        _nameController.clear();
        _doseController.clear();
        _customUnitController.clear();
        _intervalDaysController.clear();

        _selectedPreset = null;
        _selectedUnit = null;
        _useCustomUnit = false;

        _selectedSchedule = null;
        _selectedWeeklyDay = null;
        _selectedMonthlyDay = null;
        _selectedSpecificDays.clear();
      }

      _selectedCategory = category;
    });
  }

  void _applyPresetUnit(String? unit) {
    if (unit == null || unit.trim().isEmpty) {
      return;
    }

    if (_commonUnits.contains(unit)) {
      _selectedUnit = unit;
      _useCustomUnit = false;
      _customUnitController.clear();
    } else {
      _selectedUnit = null;
      _useCustomUnit = true;
      _customUnitController.text = unit;
    }
  }

  void _selectSchedule(ScheduleOption option) {
    setState(() {
      _selectedSchedule = option;
    });
  }

  Widget _dayChip(String label, int weekday) {
    final isSelected = _selectedSpecificDays.contains(weekday);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedSpecificDays.add(weekday);
          } else {
            _selectedSpecificDays.remove(weekday);
          }
        });
      },
    );
  }

  List<DropdownMenuItem<int>> _weekdayItems() {
    return const [
      DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
      DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
      DropdownMenuItem(value: DateTime.wednesday, child: Text('Wednesday')),
      DropdownMenuItem(value: DateTime.thursday, child: Text('Thursday')),
      DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
      DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
      DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
    ];
  }

  String _searchHint(ProtocolCategory category) {
    switch (category) {
      case ProtocolCategory.peptide:
        return 'Search peptides';

      case ProtocolCategory.prescription:
        return 'Search medications';

      case ProtocolCategory.supplement:
        return 'Search supplements';

      case ProtocolCategory.vitamin:
        return 'Search vitamins';

      case ProtocolCategory.custom:
        return 'Enter a custom name';
    }
  }

  String _categoryLabel(ProtocolCategory category) {
    switch (category) {
      case ProtocolCategory.peptide:
        return 'Peptide';

      case ProtocolCategory.prescription:
        return 'Prescription';

      case ProtocolCategory.supplement:
        return 'Supplement';

      case ProtocolCategory.vitamin:
        return 'Vitamin';

      case ProtocolCategory.custom:
        return 'Custom';
    }
  }

  String _scheduleSummary() {
    switch (_selectedSchedule!) {
      case ScheduleOption.daily:
        return 'Daily';

      case ScheduleOption.weekly:
        return 'Weekly on '
            '${_weekdayName(_selectedWeeklyDay!)}';

      case ScheduleOption.everyXDays:
        return 'Every '
            '${_intervalDaysController.text.trim()} days';

      case ScheduleOption.specificDays:
        final days = _selectedSpecificDays.toList()..sort();

        return days.map(_shortWeekdayName).join(' • ');

      case ScheduleOption.monthly:
        return 'Monthly on day '
            '$_selectedMonthlyDay';
    }
  }

  String _cycleReviewSummary() {
    if (!_useCycle) {
      return 'Continuous';
    }

    final onDuration = _cycleOnDurationController.text.trim();
    final offDuration = _cycleOffDurationController.text.trim();

    if (!_repeatCycle) {
      return '$onDuration ${_unitLabel(_cycleOnUnit, onDuration)} on';
    }

    return '$onDuration ${_unitLabel(_cycleOnUnit, onDuration)} on • '
        '$offDuration ${_unitLabel(_cycleOffUnit, offDuration)} off • Repeats';
  }

  String _unitLabel(CycleUnit unit, String durationText) {
    final duration = int.tryParse(durationText);
    return duration == 1 ? unit.singularLabel : unit.label.toLowerCase();
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.10)
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppIcon.md,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final ProtocolPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  preset.name,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                preset.defaultUnit ?? '',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.check_circle,
                  size: AppIcon.sm,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChoiceChip extends StatelessWidget {
  const _QuickChoiceChip({
    required this.label,
    required this.detail,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(
            detail,
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChoiceTile extends StatelessWidget {
  const _DateChoiceTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.category,
    required this.rows,
  });

  final String title;
  final String category;
  final List<_ReviewRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    rows[index].label,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[index].value,
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (index < rows.length - 1) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _ReviewRowData {
  const _ReviewRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class _CustomNameMessage extends StatelessWidget {
  const _CustomNameMessage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          trimmedName.isEmpty
              ? 'No presets available.'
              : 'Use “$trimmedName” as a custom name.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
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

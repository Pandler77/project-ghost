import 'package:flutter/material.dart';

import '../models/cycle_unit.dart';
import '../models/injection_site.dart';
import '../models/protocol.dart';
import '../models/protocol_category.dart';
import '../models/protocol_preset.dart';
import '../models/protocol_schedule.dart';
import '../models/protocol_type.dart';
import '../models/rotation_mode.dart';
import '../services/protocol_preset_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_color_picker.dart';
import '../widgets/ios_time_picker.dart';
import '../widgets/protocol_editor/protocol_editor.dart';
import '../widgets/wizard_step_indicator.dart';
import 'calculator_hub_screen.dart';

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
  ProtocolType? _selectedProtocolType;

  String? _selectedUnit;
  bool _useCustomUnit = false;

  ScheduleOption? _selectedSchedule;
  int? _selectedWeeklyDay;
  int? _selectedMonthlyDay;

  final Set<int> _selectedSpecificDays = {};

  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  DateTime _selectedStartDate = DateTime.now();
  int _selectedColorValue = Protocol.defaultColorValue;

  bool _useCyclesSelected = false;
  bool _useRotationSelected = false;
  bool _useGhostSupplySelected = false;
  RotationMode _rotationMode = RotationMode.sequential;
  final Set<InjectionSite> _enabledInjectionSites = {};
  bool? _useCycle;
  DateTime _cycleStartDate = DateTime.now();
  CycleUnit _cycleOnUnit = CycleUnit.weeks;
  CycleUnit _cycleOffUnit = CycleUnit.weeks;
  bool _repeatCycle = true;

  bool? _reminderEnabled;
  int _reminderMinutesBefore = 0;
  bool? _missedDoseReminderEnabled;
  int _missedDoseReminderMinutesAfter = 60;

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
    final colors = Theme.of(context).colorScheme;

    final stepTitle = switch (_currentStep) {
      0 => 'Category',
      1 => 'Name',
      2 => 'Administration',
      3 => 'Dose',
      4 => 'Schedule',
      5 => 'Start',
      6 => 'Features',
      7 => 'Setup',
      8 => 'Reminders',
      9 => 'Review',
      _ => '',
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        title: const Text(
          'Add Protocol',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'STEP ${_currentStep + 1} OF 10',
                            style: TextStyle(
                              fontSize: AppTypography.micro,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: colors.primary,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Text(
                          stepTitle,
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    WizardStepIndicator(
                      currentStep: _currentStep,
                      totalSteps: 10,
                      label: '',
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: switch (_currentStep) {
                  0 => _buildCategoryStep(context),
                  1 => _buildNameStep(context),
                  2 => _buildAdministrationStep(context),
                  3 => _buildDoseStep(context),
                  4 => _buildScheduleStep(context),
                  5 => _buildTimeStep(context),
                  6 => _buildGhostFeaturesStep(context),
                  7 => _buildFeatureSetupStep(context),
                  8 => _buildReminderStep(context),
                  9 => _buildReviewStep(context),
                  _ => const SizedBox.shrink(),
                },
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
              child: FilledButton(
                onPressed: _canContinue() ? _handleContinue : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == 9
                          ? 'Save Protocol'
                          : _currentStep == 0
                          ? 'Continue'
                          : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    if (_currentStep < 9) ...[
                      const SizedBox(width: 7),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ] else ...[
                      const SizedBox(width: 7),
                      const Icon(Icons.check_rounded, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
    if (_currentStep < 9) {
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
        return _selectedProtocolType != null;

      case 3:
        final dose = double.tryParse(_doseController.text.trim());

        return dose != null && dose > 0 && _currentUnit.isNotEmpty;

      case 4:
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

      case 5:
        return true;

      case 6:
        return true;

      case 7:
        if (_useCyclesSelected) {
          final onDuration = int.tryParse(
            _cycleOnDurationController.text.trim(),
          );

          final offDuration = int.tryParse(
            _cycleOffDurationController.text.trim(),
          );

          final cycleIsValid =
              onDuration != null &&
              onDuration > 0 &&
              offDuration != null &&
              offDuration >= 0;

          if (!cycleIsValid) {
            return false;
          }
        }

        if (_useRotationSelected && _enabledInjectionSites.length < 2) {
          return false;
        }

        return true;

      case 8:
        if (_reminderEnabled == null) {
          return false;
        }

        if (_reminderEnabled == true) {
          return _missedDoseReminderEnabled != null;
        }

        return true;

      case 9:
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
          'What are you tracking?',
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
                title: 'Peptides & Research',
                subtitle:
                    'Peptides, research compounds, blends, and adjacent protocols',
                icon: Icons.science_outlined,
                isSelected: _selectedCategory == ProtocolCategory.peptide,
                onTap: () {
                  _selectCategory(ProtocolCategory.peptide);
                },
              ),
              _CategoryTile(
                title: 'Hormones & TRT',
                subtitle:
                    'Testosterone, growth hormone, fertility, and hormone protocols',
                icon: Icons.monitor_heart_outlined,
                isSelected:
                    _selectedCategory == ProtocolCategory.hormonesAndTrt,
                onTap: () {
                  _selectCategory(ProtocolCategory.hormonesAndTrt);
                },
              ),
              _CategoryTile(
                title: 'Medication',
                subtitle: 'Prescription and over-the-counter medications',
                icon: Icons.medication_outlined,
                isSelected: _selectedCategory == ProtocolCategory.medication,
                onTap: () {
                  _selectCategory(ProtocolCategory.medication);
                },
              ),
              _CategoryTile(
                title: 'Supplements & Vitamins',
                subtitle: 'Supplements, vitamins, minerals, and nutrition',
                icon: Icons.local_florist_outlined,
                isSelected:
                    _selectedCategory ==
                    ProtocolCategory.supplementsAndVitamins,
                onTap: () {
                  _selectCategory(ProtocolCategory.supplementsAndVitamins);
                },
              ),
              _CategoryTile(
                title: 'Other & Wellness',
                subtitle:
                    'Wellness products and protocols that do not fit elsewhere',
                icon: Icons.category_outlined,
                isSelected: _selectedCategory == ProtocolCategory.otherWellness,
                onTap: () {
                  _selectCategory(ProtocolCategory.otherWellness);
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
                _applyPresetDefaults(exactMatch);
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

                            _applyPresetDefaults(preset);
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

  Widget _buildAdministrationStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const Text(
          'How is it taken?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose the administration method. Ghost will only show features that apply.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _AdministrationTile(
          title: 'Injection',
          subtitle: 'Subcutaneous, intramuscular, or other injections',
          icon: Icons.vaccines_outlined,
          isSelected: _selectedProtocolType == ProtocolType.injection,
          onTap: () {
            setState(() {
              _selectedProtocolType = ProtocolType.injection;
            });
          },
        ),

        _AdministrationTile(
          title: 'Oral',
          subtitle: 'Tablets, capsules, liquids, and powders',
          icon: Icons.medication_outlined,
          isSelected: _selectedProtocolType == ProtocolType.oral,
          onTap: () {
            setState(() {
              _selectedProtocolType = ProtocolType.oral;
            });
          },
        ),

        _AdministrationTile(
          title: 'Topical',
          subtitle: 'Creams, gels, patches, and skin applications',
          icon: Icons.spa_outlined,
          isSelected: _selectedProtocolType == ProtocolType.topical,
          onTap: () {
            setState(() {
              _selectedProtocolType = ProtocolType.topical;
            });
          },
        ),

        _AdministrationTile(
          title: 'Nasal',
          subtitle: 'Nasal sprays and intranasal products',
          icon: Icons.air_outlined,
          isSelected: _selectedProtocolType == ProtocolType.nasal,
          onTap: () {
            setState(() {
              _selectedProtocolType = ProtocolType.nasal;
            });
          },
        ),

        _AdministrationTile(
          title: 'Sublingual',
          subtitle: 'Placed under the tongue',
          icon: Icons.water_drop_outlined,
          isSelected: _selectedProtocolType == ProtocolType.sublingual,
          onTap: () {
            setState(() {
              _selectedProtocolType = ProtocolType.sublingual;
            });
          },
        ),

        _AdministrationTile(
          title: 'Other',
          subtitle: 'Any method not listed above',
          icon: Icons.more_horiz,
          isSelected: _selectedProtocolType == ProtocolType.other,
          onTap: () {
            setState(() {
              _selectedProtocolType = ProtocolType.other;
            });
          },
        ),
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
            'Suggested unit based on ${_selectedPreset!.name}.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_selectedProtocolType == ProtocolType.injection) ...[
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openCalculator,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Ink(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Icon(
                        Icons.calculate_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need help calculating?',
                            style: TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Open Ghost Calculator',
                            style: TextStyle(fontSize: AppTypography.caption),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
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

  Widget _buildGhostFeaturesStep(BuildContext context) {
    final isInjection = _selectedProtocolType == ProtocolType.injection;

    return ListView(
      children: [
        const Text(
          'Ghost Features',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select the extra tools Ghost should use for this protocol.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isInjection)
          _FeatureSelectionTile(
            title: 'Use Cycles',
            subtitle: 'Run during planned on and off periods.',
            value: _useCyclesSelected,
            onChanged: (value) {
              setState(() {
                _useCyclesSelected = value;
                _useCycle = value;

                if (value) {
                  _cycleStartDate = _selectedStartDate;
                }
              });
            },
          ),
        if (isInjection)
          _FeatureSelectionTile(
            title: 'Injection Site Rotation',
            subtitle: 'Suggest sites and keep an injection history.',
            value: _useRotationSelected,
            onChanged: (value) {
              setState(() {
                _useRotationSelected = value;

                if (!value) {
                  _enabledInjectionSites.clear();
                  _rotationMode = RotationMode.sequential;
                }
              });
            },
          ),
        _FeatureSelectionTile(
          title: 'Ghost Supply',
          subtitle: 'Track inventory and receive reorder reminders.',
          value: _useGhostSupplySelected,
          onChanged: (value) {
            setState(() {
              _useGhostSupplySelected = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFeatureSetupStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelectedFeature =
        _useCyclesSelected || _useRotationSelected || _useGhostSupplySelected;

    if (!hasSelectedFeature) {
      return ListView(
        children: [
          const Text(
            'Feature Setup',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No additional setup is needed for the selected features.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Everything is ready. Continue to reminders.',
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      children: [
        const Text(
          'Feature Setup',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Configure the Ghost features selected for this protocol.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_useCyclesSelected) ...[
          ProtocolCycleEditor(
            showCycleChoice: false,
            useCycle: true,
            cycleStartDate: _cycleStartDate,
            onDurationController: _cycleOnDurationController,
            onUnit: _cycleOnUnit,
            offDurationController: _cycleOffDurationController,
            offUnit: _cycleOffUnit,
            repeatCycle: _repeatCycle,
            onUseCycleChanged: (_) {},
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
        if (_useGhostSupplySelected) ...[
          if (_useCyclesSelected || _useRotationSelected)
            const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.inventory_2_outlined, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Ghost Supply will be available for this protocol after it is saved. '
                    'You can configure container type, quantity, and alerts from Ghost Supply.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_useCyclesSelected && _useRotationSelected)
          const SizedBox(height: AppSpacing.lg),
        if (_useRotationSelected)
          InjectionRotationEditor(
            rotationMode: _rotationMode,
            enabledSites: _enabledInjectionSites,
            onRotationModeChanged: (mode) {
              setState(() {
                _rotationMode = mode;
              });
            },
            onSiteChanged: (site, enabled) {
              setState(() {
                if (enabled) {
                  _enabledInjectionSites.add(site);
                } else {
                  _enabledInjectionSites.remove(site);
                }
              });
            },
          ),
      ],
    );
  }

  Widget _buildReminderStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const Text(
          'Dose reminders',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Would you like to receive reminders for this protocol?',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Enable dose reminders?',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _BinaryChoiceTile(
                label: 'Yes',
                isSelected: _reminderEnabled == true,
                onTap: () {
                  setState(() {
                    _reminderEnabled = true;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BinaryChoiceTile(
                label: 'No',
                isSelected: _reminderEnabled == false,
                onTap: () {
                  setState(() {
                    _reminderEnabled = false;
                    _missedDoseReminderEnabled = null;
                  });
                },
              ),
            ),
          ],
        ),
        if (_reminderEnabled == true) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Notify me',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose when Ghost should notify you.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ReminderChoiceChip(
                label: 'At time',
                isSelected: _reminderMinutesBefore == 0,
                onTap: () {
                  setState(() {
                    _reminderMinutesBefore = 0;
                  });
                },
              ),
              _ReminderChoiceChip(
                label: '5m before',
                isSelected: _reminderMinutesBefore == 5,
                onTap: () {
                  setState(() {
                    _reminderMinutesBefore = 5;
                  });
                },
              ),
              _ReminderChoiceChip(
                label: '10m before',
                isSelected: _reminderMinutesBefore == 10,
                onTap: () {
                  setState(() {
                    _reminderMinutesBefore = 10;
                  });
                },
              ),
              _ReminderChoiceChip(
                label: '15m before',
                isSelected: _reminderMinutesBefore == 15,
                onTap: () {
                  setState(() {
                    _reminderMinutesBefore = 15;
                  });
                },
              ),
              _ReminderChoiceChip(
                label: '30m before',
                isSelected: _reminderMinutesBefore == 30,
                onTap: () {
                  setState(() {
                    _reminderMinutesBefore = 30;
                  });
                },
              ),
              _ReminderChoiceChip(
                label: '1h before',
                isSelected: _reminderMinutesBefore == 60,
                onTap: () {
                  setState(() {
                    _reminderMinutesBefore = 60;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Follow-up Reminder',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "If this dose isn't marked as taken, would you like another reminder?",
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _BinaryChoiceTile(
                  label: 'Yes',
                  isSelected: _missedDoseReminderEnabled == true,
                  onTap: () {
                    setState(() {
                      _missedDoseReminderEnabled = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _BinaryChoiceTile(
                  label: 'No',
                  isSelected: _missedDoseReminderEnabled == false,
                  onTap: () {
                    setState(() {
                      _missedDoseReminderEnabled = false;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_missedDoseReminderEnabled == true) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Follow-up timing',
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
                _ReminderChoiceChip(
                  label: '15m later',
                  isSelected: _missedDoseReminderMinutesAfter == 15,
                  onTap: () {
                    setState(() {
                      _missedDoseReminderMinutesAfter = 15;
                    });
                  },
                ),
                _ReminderChoiceChip(
                  label: '30m later',
                  isSelected: _missedDoseReminderMinutesAfter == 30,
                  onTap: () {
                    setState(() {
                      _missedDoseReminderMinutesAfter = 30;
                    });
                  },
                ),
                _ReminderChoiceChip(
                  label: '1h later',
                  isSelected: _missedDoseReminderMinutesAfter == 60,
                  onTap: () {
                    setState(() {
                      _missedDoseReminderMinutesAfter = 60;
                    });
                  },
                ),
                _ReminderChoiceChip(
                  label: '2h later',
                  isSelected: _missedDoseReminderMinutesAfter == 120,
                  onTap: () {
                    setState(() {
                      _missedDoseReminderMinutesAfter = 120;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
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
          subtitle:
              '${_categoryLabel(_selectedCategory!)} • ${_selectedProtocolType!.label}',
          colorValue: _selectedColorValue,
          rows: [
            _ReviewRowData(label: 'Dose', value: _formattedDose),
            _ReviewRowData(label: 'Schedule', value: _scheduleSummary()),
            _ReviewRowData(label: 'Time', value: _formatTime(_selectedTime)),
            _ReviewRowData(
              label: 'Starts',
              value: _formatDate(_selectedStartDate),
            ),
            if (_useCyclesSelected)
              _ReviewRowData(label: 'Cycle', value: _cycleReviewSummary()),
            if (_useRotationSelected)
              _ReviewRowData(
                label: 'Rotation',
                value: _rotationReviewSummary(),
              ),
            if (_useGhostSupplySelected)
              const _ReviewRowData(label: 'Ghost Supply', value: 'Enabled'),
            _ReviewRowData(label: 'Reminder', value: _reminderReviewSummary()),
            if (_reminderEnabled == true && _missedDoseReminderEnabled == true)
              _ReviewRowData(
                label: 'Follow-up',
                value: _missedReminderReviewSummary(),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Protocol color',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Use quick colors or choose a custom color for easy calendar recognition.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppColorPicker(
          selectedColorValue: _selectedColorValue,
          onColorChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedColorValue = value;
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'You can pause, edit, or recolor this protocol later from the Protocols tab.',
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

  Future<void> _openCalculator() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CalculatorHubScreen()),
    );
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
      category: _selectedCategory!,
      type: _selectedProtocolType!,
      dose: _formattedDose,
      schedule: _createSchedule(),
      colorValue: _selectedColorValue,
      useCycle: _useCyclesSelected && _useCycle == true,
      cycleStartDate: _useCyclesSelected && _useCycle == true
          ? DateTime(
              _cycleStartDate.year,
              _cycleStartDate.month,
              _cycleStartDate.day,
            )
          : null,
      cycleOnDuration: _useCyclesSelected && _useCycle == true
          ? int.parse(_cycleOnDurationController.text.trim())
          : 1,
      cycleOnUnit: _cycleOnUnit,
      cycleOffDuration: _useCyclesSelected && _useCycle == true
          ? int.parse(_cycleOffDurationController.text.trim())
          : 0,
      cycleOffUnit: _cycleOffUnit,
      repeatCycle: _useCyclesSelected && _useCycle == true && _repeatCycle,
      rotationEnabled: _useRotationSelected,
      rotationMode: _rotationMode,
      enabledInjectionSites: Set<InjectionSite>.from(_enabledInjectionSites),
      reminderEnabled: _reminderEnabled == true,
      reminderMinutesBefore: _reminderEnabled == true
          ? _reminderMinutesBefore
          : 0,
      missedDoseReminderEnabled:
          _reminderEnabled == true && _missedDoseReminderEnabled == true,
      missedDoseReminderMinutesAfter: _missedDoseReminderEnabled == true
          ? _missedDoseReminderMinutesAfter
          : 60,
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
        _selectedProtocolType = null;

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

  void _applyPresetDefaults(ProtocolPreset preset) {
    _applyPresetUnit(preset.defaultUnit);

    final protocolType = preset.defaultProtocolType;
    if (protocolType != null) {
      _selectedProtocolType = protocolType;
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
    return switch (category) {
      ProtocolCategory.peptide => 'Search peptides and research',
      ProtocolCategory.hormonesAndTrt => 'Search hormones and TRT',
      ProtocolCategory.medication => 'Search medications',
      ProtocolCategory.supplementsAndVitamins =>
        'Search supplements and vitamins',
      ProtocolCategory.otherWellness => 'Search wellness products',
      ProtocolCategory.researchCompound => 'Search research compounds',
      ProtocolCategory.custom => 'Enter a custom name',
    };
  }

  String _categoryLabel(ProtocolCategory category) {
    return category.label;
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
    if (_useCycle != true) {
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

  String _rotationReviewSummary() {
    final modeLabel = _rotationMode.label;
    final siteCount = _enabledInjectionSites.length;

    return '$modeLabel • $siteCount '
        '${siteCount == 1 ? 'site' : 'sites'}';
  }

  String _reminderReviewSummary() {
    if (_reminderEnabled != true) {
      return 'Disabled';
    }

    if (_reminderMinutesBefore == 0) {
      return 'Reminder enabled\nAt scheduled time';
    }

    if (_reminderMinutesBefore == 60) {
      return 'Reminder enabled\n1 hour before';
    }

    return 'Reminder enabled\n$_reminderMinutesBefore minutes before';
  }

  String _missedReminderReviewSummary() {
    if (_missedDoseReminderMinutesAfter == 60) {
      return '1 hour after if not taken';
    }

    if (_missedDoseReminderMinutesAfter == 120) {
      return '2 hours after if not taken';
    }

    return '$_missedDoseReminderMinutesAfter minutes after if not taken';
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

class _AdministrationTile extends StatelessWidget {
  const _AdministrationTile({
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
    final colors = Theme.of(context).colorScheme;

    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.10)
                  : baseColor,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.75)
                    : colors.outlineVariant.withValues(alpha: 0.60),
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.14)
                        : colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: AppIcon.md,
                    color: isSelected
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? colors.primary : colors.onSurface,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        subtitle,
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

                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: Colors.white,
                        )
                      : null,
                ),
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : Theme.of(context).cardTheme.color ?? colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
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

class _BinaryChoiceTile extends StatelessWidget {
  const _BinaryChoiceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
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
            vertical: 14,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.xs),
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

class _ReminderChoiceChip extends StatelessWidget {
  const _ReminderChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.subtitle,
    required this.colorValue,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final int colorValue;
  final List<_ReviewRowData> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color(colorValue),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
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
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 94,
                  child: Text(
                    rows[index].label,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rows[index].value,
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
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

class _FeatureSelectionTile extends StatelessWidget {
  const _FeatureSelectionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: value ? colorScheme.primary : colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: value,
                  onChanged: (newValue) {
                    onChanged(newValue ?? false);
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

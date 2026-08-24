import 'package:flutter/material.dart';

import '../models/cycle_unit.dart';
import '../models/dose_details.dart';
import '../models/dose_unit.dart';
import '../models/injection_site.dart';
import '../models/protocol.dart';
import '../models/protocol_category.dart';
import '../models/protocol_preset.dart';
import '../models/protocol_schedule.dart';
import '../models/protocol_type.dart';
import '../models/rotation_mode.dart';
import '../services/protocol_preset_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_color_picker.dart';
import '../widgets/ios_time_picker.dart';
import '../widgets/protocol_editor/protocol_editor.dart';
import '../widgets/wizard_step_indicator.dart';
import 'calculator_hub_screen.dart';
import 'advanced_dose_details_screen.dart';
import '../theme/arctic_icons.dart';

enum ScheduleOption { daily, weekly, everyXDays, specificDays, monthly }

class AddProtocolScreen extends StatefulWidget {
  const AddProtocolScreen({super.key});

  @override
  State<AddProtocolScreen> createState() => _AddProtocolScreenState();
}

class _AddProtocolScreenState extends State<AddProtocolScreen> {
  final ProtocolPresetService _presetService = ProtocolPresetService();
  final SettingsService _settingsService = SettingsService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _doseController = TextEditingController();

  final TextEditingController _customUnitController = TextEditingController();

  final TextEditingController _strengthController = TextEditingController();

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  DoseForm _physicalDoseForm = DoseForm.tablet;
  DoseUnit _physicalStrengthUnit = DoseUnit.mg;

  final TextEditingController _intervalDaysController = TextEditingController();

  final TextEditingController _customReminderBodyController =
      TextEditingController();

  final TextEditingController _customFollowUpBodyController =
      TextEditingController();

  final TextEditingController _cycleOnDurationController =
      TextEditingController(text: '12');

  final TextEditingController _cycleOffDurationController =
      TextEditingController(text: '4');

  static const List<String> _injectionUnits = [
    'mg',
    'mcg',
    'g',
    'IU',
    'mL',
    'units',
  ];

  static const List<String> _oralUnits = [
    'tablet',
    'capsule',
    'pill',
    'mg',
    'mcg',
    'g',
    'mL',
    'serving',
  ];

  static const List<String> _topicalUnits = ['mg', 'g', 'mL', 'patch'];

  static const List<String> _nasalUnits = ['spray', 'drop', 'mg', 'mcg'];

  static const List<String> _sublingualUnits = ['drop', 'mg', 'mcg', 'mL'];

  static const List<String> _otherUnits = [
    'mg',
    'mcg',
    'g',
    'IU',
    'mL',
    'units',
    'tablet',
    'capsule',
    'pill',
    'spray',
    'drop',
    'patch',
    'serving',
  ];

  List<String> get _availableUnits {
    return switch (_selectedProtocolType) {
      ProtocolType.injection => _injectionUnits,
      ProtocolType.oral => _oralUnits,
      ProtocolType.topical => _topicalUnits,
      ProtocolType.nasal => _nasalUnits,
      ProtocolType.sublingual => _sublingualUnits,
      ProtocolType.other => _otherUnits,
      null => _otherUnits,
    };
  }

  int _currentStep = 0;

  ProtocolCategory? _selectedCategory;
  ProtocolPreset? _selectedPreset;
  ProtocolType? _selectedProtocolType;

  String? _selectedUnit;
  bool _useCustomUnit = false;
  DoseDetails? _advancedDoseDetails;

  ScheduleOption? _selectedSchedule;
  int? _selectedWeeklyDay;
  int? _selectedMonthlyDay;

  final Set<int> _selectedSpecificDays = {};

  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  DateTime _selectedStartDate = DateTime.now();
  DateTime _displayedStartMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  int _selectedColorValue = Protocol.defaultColorValue;

  bool _useCyclesSelected = false;
  bool _useRotationSelected = false;
  bool _useGhostSupplySelected = false;
  bool _cycleSetupExpanded = true;
  bool _rotationSetupExpanded = false;
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
  bool _customNotificationTextEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final preferences = await _settingsService.getNotificationPreferences();

    if (!mounted) {
      return;
    }

    setState(() {
      _customNotificationTextEnabled =
          preferences.customNotificationTextEnabled;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _customUnitController.dispose();
    _strengthController.dispose();
    _quantityController.dispose();
    _intervalDaysController.dispose();
    _customReminderBodyController.dispose();
    _customFollowUpBodyController.dispose();
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
    FocusManager.instance.primaryFocus?.unfocus();

    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _handleContinue() {
    FocusManager.instance.primaryFocus?.unfocus();

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
        if (_usesPhysicalDoseEditor) {
          final strength = double.tryParse(_strengthController.text.trim());
          final quantity = double.tryParse(_quantityController.text.trim());

          return strength != null &&
              strength > 0 &&
              quantity != null &&
              quantity > 0;
        }

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

  bool get _usesPhysicalDoseEditor {
    return switch (_selectedProtocolType) {
      ProtocolType.oral ||
      ProtocolType.topical ||
      ProtocolType.nasal ||
      ProtocolType.sublingual => true,
      _ => false,
    };
  }

  List<DoseForm> get _availablePhysicalForms {
    return switch (_selectedProtocolType) {
      ProtocolType.oral => const [
        DoseForm.tablet,
        DoseForm.capsule,
        DoseForm.pill,
        DoseForm.liquid,
        DoseForm.powder,
        DoseForm.scoop,
        DoseForm.serving,
      ],
      ProtocolType.topical => const [
        DoseForm.cream,
        DoseForm.gel,
        DoseForm.liquid,
        DoseForm.patch,
        DoseForm.pump,
      ],
      ProtocolType.nasal => const [DoseForm.spray, DoseForm.drop],
      ProtocolType.sublingual => const [
        DoseForm.drop,
        DoseForm.liquid,
        DoseForm.spray,
      ],
      _ => const [DoseForm.other],
    };
  }

  static const List<DoseUnit> _physicalStrengthUnits = [
    DoseUnit.mcg,
    DoseUnit.mg,
    DoseUnit.g,
    DoseUnit.iu,
    DoseUnit.units,
    DoseUnit.mL,
  ];

  double? get _physicalTotalDose {
    final strength = double.tryParse(_strengthController.text.trim());
    final quantity = double.tryParse(_quantityController.text.trim());

    if (strength == null ||
        strength <= 0 ||
        quantity == null ||
        quantity <= 0) {
      return null;
    }

    return strength * quantity;
  }

  DoseDetails? get _physicalDoseDetails {
    if (!_usesPhysicalDoseEditor) {
      return _advancedDoseDetails;
    }

    final strength = double.tryParse(_strengthController.text.trim());
    final quantity = double.tryParse(_quantityController.text.trim());

    if (strength == null ||
        strength <= 0 ||
        quantity == null ||
        quantity <= 0) {
      return null;
    }

    return DoseDetails(
      form: _physicalDoseForm,
      strengthAmount: strength,
      strengthUnit: _physicalStrengthUnit,
      scheduledQuantity: quantity,
      blendComponents: _advancedDoseDetails?.blendComponents ?? const [],
    );
  }

  String get _formattedDose {
    if (_usesPhysicalDoseEditor) {
      final total = _physicalTotalDose;

      if (total == null) {
        return '';
      }

      return '${_formatAdvancedNumber(total)} ${_physicalStrengthUnit.label}';
    }

    return '${_doseController.text.trim()} $_currentUnit';
  }

  String get _physicalDoseInstruction {
    final details = _physicalDoseDetails;

    if (details == null) {
      return '';
    }

    final quantity = _formatAdvancedNumber(details.scheduledQuantity!);
    final strength = _formatAdvancedNumber(details.strengthAmount!);
    final unitLabel = details.quantityUnitLabel;
    final plural =
        details.scheduledQuantity == 1 || unitLabel == 'mL' || unitLabel == 'g'
        ? unitLabel
        : '${unitLabel}s';

    return '$quantity $plural × $strength ${details.strengthUnit!.label} '
        '= ${_formatAdvancedNumber(details.totalActiveDose!)} '
        '${details.strengthUnit!.label}';
  }

  String get _strengthFieldLabel {
    return switch (_physicalDoseForm) {
      DoseForm.liquid => 'Strength per mL',
      DoseForm.powder => 'Strength per g',
      DoseForm.cream => 'Strength per mL',
      DoseForm.gel => 'Strength per mL',
      _ => 'Strength per ${_physicalDoseForm.label.toLowerCase()}',
    };
  }

  String get _quantityFieldLabel {
    return switch (_physicalDoseForm) {
      DoseForm.liquid => 'mL per dose',
      DoseForm.powder => 'Grams per dose',
      DoseForm.cream => 'mL per application',
      DoseForm.gel => 'mL per application',
      _ => '${_physicalDoseForm.label}s per dose',
    };
  }

  void _ensurePhysicalFormIsValid() {
    final forms = _availablePhysicalForms;

    if (!forms.contains(_physicalDoseForm)) {
      _physicalDoseForm = forms.first;
    }
  }

  Widget _buildCategoryStep(BuildContext context) {
    final categories = [
      (
        ProtocolCategory.peptide,
        'Peptides & Hormones',
        'Peptides, research compounds, blends, TRT, hormones, and injectables.',
        ArcticIcons.science_outlined,
      ),
      (
        ProtocolCategory.medication,
        'Medication',
        'Prescription and over-the-counter medications, including tablets, capsules, liquids, and other forms.',
        ArcticIcons.medication_outlined,
      ),
      (
        ProtocolCategory.supplementsAndVitamins,
        'Supplements & Vitamins',
        'Vitamins, minerals, powders, capsules, nutrition, and daily supplements.',
        ArcticIcons.local_florist_outlined,
      ),
      (
        ProtocolCategory.custom,
        'Custom',
        'Create a fully custom protocol when your item does not fit one of the categories above.',
        ArcticIcons.tune_outlined,
      ),
    ];

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
          child: Column(
            children: [
              for (var index = 0; index < categories.length; index++) ...[
                Expanded(
                  child: _CategoryFeatureCard(
                    title: categories[index].$2,
                    description: categories[index].$3,
                    icon: categories[index].$4,
                    isSelected: _selectedCategory == categories[index].$1,
                    onTap: () => _selectCategory(categories[index].$1),
                  ),
                ),
                if (index < categories.length - 1) const SizedBox(height: 10),
              ],
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

    final query = _nameController.text.trim();

    final presets = category == ProtocolCategory.custom
        ? <ProtocolPreset>[]
        : _presetService.search(category: category, query: query);

    final exactMatch = query.isEmpty
        ? null
        : _presetService.findByName(category: category, name: query);

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
              ? 'Enter any name for the protocol you want to track.'
              : 'Search our suggestions or enter any name to create your own protocol.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _nameController,
          autofocus: false,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            setState(() {
              final match = _presetService.findByName(
                category: category,
                name: value,
              );

              _selectedPreset = match;

              if (match != null) {
                _applyPresetDefaults(match);
              }
            });
          },
          decoration: InputDecoration(
            labelText: category == ProtocolCategory.custom
                ? 'Protocol name'
                : 'Search or enter a name',
            hintText: category == ProtocolCategory.custom
                ? 'Example: Morning Medication'
                : _searchHint(category),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _nameController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
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

        if (category == ProtocolCategory.custom) ...[
          if (query.isNotEmpty)
            _CustomProtocolCard(name: query, isSelected: true, onTap: () {})
          else
            _NameHelperCard(
              title: 'Create anything',
              description:
                  'Type the name above. You will choose how it is taken and how much on the next screens.',
            ),
          const Spacer(),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  query.isEmpty ? 'Suggested protocols' : 'Results',
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (query.isEmpty)
                Text(
                  'Tap one or type your own',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (query.isNotEmpty && exactMatch == null) ...[
                  _CustomProtocolCard(
                    name: query,
                    isSelected: _selectedPreset == null,
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        _selectedPreset = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (presets.isEmpty && query.isEmpty)
                  const _NameHelperCard(
                    title: 'No suggestions available',
                    description:
                        'Enter any name above to create a custom protocol.',
                  )
                else if (presets.isEmpty)
                  _NameHelperCard(
                    title: 'No preset match',
                    description:
                        'You can still continue with “$query” as a custom protocol.',
                  )
                else
                  for (var index = 0; index < presets.length; index++) ...[
                    _PresetTile(
                      preset: presets[index],
                      isSelected: _selectedPreset?.name == presets[index].name,
                      onTap: () {
                        final preset = presets[index];

                        FocusManager.instance.primaryFocus?.unfocus();

                        setState(() {
                          _selectedPreset = preset;
                          _nameController.text = preset.name;
                          _nameController.selection = TextSelection.collapsed(
                            offset: preset.name.length,
                          );
                          _applyPresetDefaults(preset);
                        });
                      },
                    ),
                    if (index < presets.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          ),
        ],
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
          'Choose the administration method. MODOSE will only show features that apply.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _AdministrationTile(
          title: 'Injection',
          subtitle: 'Subcutaneous, intramuscular, or other injections',
          icon: ArcticIcons.vaccines_outlined,
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
          icon: ArcticIcons.medication_outlined,
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
          icon: ArcticIcons.spa_outlined,
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
          icon: ArcticIcons.air_outlined,
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
          icon: ArcticIcons.water_drop_outlined,
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

    if (_usesPhysicalDoseEditor) {
      _ensurePhysicalFormIsValid();

      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const Text(
            'How is each dose taken?',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter the form, strength, and amount you actually take each time.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          DropdownButtonFormField<DoseForm>(
            initialValue: _physicalDoseForm,
            decoration: const InputDecoration(
              labelText: 'Dose form',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final form in _availablePhysicalForms)
                DropdownMenuItem<DoseForm>(
                  value: form,
                  child: Text(form.label),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _physicalDoseForm = value;
              });
            },
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _strengthController,
                  autofocus: false,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _strengthFieldLabel,
                    hintText: '500',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<DoseUnit>(
                  initialValue: _physicalStrengthUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final unit in _physicalStrengthUnits)
                      DropdownMenuItem<DoseUnit>(
                        value: unit,
                        child: Text(unit.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _physicalStrengthUnit = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _quantityController,
            autofocus: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _quantityFieldLabel,
              suffixText:
                  _physicalDoseForm == DoseForm.liquid ||
                      _physicalDoseForm == DoseForm.cream ||
                      _physicalDoseForm == DoseForm.gel
                  ? 'mL'
                  : _physicalDoseForm == DoseForm.powder
                  ? 'g'
                  : _physicalDoseForm.label.toLowerCase(),
              border: const OutlineInputBorder(),
            ),
          ),

          if (_physicalTotalDose != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled dose',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _physicalDoseInstruction,
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final dropdownValue =
        _selectedUnit != null && _availableUnits.contains(_selectedUnit)
        ? _selectedUnit
        : null;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          autofocus: false,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
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
            for (final unit in _availableUnits)
              DropdownMenuItem(value: unit, child: Text(unit)),
          ],
          onChanged: (value) {
            setState(() {
              _selectedUnit = value;
              _useCustomUnit = false;
              _customUnitController.clear();
            });
          },
        ),

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
          _AdvancedDoseTile(
            hasDetails: _advancedDoseDetails != null,
            summary: _advancedDoseSummary,
            onTap: _openAdvancedDoseDetails,
            onClear: _advancedDoseDetails == null
                ? null
                : () {
                    setState(() {
                      _advancedDoseDetails = null;
                    });
                  },
          ),
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
                        ArcticIcons.calculate_outlined,
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
                            'Open Calculator',
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
          icon: ArcticIcons.today_outlined,
          isSelected: _selectedSchedule == ScheduleOption.daily,
          onTap: () {
            _selectSchedule(ScheduleOption.daily);
          },
        ),
        _ScheduleTile(
          title: 'Weekly',
          subtitle: 'Once each week',
          icon: ArcticIcons.date_range_outlined,
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
          icon: ArcticIcons.calendar_view_week_outlined,
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
          icon: ArcticIcons.calendar_month_outlined,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          'Choose the start date, then set the dose time.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: _CompactCalendar(
              displayedMonth: _displayedStartMonth,
              selectedDate: _selectedStartDate,
              onPreviousMonth: () {
                setState(() {
                  _displayedStartMonth = DateTime(
                    _displayedStartMonth.year,
                    _displayedStartMonth.month - 1,
                  );
                });
              },
              onNextMonth: () {
                setState(() {
                  _displayedStartMonth = DateTime(
                    _displayedStartMonth.year,
                    _displayedStartMonth.month + 1,
                  );
                });
              },
              onDateSelected: (date) {
                setState(() {
                  _selectedStartDate = date;
                  _displayedStartMonth = DateTime(date.year, date.month);
                  _cycleStartDate = date;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        const Text(
          'What time?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose a quick time or select an exact time.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _TimePresetCard(
                label: 'Morning',
                detail: '8:00 AM',
                isSelected:
                    _selectedTime.hour == 8 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 8, minute: 0);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TimePresetCard(
                label: 'Afternoon',
                detail: '2:00 PM',
                isSelected:
                    _selectedTime.hour == 14 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 14, minute: 0);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TimePresetCard(
                label: 'Evening',
                detail: '8:00 PM',
                isSelected:
                    _selectedTime.hour == 20 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 20, minute: 0);
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _chooseCustomTime,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              'Choose exact time • ${_formatTime(_selectedTime)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            'Starts ${_formatDate(_selectedStartDate)} at ${_formatTime(_selectedTime)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostFeaturesStep(BuildContext context) {
    final isInjection = _selectedProtocolType == ProtocolType.injection;

    return ListView(
      children: [
        const Text(
          'MODOSE Features',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select the extra tools MODOSE should use for this protocol.',
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
                  _cycleSetupExpanded = true;
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

                if (value) {
                  if (!_useCyclesSelected) {
                    _rotationSetupExpanded = true;
                  }
                } else {
                  _enabledInjectionSites.clear();
                  _rotationMode = RotationMode.sequential;
                  _rotationSetupExpanded = false;
                }
              });
            },
          ),
        _FeatureSelectionTile(
          title: 'MODOSE Supply',
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

    final cycleValid = !_useCyclesSelected || _cycleSetupIsValid;
    final rotationValid =
        !_useRotationSelected || _enabledInjectionSites.length >= 2;

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
          'Set up each feature separately. Tap a section to open or close it.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_useCyclesSelected) ...[
          _FeatureSetupCard(
            title: 'Cycle Setup',
            subtitle: cycleValid
                ? _cycleSetupSummary()
                : 'Enter valid on and off durations.',
            icon: ArcticIcons.event_repeat_outlined,
            isExpanded: _cycleSetupExpanded,
            isComplete: cycleValid,
            onTap: () {
              setState(() {
                _cycleSetupExpanded = !_cycleSetupExpanded;
              });
            },
            child: ProtocolCycleEditor(
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
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (_useRotationSelected) ...[
          _FeatureSetupCard(
            title: 'Injection Site Rotation',
            subtitle: rotationValid
                ? '${_rotationMode.label} • ${_enabledInjectionSites.length} sites'
                : 'Select at least two injection sites.',
            icon: ArcticIcons.location_on_outlined,
            isExpanded: _rotationSetupExpanded,
            isComplete: rotationValid,
            onTap: () {
              setState(() {
                _rotationSetupExpanded = !_rotationSetupExpanded;
              });
            },
            child: InjectionRotationEditor(
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
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (_useGhostSupplySelected)
          _FeatureSetupCard(
            title: 'MODOSE Supply',
            subtitle: 'Inventory tracking enabled',
            icon: ArcticIcons.inventory_2_outlined,
            isExpanded: false,
            isComplete: true,
            canExpand: false,
            onTap: () {},
            footer: Text(
              'Configure container type, quantity, and alerts from MODOSE Supply after this protocol is saved.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }

  bool get _cycleSetupIsValid {
    final onDuration = int.tryParse(_cycleOnDurationController.text.trim());
    final offDuration = int.tryParse(_cycleOffDurationController.text.trim());

    return onDuration != null &&
        onDuration > 0 &&
        offDuration != null &&
        offDuration >= 0;
  }

  String _cycleSetupSummary() {
    final onDuration = _cycleOnDurationController.text.trim();
    final offDuration = _cycleOffDurationController.text.trim();

    final onLabel = _unitLabel(_cycleOnUnit, onDuration);
    final offLabel = _unitLabel(_cycleOffUnit, offDuration);

    if (!_repeatCycle) {
      return '$onDuration $onLabel on • Does not repeat';
    }

    return '$onDuration $onLabel on • $offDuration $offLabel off';
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
            'Choose when MODOSE should notify you.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReminderTimingDropdown(
            value: _reminderMinutesBefore,
            values: const [0, 5, 10, 15, 30, 60],
            label: 'Reminder timing',
            labelBuilder: _beforeLabel,
            onChanged: (value) {
              setState(() {
                _reminderMinutesBefore = value;
              });
            },
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
            _ReminderTimingDropdown(
              value: _missedDoseReminderMinutesAfter,
              values: _followUpTimingValues,
              label: 'Follow-up timing',
              labelBuilder: _afterLabel,
              onChanged: (value) {
                setState(() {
                  _missedDoseReminderMinutesAfter = value;
                });
              },
            ),
          ],
          if (_customNotificationTextEnabled) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Main reminder message',
              style: TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Applies only to the main reminder. Leave blank to use “It\'s time for your protocol”.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _customReminderBodyController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 140,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Custom main reminder',
                hintText: "It's time for your protocol",
                border: OutlineInputBorder(),
              ),
            ),
            if (_missedDoseReminderEnabled == true) ...[
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Follow-up reminder message',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Applies only to the follow-up. Leave blank to use the MODOSE default.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _customFollowUpBodyController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 140,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Custom follow-up reminder',
                  hintText: "You haven't logged your protocol today.",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
            if (_usesPhysicalDoseEditor)
              _ReviewRowData(
                label: 'How taken',
                value: _physicalDoseInstruction,
              ),
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
              const _ReviewRowData(label: 'MODOSE Supply', value: 'Enabled'),
            _ReviewRowData(label: 'Reminder', value: _reminderReviewSummary()),
            if (_reminderEnabled == true && _missedDoseReminderEnabled == true)
              _ReviewRowData(
                label: 'Follow-up',
                value: _missedReminderReviewSummary(),
              ),
            if (_reminderEnabled == true &&
                _customNotificationTextEnabled &&
                _customReminderBodyController.text.trim().isNotEmpty)
              _ReviewRowData(
                label: 'Main text',
                value: _customReminderBodyController.text.trim(),
              ),
            if (_reminderEnabled == true &&
                _missedDoseReminderEnabled == true &&
                _customNotificationTextEnabled &&
                _customFollowUpBodyController.text.trim().isNotEmpty)
              _ReviewRowData(
                label: 'Follow-up text',
                value: _customFollowUpBodyController.text.trim(),
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

  Future<void> _openAdvancedDoseDetails() async {
    final doseAmount = double.tryParse(_doseController.text.trim());

    if (_selectedProtocolType == null ||
        doseAmount == null ||
        doseAmount <= 0 ||
        _currentUnit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the scheduled dose and unit first.'),
        ),
      );
      return;
    }

    final doseUnit = DoseUnitDetails.fromStorageValue(_currentUnit);

    final details = await Navigator.push<DoseDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => AdvancedDoseDetailsScreen(
          protocolType: _selectedProtocolType!,
          scheduledDoseAmount: doseAmount,
          scheduledDoseUnit: doseUnit,
          initialDetails: _advancedDoseDetails,
          presetName: _selectedPreset?.name,
        ),
      ),
    );

    if (details == null || !mounted) {
      return;
    }

    setState(() {
      _advancedDoseDetails = details;
    });
  }

  String get _advancedDoseSummary {
    final details = _advancedDoseDetails;

    if (details == null) {
      return 'Optional: reconstitution, syringe units, strength, or blend composition.';
    }

    final parts = <String>[];

    if (details.form != null && details.form != DoseForm.injection) {
      parts.add(details.form!.label);
    }

    if (details.hasReconstitution) {
      parts.add(
        '${_formatAdvancedNumber(details.vialAmount!)} '
        '${details.vialUnit!.label} vial + '
        '${_formatAdvancedNumber(details.reconstitutionVolumeMl!)} mL',
      );
    }

    final draw = details.drawUnits(
      scheduledDoseAmount: double.tryParse(_doseController.text.trim()) ?? 0,
      scheduledDoseUnit: DoseUnitDetails.fromStorageValue(_currentUnit),
    );

    if (draw != null) {
      parts.add('Draw ${_formatAdvancedNumber(draw)} units');
    }

    if (details.hasOralStrength) {
      parts.add(
        '${_formatAdvancedNumber(details.scheduledQuantity!)} × '
        '${_formatAdvancedNumber(details.strengthAmount!)} '
        '${details.strengthUnit!.label}',
      );
    }

    if (details.blendComponents.isNotEmpty) {
      parts.add('${details.blendComponents.length} blend components');
    }

    return parts.isEmpty ? 'Advanced details added' : parts.join(' • ');
  }

  String _formatAdvancedNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> _openCalculator() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CalculatorHubScreen()),
    );
  }

  Protocol _createProtocol() {
    return Protocol(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      type: _selectedProtocolType!,
      dose: _formattedDose,
      doseDetails: _usesPhysicalDoseEditor
          ? _physicalDoseDetails
          : _advancedDoseDetails,
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
      customReminderTitle: null,
      customReminderBody: _optionalNotificationText(
        _customReminderBodyController.text,
      ),
      customFollowUpTitle: null,
      customFollowUpBody: _optionalNotificationText(
        _customFollowUpBodyController.text,
      ),
    );
  }

  String? _optionalNotificationText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
        _advancedDoseDetails = null;
        _selectedProtocolType = null;
        _strengthController.clear();
        _quantityController.text = '1';
        _physicalDoseForm = DoseForm.tablet;
        _physicalStrengthUnit = DoseUnit.mg;

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

    final normalized = switch (unit.trim().toLowerCase()) {
      'tablets' => 'tablet',
      'capsules' => 'capsule',
      'pills' => 'pill',
      'sprays' => 'spray',
      'drops' => 'drop',
      'patches' => 'patch',
      'servings' => 'serving',
      'iu' => 'IU',
      'ml' => 'mL',
      _ => unit.trim(),
    };

    if (_availableUnits.contains(normalized)) {
      _selectedUnit = normalized;
      _useCustomUnit = false;
      _customUnitController.clear();
    }
  }

  void _applyPresetDefaults(ProtocolPreset preset) {
    final protocolType = preset.defaultProtocolType;

    if (protocolType != null) {
      _selectedProtocolType = protocolType;
    }

    _applyPresetUnit(preset.defaultUnit);

    if (_usesPhysicalDoseEditor) {
      final inventoryUnit =
          preset.defaultInventoryUnit?.trim().toLowerCase() ?? '';

      _physicalDoseForm = switch (inventoryUnit) {
        'tablet' || 'tablets' => DoseForm.tablet,
        'capsule' || 'capsules' => DoseForm.capsule,
        'pill' || 'pills' => DoseForm.pill,
        'spray' || 'sprays' => DoseForm.spray,
        'drop' || 'drops' => DoseForm.drop,
        'patch' || 'patches' => DoseForm.patch,
        'serving' || 'servings' => DoseForm.serving,
        _ => _availablePhysicalForms.first,
      };

      final presetUnit = preset.defaultUnit;

      if (presetUnit != null) {
        final parsed = DoseUnitDetails.fromStorageValue(presetUnit);

        if (_physicalStrengthUnits.contains(parsed)) {
          _physicalStrengthUnit = parsed;
        }
      }
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
}

class _FeatureSetupCard extends StatelessWidget {
  const _FeatureSetupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isExpanded,
    required this.isComplete,
    required this.onTap,
    required this.child,
    this.footer,
    this.canExpand = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isExpanded;
  final bool isComplete;
  final VoidCallback onTap;
  final Widget child;
  final Widget? footer;
  final bool canExpand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).cardTheme.color ?? colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isExpanded
                ? colors.primary.withValues(alpha: 0.55)
                : colors.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: canExpand ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(icon, color: colors.primary),
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
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      isComplete
                          ? Icons.check_circle
                          : ArcticIcons.error_outline_rounded,
                      color: isComplete ? colors.primary : colors.error,
                    ),
                    if (canExpand) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (footer != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Align(alignment: Alignment.centerLeft, child: footer!),
              ),
            ],
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  Divider(
                    height: 1,
                    color: colors.outlineVariant.withValues(alpha: 0.65),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: child,
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

class _CategoryFeatureCard extends StatelessWidget {
  const _CategoryFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.11)
                : baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card + 2),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.85),
              width: isSelected ? 2.2 : 1.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colors.primary
                        : colors.outline.withValues(alpha: 0.55),
                    width: 1.3,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
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

class _AdvancedDoseTile extends StatelessWidget {
  const _AdvancedDoseTile({
    required this.hasDetails,
    required this.summary,
    required this.onTap,
    required this.onClear,
  });

  final bool hasDetails;
  final String summary;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hasDetails
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: hasDetails
                  ? colors.primary.withValues(alpha: 0.55)
                  : colors.outlineVariant,
              width: hasDetails ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(value: hasDetails, onChanged: (_) => onTap()),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Advanced dose details',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Remove advanced details',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
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
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.10)
                : baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.55),
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  preset.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.primary : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  preset.defaultProtocolType?.label ?? 'Custom',
                  style: TextStyle(
                    fontSize: AppTypography.micro,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactCalendar extends StatelessWidget {
  const _CompactCalendar({
    required this.displayedMonth,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;
    final leadingEmpty = firstDay.weekday % 7;
    final cellCount = leadingEmpty + daysInMonth;
    final rowCount = (cellCount / 7).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_months[displayedMonth.month - 1]} ${displayedMonth.year}',
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          const Row(
            children: [
              _CalendarWeekday('S'),
              _CalendarWeekday('M'),
              _CalendarWeekday('T'),
              _CalendarWeekday('W'),
              _CalendarWeekday('T'),
              _CalendarWeekday('F'),
              _CalendarWeekday('S'),
            ],
          ),
          const SizedBox(height: 2),
          for (var row = 0; row < rowCount; row++)
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  for (var column = 0; column < 7; column++)
                    Expanded(
                      child: _buildDayCell(
                        context,
                        row * 7 + column,
                        leadingEmpty,
                        daysInMonth,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    int index,
    int leadingEmpty,
    int daysInMonth,
  ) {
    final day = index - leadingEmpty + 1;

    if (day < 1 || day > daysInMonth) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final date = DateTime(displayedMonth.year, displayedMonth.month, day);
    final today = DateTime.now();

    final isSelected =
        selectedDate.year == date.year &&
        selectedDate.month == date.month &&
        selectedDate.day == date.day;

    final isToday =
        today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;

    return Center(
      child: InkWell(
        onTap: () => onDateSelected(date),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: !isSelected && isToday
                ? Border.all(color: colors.primary, width: 1.2)
                : null,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: isSelected || isToday
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: isSelected
                  ? colors.onPrimary
                  : isToday
                  ? colors.primary
                  : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarWeekday extends StatelessWidget {
  const _CalendarWeekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.micro,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TimePresetCard extends StatelessWidget {
  const _TimePresetCard({
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
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.11)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.40),
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.micro,
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

const List<int> _followUpTimingValues = [
  5,
  10,
  15,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
  60,
  120,
  180,
  240,
  300,
  360,
  420,
  480,
  540,
  600,
];

String _beforeLabel(int value) {
  if (value == 0) return 'At scheduled time';
  if (value == 60) return '1 hour before';
  return '$value minutes before';
}

String _afterLabel(int value) {
  if (value == 60) return '1 hour later';
  if (value > 60 && value % 60 == 0) {
    final hours = value ~/ 60;
    return '$hours hours later';
  }
  return '$value minutes later';
}

class _ReminderTimingDropdown extends StatelessWidget {
  const _ReminderTimingDropdown({
    required this.value,
    required this.values,
    required this.label,
    required this.labelBuilder,
    required this.onChanged,
  });

  final int value;
  final List<int> values;
  final String label;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = values.contains(value) ? value : values.first;

    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem<int>(value: item, child: Text(labelBuilder(item))),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
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
                  ArcticIcons.palette_outlined,
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

class _CustomProtocolCard extends StatelessWidget {
  const _CustomProtocolCard({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.09)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.55),
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create custom protocol',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Continue with this name and choose the details yourself.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
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

class _NameHelperCard extends StatelessWidget {
  const _NameHelperCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outline.withValues(alpha: 0.40)),
      ),
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
            description,
            style: TextStyle(
              fontSize: AppTypography.caption,
              height: 1.35,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
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

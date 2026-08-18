import 'package:flutter/material.dart';

import '../models/measurement_system.dart';
import '../models/profile.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/weight_display.dart';
import '../theme/arctic_icons.dart';

enum CalorieSex {
  male('Male'),
  female('Female');

  const CalorieSex(this.label);

  final String label;
}

enum ActivityLevel {
  sedentary('Sedentary', 'Little structured exercise', 1.20),
  lightlyActive('Lightly active', 'Light exercise 1–3 days/week', 1.375),
  moderatelyActive(
    'Moderately active',
    'Moderate exercise 3–5 days/week',
    1.55,
  ),
  veryActive('Very active', 'Hard exercise 6–7 days/week', 1.725),
  extraActive(
    'Extra active',
    'Very hard training or highly active work',
    1.90,
  );

  const ActivityLevel(this.label, this.description, this.multiplier);

  final String label;
  final String description;
  final double multiplier;
}

enum NutritionGoal {
  maintain('Maintain', 'Stay near estimated maintenance', 0),
  mildLoss('Mild loss', 'About 10% below estimated maintenance', -0.10),
  moderateLoss('Moderate loss', 'About 20% below estimated maintenance', -0.20),
  gain('Gain', 'About 10% above estimated maintenance', 0.10);

  const NutritionGoal(this.label, this.description, this.adjustment);

  final String label;
  final String description;
  final double adjustment;
}

class CalorieProteinCalculatorScreen extends StatefulWidget {
  const CalorieProteinCalculatorScreen({
    required this.dataService,
    required this.measurementSystem,
    super.key,
  });

  final AppDataService dataService;
  final MeasurementSystem measurementSystem;

  @override
  State<CalorieProteinCalculatorScreen> createState() =>
      _CalorieProteinCalculatorScreenState();
}

class _CalorieProteinCalculatorScreenState
    extends State<CalorieProteinCalculatorScreen> {
  final ProfileService _profileService = ProfileService();

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  CalorieSex _sex = CalorieSex.male;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  NutritionGoal _goal = NutritionGoal.maintain;

  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    try {
      final results = await Future.wait<Object>([
        _profileService.getActiveProfile(),
        widget.dataService.getWeightRecords(),
      ]);

      final profile = results[0] as Profile;
      final weightRecords = results[1] as List<WeightRecord>;

      weightRecords.sort(
        (first, second) => second.recordedAt.compareTo(first.recordedAt),
      );

      final latestWeight = weightRecords.isEmpty
          ? profile.startingWeight
          : weightRecords.first.weight;

      if (latestWeight != null && latestWeight > 0) {
        final displayedWeight = WeightDisplay.displayValue(
          latestWeight,
          widget.measurementSystem,
        );

        _weightController.text = displayedWeight.toStringAsFixed(1);
      }

      final heightCm = profile.heightCm;

      if (heightCm != null && heightCm > 0) {
        _heightController.text = widget.measurementSystem ==
                MeasurementSystem.metric
            ? heightCm.toStringAsFixed(1)
            : (heightCm / 2.54).toStringAsFixed(1);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double? get _weightKg {
    final value = double.tryParse(_weightController.text.trim());

    if (value == null || value <= 0) {
      return null;
    }

    if (widget.measurementSystem == MeasurementSystem.metric) {
      return value;
    }

    return value * 0.45359237;
  }

  double? get _heightCm {
    final value = double.tryParse(_heightController.text.trim());

    if (value == null || value <= 0) {
      return null;
    }

    if (widget.measurementSystem == MeasurementSystem.metric) {
      return value;
    }

    return value * 2.54;
  }

  int? get _age {
    final value = int.tryParse(_ageController.text.trim());

    if (value == null || value < 18 || value > 120) {
      return null;
    }

    return value;
  }

  double? get _restingCalories {
    final weightKg = _weightKg;
    final heightCm = _heightCm;
    final age = _age;

    if (weightKg == null || heightCm == null || age == null) {
      return null;
    }

    final sexAdjustment = _sex == CalorieSex.male ? 5.0 : -161.0;

    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + sexAdjustment;
  }

  double? get _maintenanceCalories {
    final resting = _restingCalories;

    if (resting == null) {
      return null;
    }

    return resting * _activityLevel.multiplier;
  }

  double? get _targetCalories {
    final maintenance = _maintenanceCalories;

    if (maintenance == null) {
      return null;
    }

    return maintenance * (1 + _goal.adjustment);
  }

  double? get _proteinLow {
    final weightKg = _weightKg;

    if (weightKg == null) {
      return null;
    }

    return weightKg * 1.4;
  }

  double? get _proteinHigh {
    final weightKg = _weightKg;

    if (weightKg == null) {
      return null;
    }

    return weightKg * 2.0;
  }

  bool get _hasResult {
    return _restingCalories != null &&
        _maintenanceCalories != null &&
        _targetCalories != null &&
        _proteinLow != null &&
        _proteinHigh != null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calories & Protein',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  80,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          ArcticIcons.restaurant_menu_outlined,
                          color: colors.primary,
                          size: 30,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Daily Target Estimator',
                          style: TextStyle(
                            fontSize: AppTypography.pageTitle,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _profile == null
                              ? 'Enter your information to estimate daily targets.'
                              : 'Profile height and latest weight are filled in when available. You can override them here without changing your profile.',
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            height: 1.4,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const _SectionTitle(title: 'Your information'),
                  const SizedBox(height: AppSpacing.sm),

                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      hintText: '30',
                      suffixText: 'years',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  DropdownButtonFormField<CalorieSex>(
                    initialValue: _sex,
                    decoration: const InputDecoration(
                      labelText: 'Sex used by calorie equation',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final option in CalorieSex.values)
                        DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _sex = value;
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: WeightDisplay.unit(widget.measurementSystem),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Height',
                      suffixText: widget.measurementSystem ==
                              MeasurementSystem.metric
                          ? 'cm'
                          : 'in',
                      helperText: widget.measurementSystem ==
                              MeasurementSystem.imperial
                          ? 'Enter total inches. Example: 79 for 6 ft 7 in.'
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const _SectionTitle(title: 'Activity'),
                  const SizedBox(height: AppSpacing.sm),

                  for (final level in ActivityLevel.values) ...[
                    _SelectionCard(
                      title: level.label,
                      subtitle: level.description,
                      selected: _activityLevel == level,
                      onTap: () {
                        setState(() {
                          _activityLevel = level;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  const _SectionTitle(title: 'Goal'),
                  const SizedBox(height: AppSpacing.sm),

                  for (final goal in NutritionGoal.values) ...[
                    _SelectionCard(
                      title: goal.label,
                      subtitle: goal.description,
                      selected: _goal == goal,
                      onTap: () {
                        setState(() {
                          _goal = goal;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  if (_hasResult)
                    _ResultsCard(
                      restingCalories: _restingCalories!,
                      maintenanceCalories: _maintenanceCalories!,
                      targetCalories: _targetCalories!,
                      proteinLow: _proteinLow!,
                      proteinHigh: _proteinHigh!,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Text(
                        'Enter a valid age from 18–120, weight, and height to calculate targets.',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Estimates use the Mifflin–St Jeor resting-energy equation '
                    'with an activity multiplier. Protein is shown as a broad '
                    '1.4–2.0 g/kg/day planning range. Actual energy and protein '
                    'needs can differ based on body composition, medical '
                    'conditions, training, medications, and other factors.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      height: 1.45,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppTypography.title,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.restingCalories,
    required this.maintenanceCalories,
    required this.targetCalories,
    required this.proteinLow,
    required this.proteinHigh,
  });

  final double restingCalories;
  final double maintenanceCalories;
  final double targetCalories;
  final double proteinLow;
  final double proteinHigh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Daily Targets',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  label: 'RESTING',
                  value: '${restingCalories.round()}',
                  unit: 'kcal/day',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ResultMetric(
                  label: 'MAINTENANCE',
                  value: '${maintenanceCalories.round()}',
                  unit: 'kcal/day',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ResultMetric(
            label: 'CALORIE TARGET',
            value: '${targetCalories.round()}',
            unit: 'kcal/day',
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ResultMetric(
            label: 'PROTEIN RANGE',
            value: '${proteinLow.round()}–${proteinHigh.round()}',
            unit: 'g/day',
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
    required this.unit,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: emphasized ? 0.70 : 0.46),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: colors.primary.withValues(alpha: emphasized ? 0.18 : 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 27 : 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

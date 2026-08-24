import 'package:flutter/material.dart';

import '../models/measurement_system.dart';
import '../services/app_data_service.dart';
import '../services/settings_service.dart';
import '../services/usage_analytics_service.dart';
import '../theme/app_theme.dart';
import 'bac_water_calculator_screen.dart';
import 'calorie_protein_calculator_screen.dart';
import 'dose_from_units_calculator_screen.dart';
import 'premium_screen.dart';
import 'reconstitution_calculator_screen.dart';
import '../theme/arctic_icons.dart';

class CalculatorHubScreen extends StatefulWidget {
  const CalculatorHubScreen({
    this.dataService,
    this.measurementSystem,
    super.key,
  });

  final AppDataService? dataService;
  final MeasurementSystem? measurementSystem;

  @override
  State<CalculatorHubScreen> createState() => _CalculatorHubScreenState();
}

class _CalculatorHubScreenState extends State<CalculatorHubScreen> {
  final SettingsService _settingsService = SettingsService();

  late final AppDataService _dataService;
  MeasurementSystem _measurementSystem = MeasurementSystem.imperial;
  bool _isLoadingMeasurementSystem = true;

  @override
  void initState() {
    super.initState();

    _dataService = widget.dataService ?? AppDataService();

    final suppliedMeasurementSystem = widget.measurementSystem;

    if (suppliedMeasurementSystem != null) {
      _measurementSystem = suppliedMeasurementSystem;
      _isLoadingMeasurementSystem = false;
    } else {
      _loadMeasurementSystem();
    }
  }

  Future<void> _loadMeasurementSystem() async {
    final measurementSystem = await _settingsService.getMeasurementSystem();

    if (!mounted) {
      return;
    }

    setState(() {
      _measurementSystem = measurementSystem;
      _isLoadingMeasurementSystem = false;
    });
  }

  Future<void> _openCalorieProteinCalculator() async {
    if (_isLoadingMeasurementSystem) {
      return;
    }

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.calculatorOpened,
      properties: {
        'calculator_type': 'calories_protein',
      },
    );

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CalorieProteinCalculatorScreen(
          dataService: _dataService,
          measurementSystem: _measurementSystem,
        ),
      ),
    );
  }

  Future<void> _openPremium() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumScreen(dataService: _dataService),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openDoseFromUnitsCalculator() async {
    if (!_dataService.hasPremium) {
      await _openPremium();
      return;
    }

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.calculatorOpened,
      properties: {
        'calculator_type': 'dose_from_units',
      },
    );

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const DoseFromUnitsCalculatorScreen(),
      ),
    );
  }

  Future<void> _openBacWaterCalculator() async {
    if (!_dataService.hasPremium) {
      await _openPremium();
      return;
    }

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.calculatorOpened,
      properties: {
        'calculator_type': 'bac_water',
      },
    );

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const BacWaterCalculatorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            colors.primary.withValues(alpha: 0.28),
            colors.primaryContainer.withValues(alpha: 0.12),
          ]
        : [
            colors.primary.withValues(alpha: 0.15),
            colors.primaryContainer.withValues(alpha: 0.50),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calculator',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            80,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.44),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      ArcticIcons.calculate_outlined,
                      color: colors.primary,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Calculator',
                    style: TextStyle(
                      fontSize: AppTypography.pageTitle,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose the calculation you need.',
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SectionLabel(
              title: 'EVERYDAY CALCULATORS',
              subtitle: 'Core tools available to everyone.',
            ),

            const SizedBox(height: AppSpacing.sm),

            _CalculatorTile(
              icon: ArcticIcons.science_outlined,
              title: 'Reconstitution',
              subtitle: 'Calculate how many syringe units to draw.',
              onTap: () {
                UsageAnalyticsService.instance.track(
                  UsageAnalyticsEvent.calculatorOpened,
                  properties: {
                    'calculator_type': 'reconstitution',
                  },
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReconstitutionCalculatorScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            _CalculatorTile(
              icon: ArcticIcons.restaurant_menu_outlined,
              title: 'Calories & Protein',
              subtitle: 'Estimate maintenance calories and daily targets.',
              onTap: _openCalorieProteinCalculator,
            ),

            const SizedBox(height: AppSpacing.lg),

            _SectionLabel(
              title: 'ADVANCED CALCULATORS',
              subtitle: _dataService.hasPremium
                  ? 'Premium tools unlocked.'
                  : 'Specialized dosing tools included with MODOSE Premium.',
            ),

            const SizedBox(height: AppSpacing.sm),

            _CalculatorTile(
              icon: ArcticIcons.vaccines_outlined,
              title: 'Dose from Units',
              subtitle: 'Calculate the dose contained in syringe units.',
              premium: true,
              premiumActive: _dataService.hasPremium,
              onTap: _openDoseFromUnitsCalculator,
            ),

            const SizedBox(height: AppSpacing.sm),

            _CalculatorTile(
              icon: ArcticIcons.water_drop_outlined,
              title: 'BAC Water',
              subtitle: 'Calculate how much BAC water to add.',
              premium: true,
              premiumActive: _dataService.hasPremium,
              onTap: _openBacWaterCalculator,
            ),

            const SizedBox(height: AppSpacing.lg),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.60),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      ArcticIcons.info_outline,
                      size: AppIcon.sm,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Calculator results are estimates. Verify inputs and use '
                      'results as planning guidance rather than medical advice.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.4,
                        color: colors.onSurfaceVariant,
                      ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypography.caption,
            height: 1.3,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CalculatorTile extends StatelessWidget {
  const _CalculatorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.premium = false,
    this.premiumActive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool premium;
  final bool premiumActive;

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
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: colors.primary, size: AppIcon.md),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (premium)
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                premiumActive
                                    ? const Color(0xFFE3AA22)
                                    : colors.primary,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/branding/modose_premium_mark.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                      ],
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

              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
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


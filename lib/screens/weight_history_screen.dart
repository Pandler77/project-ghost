import 'dart:io';

import 'package:flutter/material.dart';

import '../models/measurement_system.dart';
import '../models/profile.dart';
import '../models/progress_photo.dart';
import '../models/progress_photo_session.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/profile_service.dart';
import '../services/progress_photo_service.dart';
import '../services/usage_analytics_service.dart';
import '../theme/app_theme.dart';
import '../utils/weight_display.dart';
import 'premium_screen.dart';
import 'progress_photo_screen.dart';
import '../theme/arctic_icons.dart';

enum WeightChartRange {
  oneWeek('1W'),
  oneMonth('1M'),
  threeMonths('3M'),
  sixMonths('6M'),
  oneYear('1Y'),
  all('All');

  const WeightChartRange(this.label);

  final String label;
}

class WeightHistoryScreen extends StatefulWidget {
  const WeightHistoryScreen({
    required this.dataService,
    required this.measurementSystem,
    super.key,
  });

  final AppDataService dataService;
  final MeasurementSystem measurementSystem;

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  final ProfileService _profileService = ProfileService();
  final ProgressPhotoService _progressPhotoService = ProgressPhotoService();

  List<WeightRecord> _records = [];
  Profile? _profile;
  ProgressPhotoSession? _latestPhotoSession;
  List<ProgressPhoto> _latestSessionPhotos = [];

  WeightChartRange _selectedRange = WeightChartRange.oneMonth;

  bool _isLoading = true;
  bool _didChangeData = false;

  bool get _hasPremium => widget.dataService.hasPremium;

  @override
  void initState() {
    super.initState();

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.weightHistoryOpened,
    );

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<Object>([
        widget.dataService.getWeightRecords(),
        _profileService.getActiveProfile(),
        _progressPhotoService.getAllSessions(),
      ]);

      final records = results[0] as List<WeightRecord>;
      final profile = results[1] as Profile;
      final sessions = results[2] as List<ProgressPhotoSession>;

      records.sort(
        (first, second) => second.recordedAt.compareTo(first.recordedAt),
      );

      sessions.sort(
        (first, second) => second.recordedAt.compareTo(first.recordedAt),
      );

      final latestSession = sessions.isEmpty ? null : sessions.first;

      final latestPhotos = latestSession == null
          ? <ProgressPhoto>[]
          : await _progressPhotoService.getPhotosForSession(latestSession.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
        _profile = profile;
        _latestPhotoSession = latestSession;
        _latestSessionPhotos = latestPhotos;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load weight data: $error')),
      );
    }
  }

  Future<void> _loadRecords() async {
    final records = await widget.dataService.getWeightRecords();

    records.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _openProgressPhotos() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressPhotosScreen(
          dataService: widget.dataService,
          measurementSystem: widget.measurementSystem,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadData();
  }

  Future<void> _openPremium() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumScreen(dataService: widget.dataService),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _logWeight() async {
    final currentStoredWeight = _records.isEmpty ? null : _records.first.weight;

    final initialDisplayWeight = currentStoredWeight == null
        ? null
        : WeightDisplay.displayValue(
            currentStoredWeight,
            widget.measurementSystem,
          );

    final enteredWeight = await showDialog<double>(
      context: context,
      builder: (_) => _WeightEntryDialog(
        initialWeight: initialDisplayWeight,
        isFirstEntry: _records.isEmpty,
        measurementSystem: widget.measurementSystem,
      ),
    );

    if (enteredWeight == null || !mounted) {
      return;
    }

    final storedWeight = WeightDisplay.storageValue(
      enteredWeight,
      widget.measurementSystem,
    );

    final now = DateTime.now();

    final existingRecord = await widget.dataService.getWeightRecordForDate(now);

    final record = WeightRecord(
      id: existingRecord?.id ?? now.microsecondsSinceEpoch.toString(),
      weight: storedWeight,
      recordedAt: now,
    );

    await widget.dataService.saveWeightRecord(record);

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.weightLogged,
    );

    final profile = _profile;

    if (profile != null && profile.startingWeight == null) {
      final updatedProfile = profile.copyWith(
        startingWeight: storedWeight,
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(updatedProfile);
      _profile = updatedProfile;
    }

    if (!mounted) {
      return;
    }

    _didChangeData = true;

    await _loadRecords();
  }

  Future<void> _editRecord(WeightRecord record) async {
    final updatedRecord = await showDialog<WeightRecord>(
      context: context,
      builder: (_) => _EditWeightEntryDialog(
        record: record,
        measurementSystem: widget.measurementSystem,
      ),
    );

    if (updatedRecord == null || !mounted) {
      return;
    }

    try {
      await widget.dataService.saveWeightRecord(updatedRecord);

      if (!mounted) {
        return;
      }

      _didChangeData = true;

      await _loadRecords();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update weight entry: $error')),
      );
    }
  }

  Future<void> _deleteRecord(WeightRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete weight entry?'),
          content: Text(
            'Delete ${WeightDisplay.format(record.weight, widget.measurementSystem)} from ${_formatFullDate(record.recordedAt)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.dataService.deleteWeightRecord(record.id);

    if (!mounted) {
      return;
    }

    _didChangeData = true;

    await _loadRecords();
  }

  double? get _goalWeight => _profile?.goalWeight;

  double? get _startingWeightLossPercent {
    final starting = _startingWeight;
    final current = _currentWeight;

    if (starting == null || current == null || starting <= 0) {
      return null;
    }

    return ((starting - current) / starting) * 100;
  }

  double? get _goalProgress {
    final starting = _startingWeight;
    final current = _currentWeight;
    final goal = _goalWeight;

    if (starting == null ||
        current == null ||
        goal == null ||
        starting == goal) {
      return null;
    }

    final progress = (starting - current) / (starting - goal);

    return progress.clamp(0.0, 1.0);
  }

  double? get _weightRemaining {
    final current = _currentWeight;
    final goal = _goalWeight;

    if (current == null || goal == null) {
      return null;
    }

    return (current - goal).abs();
  }

  Future<void> _setStartingWeight() async {
    final profile = _profile;

    if (profile == null) {
      return;
    }

    final storedInitialWeight = profile.startingWeight ?? _startingWeight;

    final displayInitialWeight = storedInitialWeight == null
        ? null
        : WeightDisplay.displayValue(
            storedInitialWeight,
            widget.measurementSystem,
          );

    final enteredWeight = await showDialog<double>(
      context: context,
      builder: (_) => _StartingWeightDialog(
        initialWeight: displayInitialWeight,
        measurementSystem: widget.measurementSystem,
      ),
    );

    if (enteredWeight == null || !mounted) {
      return;
    }

    final startingWeight = WeightDisplay.storageValue(
      enteredWeight,
      widget.measurementSystem,
    );

    final updatedProfile = profile.copyWith(
      startingWeight: startingWeight,
      updatedAt: DateTime.now(),
    );

    try {
      await _profileService.updateProfile(updatedProfile);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updatedProfile;
        _didChangeData = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save starting weight: $error')),
      );
    }
  }

  Future<void> _setGoalWeight() async {
    final profile = _profile;

    if (profile == null) {
      return;
    }

    final displayInitialWeight = profile.goalWeight == null
        ? null
        : WeightDisplay.displayValue(
            profile.goalWeight!,
            widget.measurementSystem,
          );

    final enteredWeight = await showDialog<double>(
      context: context,
      builder: (_) => _GoalWeightDialog(
        initialWeight: displayInitialWeight,
        measurementSystem: widget.measurementSystem,
      ),
    );

    if (enteredWeight == null || !mounted) {
      return;
    }

    final goalWeight = WeightDisplay.storageValue(
      enteredWeight,
      widget.measurementSystem,
    );

    final updatedProfile = profile.copyWith(
      goalWeight: goalWeight,
      updatedAt: DateTime.now(),
    );

    try {
      await _profileService.updateProfile(updatedProfile);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updatedProfile;
        _didChangeData = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save goal weight: $error')),
      );
    }
  }

  List<WeightRecord> get _chronologicalRecords {
    final records = List<WeightRecord>.from(_records);

    records.sort(
      (first, second) => first.recordedAt.compareTo(second.recordedAt),
    );

    return records;
  }

  List<WeightRecord> get _filteredRecords {
    final records = _chronologicalRecords;

    if (_selectedRange == WeightChartRange.all || records.isEmpty) {
      return records;
    }

    final now = DateTime.now();

    final startDate = switch (_selectedRange) {
      WeightChartRange.oneWeek => now.subtract(const Duration(days: 7)),
      WeightChartRange.oneMonth => DateTime(now.year, now.month - 1, now.day),
      WeightChartRange.threeMonths => DateTime(
        now.year,
        now.month - 3,
        now.day,
      ),
      WeightChartRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
      WeightChartRange.oneYear => DateTime(now.year - 1, now.month, now.day),
      WeightChartRange.all => DateTime(1900),
    };

    return records
        .where((record) => !record.recordedAt.isBefore(startDate))
        .toList();
  }

  double? get _currentWeight {
    if (_records.isEmpty) {
      return null;
    }

    return _records.first.weight;
  }

  double? get _startingWeight {
    final savedStartingWeight = _profile?.startingWeight;

    if (savedStartingWeight != null && savedStartingWeight > 0) {
      return savedStartingWeight;
    }

    if (_records.isEmpty) {
      return null;
    }

    return _records.last.weight;
  }

  double? get _currentBmi {
    final heightCm = _profile?.heightCm;
    final currentWeightLb = _currentWeight;

    if (heightCm == null ||
        heightCm <= 0 ||
        currentWeightLb == null ||
        currentWeightLb <= 0) {
      return null;
    }

    final heightMeters = heightCm / 100;
    final weightKg = currentWeightLb * 0.45359237;

    return weightKg / (heightMeters * heightMeters);
  }

  String get _currentBmiCategory {
    final bmi = _currentBmi;

    if (bmi == null) {
      return 'Unavailable';
    }

    if (bmi < 18.5) {
      return 'Underweight';
    }

    if (bmi < 25) {
      return 'Healthy range';
    }

    if (bmi < 30) {
      return 'Overweight';
    }

    if (bmi < 35) {
      return 'Obesity class I';
    }

    if (bmi < 40) {
      return 'Obesity class II';
    }

    return 'Obesity class III';
  }

  double? get _totalChange {
    final current = _currentWeight;
    final starting = _startingWeight;

    if (current == null || starting == null) {
      return null;
    }

    return current - starting;
  }

  double? get _lowestWeight {
    if (_records.isEmpty) {
      return null;
    }

    return _records
        .map((record) => record.weight)
        .reduce((first, second) => first < second ? first : second);
  }

  double? get _highestWeight {
    if (_records.isEmpty) {
      return null;
    }

    return _records
        .map((record) => record.weight)
        .reduce((first, second) => first > second ? first : second);
  }

  double? _changeSinceDays(int days) {
    if (_records.length < 2) {
      return null;
    }

    final current = _records.first;

    final targetDate = DateTime.now().subtract(Duration(days: days));

    WeightRecord? comparison;

    for (final record in _records) {
      if (!record.recordedAt.isAfter(targetDate)) {
        comparison = record;
        break;
      }
    }

    comparison ??= _records.last;

    if (comparison.id == current.id) {
      return null;
    }

    return current.weight - comparison.weight;
  }

  String _formatChange(double? value) {
    if (value == null) {
      return '—';
    }

    final displayedValue = WeightDisplay.displayValue(
      value.abs(),
      widget.measurementSystem,
    );

    final unit = WeightDisplay.unit(widget.measurementSystem);

    if (value == 0) {
      return '0.0 $unit';
    }

    final prefix = value > 0 ? '+' : '-';

    return '$prefix${displayedValue.toStringAsFixed(1)} $unit';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final recordDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(recordDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    return _formatFullDate(date);
  }

  static String _formatFullDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        Navigator.pop(context, _didChangeData);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Weight')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _logWeight,
          icon: const Icon(Icons.add),
          label: const Text('Log Weight'),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
              ? _EmptyWeightHistory(onLogWeight: _logWeight)
              : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final currentWeight = _currentWeight!;
    final startingWeight = _startingWeight!;
    final totalChange = _totalChange ?? 0;

    final hasLostWeight = totalChange < 0;

    final displayedCurrentWeight = WeightDisplay.displayValue(
      currentWeight,
      widget.measurementSystem,
    );

    final displayedStartingWeight = WeightDisplay.displayValue(
      startingWeight,
      widget.measurementSystem,
    );

    final displayedTotalChange = WeightDisplay.displayValue(
      totalChange.abs(),
      widget.measurementSystem,
    );

    final unit = WeightDisplay.unit(widget.measurementSystem);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        110,
      ),
      children: [
        _WeightHeroCard(
          currentWeight: '${displayedCurrentWeight.toStringAsFixed(1)} $unit',
          startingWeight: '${displayedStartingWeight.toStringAsFixed(1)} $unit',
          totalChange: totalChange == 0
              ? 'No change'
              : '${displayedTotalChange.toStringAsFixed(1)} $unit '
                    '${hasLostWeight ? 'lost' : 'gained'}',
          percentChange: _startingWeightLossPercent,
          goalWeight: _goalWeight == null
              ? null
              : WeightDisplay.format(_goalWeight!, widget.measurementSystem),
          goalProgress: _goalProgress,
          remainingText: _weightRemaining == null
              ? null
              : '${WeightDisplay.displayValue(_weightRemaining!, widget.measurementSystem).toStringAsFixed(1)} $unit remaining',
          onEditStartingWeight: _setStartingWeight,
          onEditGoalWeight: _setGoalWeight,
          onSetGoalWeight: _setGoalWeight,
        ),

        const SizedBox(height: AppSpacing.lg),

        _EstimatedBmiCard(
          bmi: _currentBmi,
          category: _currentBmiCategory,
          hasHeight: (_profile?.heightCm ?? 0) > 0,
        ),

        const SizedBox(height: AppSpacing.lg),

        if (_hasPremium)
          _buildAnalytics(context)
        else
          _PremiumAnalyticsCard(onTap: _openPremium),

        const SizedBox(height: AppSpacing.lg),

        _buildChart(context),

        const SizedBox(height: AppSpacing.lg),

        _ProgressPhotosCard(
          session: _latestPhotoSession,
          photos: _latestSessionPhotos,
          measurementSystem: widget.measurementSystem,
          onTap: _openProgressPhotos,
        ),

        const SizedBox(height: AppSpacing.lg),

        Row(
          children: [
            const Expanded(
              child: Text(
                'History',
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${_records.length} entries',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        ..._records.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _WeightHistoryTile(
              record: record,
              dateLabel: _formatRelativeDate(record.recordedAt),
              measurementSystem: widget.measurementSystem,
              onEdit: () => _editRecord(record),
              onDelete: () => _deleteRecord(record),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalytics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weight Analytics',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '7-DAY',
                value: _formatChange(_changeSinceDays(7)),
                icon: ArcticIcons.calendar_view_week_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: '30-DAY',
                value: _formatChange(_changeSinceDays(30)),
                icon: ArcticIcons.calendar_month_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'LOWEST',
                value: WeightDisplay.format(
                  _lowestWeight!,
                  widget.measurementSystem,
                ),
                icon: Icons.south_east_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'HIGHEST',
                value: WeightDisplay.format(
                  _highestWeight!,
                  widget.measurementSystem,
                ),
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final visibleRecords = _hasPremium
        ? _filteredRecords
        : _chronologicalRecords.takeLast(10).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Trend',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track how your weight changes over time.',
                      style: TextStyle(fontSize: AppTypography.caption),
                    ),
                  ],
                ),
              ),
              if (!_hasPremium)
                InkWell(
                  onTap: _openPremium,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: const _PremiumBadge(),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (_hasPremium)
            _WeightRangeSelector(
              selectedRange: _selectedRange,
              onSelected: (range) {
                setState(() {
                  _selectedRange = range;
                });
              },
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openPremium,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Ink(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Upgrade to unlock date ranges and detailed weight analytics.',
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightChartPainter(
                  records: visibleRecords,
                  lineColor: colors.primary,
                  fillColor: colors.primary.withValues(alpha: 0.12),
                  guideColor: colors.outlineVariant,
                  labelColor: colors.onSurfaceVariant,
                  measurementSystem: widget.measurementSystem,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimatedBmiCard extends StatelessWidget {
  const _EstimatedBmiCard({
    required this.bmi,
    required this.category,
    required this.hasHeight,
  });

  final double? bmi;
  final String category;
  final bool hasHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              ArcticIcons.monitor_heart_outlined,
              color: colors.primary,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Estimated BMI',
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Estimated',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (bmi != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bmi!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Based on your current weight and saved profile height.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ] else
                  Text(
                    hasHeight
                        ? 'Log a current weight to estimate BMI.'
                        : 'Add height to your profile to estimate BMI.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightHeroCard extends StatelessWidget {
  const _WeightHeroCard({
    required this.currentWeight,
    required this.startingWeight,
    required this.totalChange,
    required this.percentChange,
    required this.goalWeight,
    required this.goalProgress,
    required this.remainingText,
    required this.onEditStartingWeight,
    required this.onEditGoalWeight,
    required this.onSetGoalWeight,
  });

  final String currentWeight;
  final String startingWeight;
  final String totalChange;
  final double? percentChange;
  final String? goalWeight;
  final double? goalProgress;
  final String? remainingText;
  final VoidCallback onEditStartingWeight;
  final VoidCallback onEditGoalWeight;
  final VoidCallback onSetGoalWeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            colors.primary.withValues(alpha: 0.30),
            colors.primaryContainer.withValues(alpha: 0.14),
          ]
        : [
            colors.primary.withValues(alpha: 0.16),
            colors.primaryContainer.withValues(alpha: 0.56),
          ];

    return Container(
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
          color: colors.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Weight',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            currentWeight,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _WeightHeroMetric(
                  label: 'STARTING',
                  value: startingWeight,
                  onTap: onEditStartingWeight,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _WeightHeroMetric(label: 'CHANGE', value: totalChange),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _WeightHeroMetric(
                  label: 'GOAL',
                  value: goalWeight ?? 'Set goal',
                  onTap: goalWeight == null
                      ? onSetGoalWeight
                      : onEditGoalWeight,
                ),
              ),
            ],
          ),

          if (percentChange != null && percentChange != 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              percentChange! > 0
                  ? '${percentChange!.abs().toStringAsFixed(1)}% of starting weight lost'
                  : '${percentChange!.abs().toStringAsFixed(1)}% above starting weight',
              style: TextStyle(
                fontSize: AppTypography.caption,
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],

          if (goalWeight != null) ...[
            const SizedBox(height: AppSpacing.md),

            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: goalProgress ?? 0,
                minHeight: 9,
                backgroundColor: colors.surface.withValues(alpha: 0.48),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: Text(
                    goalProgress == null
                        ? 'Goal progress unavailable'
                        : '${(goalProgress! * 100).toStringAsFixed(1)}% to goal',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (remainingText != null)
                  Text(
                    remainingText!,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightHeroMetric extends StatelessWidget {
  const _WeightHeroMetric({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: colors.primary.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.micro,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.55,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 2),
                    Icon(ArcticIcons.edit_outlined, size: 13, color: colors.primary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightRangeSelector extends StatelessWidget {
  const _WeightRangeSelector({
    required this.selectedRange,
    required this.onSelected,
  });

  final WeightChartRange selectedRange;
  final ValueChanged<WeightChartRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          for (final range in WeightChartRange.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(range),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedRange == range
                            ? colors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        range.label,
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.w800,
                          color: selectedRange == range
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressPhotosCard extends StatelessWidget {
  const _ProgressPhotosCard({
    required this.session,
    required this.photos,
    required this.measurementSystem,
    required this.onTap,
  });

  final ProgressPhotoSession? session;
  final List<ProgressPhoto> photos;
  final MeasurementSystem measurementSystem;
  final VoidCallback onTap;

  ProgressPhoto? _photoForType(ProgressPhotoType type) {
    for (final photo in photos) {
      if (photo.type == type) {
        return photo;
      }
    }

    return null;
  }

  int get _standardPhotoCount {
    return [
      ProgressPhotoType.front,
      ProgressPhotoType.side,
      ProgressPhotoType.back,
    ].where((type) => _photoForType(type) != null).length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  ArcticIcons.photo_camera_outlined,
                  color: colors.primary,
                  size: AppIcon.md,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Photos',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session == null
                          ? 'Track visual changes alongside your weight.'
                          : 'Your latest visual progress session.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (session == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(ArcticIcons.add_a_photo_outlined),
                label: const Text('Start Progress Session'),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _ProgressPhotoPreview(
                    label: 'Front',
                    photo: _photoForType(ProgressPhotoType.front),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ProgressPhotoPreview(
                    label: 'Side',
                    photo: _photoForType(ProgressPhotoType.side),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ProgressPhotoPreview(
                    label: 'Back',
                    photo: _photoForType(ProgressPhotoType.back),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _WeightHistoryScreenState._formatFullDate(
                      session!.recordedAt,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  [
                    '$_standardPhotoCount/3',
                    if (session!.weight != null)
                      WeightDisplay.format(session!.weight!, measurementSystem),
                  ].join(' • '),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(ArcticIcons.photo_library_outlined),
                label: const Text('View Progress Photos'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressPhotoPreview extends StatelessWidget {
  const _ProgressPhotoPreview({required this.label, required this.photo});

  final String label;
  final ProgressPhoto? photo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.82,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: photo == null
                ? Container(
                    color: colors.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      ArcticIcons.add_photo_alternate_outlined,
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : Image.file(
                    File(photo!.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colors.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          ArcticIcons.broken_image_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 17, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAnalyticsCard extends StatelessWidget {
  const _PremiumAnalyticsCard({required this.onTap});

  final VoidCallback onTap;

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
              color: colors.outline.withValues(alpha: 0.45),
              width: 1.35,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(ArcticIcons.insights_outlined, color: colors.primary),
              ),

              const SizedBox(width: AppSpacing.md),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Advanced Analytics',
                            style: TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _PremiumBadge(),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Unlock weekly changes, monthly trends, records, projections, and advanced chart ranges.',
                      style: TextStyle(fontSize: AppTypography.caption),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Premium',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _WeightHistoryTile extends StatelessWidget {
  const _WeightHistoryTile({
    required this.record,
    required this.dateLabel,
    required this.measurementSystem,
    required this.onEdit,
    required this.onDelete,
  });

  final WeightRecord record;
  final String dateLabel;
  final MeasurementSystem measurementSystem;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              ArcticIcons.monitor_weight_outlined,
              color: colors.primary,
              size: AppIcon.sm,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(record.recordedAt),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Text(
            WeightDisplay.format(record.weight, measurementSystem),
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(ArcticIcons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(ArcticIcons.delete_outline),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime date) {
    final hour = date.hourOfPeriod == 0 ? 12 : date.hourOfPeriod;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour < 12 ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }
}

class _EmptyWeightHistory extends StatelessWidget {
  const _EmptyWeightHistory({required this.onLogWeight});

  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 32,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.45),
              width: 1.35,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(
                  ArcticIcons.monitor_weight_outlined,
                  size: 30,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No weight entries',
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Log your first weight to begin tracking progress.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onLogWeight,
                icon: const Icon(Icons.add),
                label: const Text('Log First Weight'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartingWeightDialog extends StatefulWidget {
  const _StartingWeightDialog({
    required this.initialWeight,
    required this.measurementSystem,
  });

  final double? initialWeight;
  final MeasurementSystem measurementSystem;

  @override
  State<_StartingWeightDialog> createState() => _StartingWeightDialogState();
}

class _StartingWeightDialogState extends State<_StartingWeightDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialWeight?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_controller.text.trim());

    if (weight == null || weight <= 0) {
      return;
    }

    Navigator.pop(context, weight);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Starting Weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Starting weight',
          suffixText: WeightDisplay.unit(widget.measurementSystem),
          hintText: widget.measurementSystem == MeasurementSystem.metric
              ? '180.0'
              : '395.0',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _GoalWeightDialog extends StatefulWidget {
  const _GoalWeightDialog({
    required this.initialWeight,
    required this.measurementSystem,
  });

  final double? initialWeight;
  final MeasurementSystem measurementSystem;

  @override
  State<_GoalWeightDialog> createState() => _GoalWeightDialogState();
}

class _GoalWeightDialogState extends State<_GoalWeightDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialWeight?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_controller.text.trim());

    if (weight == null || weight <= 0) {
      return;
    }

    Navigator.pop(context, weight);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialWeight == null ? 'Set Goal Weight' : 'Edit Goal Weight',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Goal weight',
          suffixText: WeightDisplay.unit(widget.measurementSystem),
          hintText: widget.measurementSystem == MeasurementSystem.metric
              ? '110.0'
              : '250.0',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _EditWeightEntryDialog extends StatefulWidget {
  const _EditWeightEntryDialog({
    required this.record,
    required this.measurementSystem,
  });

  final WeightRecord record;
  final MeasurementSystem measurementSystem;

  @override
  State<_EditWeightEntryDialog> createState() => _EditWeightEntryDialogState();
}

class _EditWeightEntryDialogState extends State<_EditWeightEntryDialog> {
  late final TextEditingController _controller;
  late DateTime _recordedAt;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: WeightDisplay.displayValue(
        widget.record.weight,
        widget.measurementSystem,
      ).toStringAsFixed(1),
    );

    _recordedAt = widget.record.recordedAt;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _weight {
    final value = double.tryParse(_controller.text.trim());

    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );

    if (selected == null || !mounted) {
      return;
    }

    final updated = DateTime(
      _recordedAt.year,
      _recordedAt.month,
      _recordedAt.day,
      selected.hour,
      selected.minute,
    );

    if (updated.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weight entries cannot be dated in the future.'),
        ),
      );
      return;
    }

    setState(() {
      _recordedAt = updated;
    });
  }

  void _save() {
    final weight = _weight;

    if (weight == null || _recordedAt.isAfter(DateTime.now())) {
      return;
    }

    final storedWeight = WeightDisplay.storageValue(
      weight,
      widget.measurementSystem,
    );

    Navigator.pop(
      context,
      WeightRecord(
        id: widget.record.id,
        weight: storedWeight,
        recordedAt: _recordedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Edit Weight Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: WeightDisplay.unit(widget.measurementSystem),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            InkWell(
              onTap: _chooseDate,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(ArcticIcons.calendar_today_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _WeightHistoryScreenState._formatFullDate(_recordedAt),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            InkWell(
              onTap: _chooseTime,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(ArcticIcons.schedule_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_WeightHistoryTile._formatTime(_recordedAt)),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _weight == null ? null : _save,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _WeightEntryDialog extends StatefulWidget {
  const _WeightEntryDialog({
    required this.initialWeight,
    required this.isFirstEntry,
    required this.measurementSystem,
  });

  final double? initialWeight;
  final bool isFirstEntry;
  final MeasurementSystem measurementSystem;

  @override
  State<_WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<_WeightEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialWeight?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_controller.text.trim());

    if (weight == null || weight <= 0) {
      return;
    }

    Navigator.pop(context, weight);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isFirstEntry ? 'Set Starting Weight' : 'Log Weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Weight',
          suffixText: WeightDisplay.unit(widget.measurementSystem),
          hintText: widget.measurementSystem == MeasurementSystem.metric
              ? '150.0'
              : '350.0',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({
    required List<WeightRecord> records,
    required this.lineColor,
    required this.fillColor,
    required this.guideColor,
    required this.labelColor,
    required this.measurementSystem,
  }) : records = List<WeightRecord>.from(records)
         ..sort(
           (first, second) => first.recordedAt.compareTo(second.recordedAt),
         );

  final List<WeightRecord> records;

  final Color lineColor;
  final Color fillColor;
  final Color guideColor;
  final Color labelColor;
  final MeasurementSystem measurementSystem;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) {
      return;
    }

    const leftPadding = 42.0;
    const rightPadding = 12.0;
    const topPadding = 14.0;
    const bottomPadding = 28.0;

    final width = size.width - leftPadding - rightPadding;

    final height = size.height - topPadding - bottomPadding;

    final weights = records.map((record) => record.weight).toList();

    final minimum = weights.reduce(
      (first, second) => first < second ? first : second,
    );

    final maximum = weights.reduce(
      (first, second) => first > second ? first : second,
    );

    final rawRange = maximum - minimum;

    final range = rawRange == 0 ? 2.0 : rawRange;

    final chartMinimum = rawRange == 0 ? minimum - 1 : minimum;

    final gridPaint = Paint()
      ..color = guideColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final y = topPadding + height * (index / 4);

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final weight = chartMinimum + range * (1 - index / 4);

      final displayedWeight = WeightDisplay.displayValue(
        weight,
        measurementSystem,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: displayedWeight.toStringAsFixed(1),
          style: TextStyle(color: labelColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(
          leftPadding - labelPainter.width - 6,
          y - labelPainter.height / 2,
        ),
      );
    }

    if (records.length == 1) {
      canvas.drawCircle(
        Offset(leftPadding + width / 2, topPadding + height / 2),
        4,
        Paint()..color = lineColor,
      );

      return;
    }

    final points = <Offset>[];

    for (var index = 0; index < records.length; index++) {
      final x = leftPadding + width * (index / (records.length - 1));

      final normalized = (records[index].weight - chartMinimum) / range;

      final y = topPadding + height * (1 - normalized);

      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 1; index < points.length; index++) {
      linePath.lineTo(points[index].dx, points[index].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, topPadding + height)
      ..lineTo(points.first.dx, topPadding + height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      points.last,
      4.5,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    if (measurementSystem != oldDelegate.measurementSystem ||
        lineColor != oldDelegate.lineColor ||
        fillColor != oldDelegate.fillColor ||
        guideColor != oldDelegate.guideColor ||
        labelColor != oldDelegate.labelColor ||
        records.length != oldDelegate.records.length) {
      return true;
    }

    for (var index = 0; index < records.length; index++) {
      if (records[index].id != oldDelegate.records[index].id ||
          records[index].weight != oldDelegate.records[index].weight ||
          records[index].recordedAt != oldDelegate.records[index].recordedAt) {
        return true;
      }
    }

    return false;
  }
}

extension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final values = toList();

    if (values.length <= count) {
      return values;
    }

    return values.skip(values.length - count);
  }
}

extension on DateTime {
  int get hourOfPeriod {
    final value = hour % 12;

    return value == 0 ? 12 : value;
  }
}

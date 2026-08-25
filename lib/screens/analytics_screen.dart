import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/dose_record.dart';
import '../models/measurement_system.dart';
import '../models/profile.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';
import '../services/analytics_service.dart';
import '../services/app_data_service.dart';
import '../services/missed_dose_reconciliation_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/weight_display.dart';
import 'premium_screen.dart';
import '../theme/arctic_icons.dart';

enum AnalyticsRange { thirtyDays, ninetyDays, sixMonths, all }

extension AnalyticsRangeDetails on AnalyticsRange {
  String get label {
    return switch (this) {
      AnalyticsRange.thirtyDays => '30 Days',
      AnalyticsRange.ninetyDays => '90 Days',
      AnalyticsRange.sixMonths => '6 Months',
      AnalyticsRange.all => 'All',
    };
  }

  DateTime? startDate(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    return switch (this) {
      AnalyticsRange.thirtyDays => today.subtract(const Duration(days: 29)),
      AnalyticsRange.ninetyDays => today.subtract(const Duration(days: 89)),
      AnalyticsRange.sixMonths => DateTime(
        today.year,
        today.month - 6,
        today.day,
      ),
      AnalyticsRange.all => null,
    };
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    required this.dataService,
    required this.protocols,
    required this.measurementSystem,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;
  final MeasurementSystem measurementSystem;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = const AnalyticsService();

  final MissedDoseReconciliationService _missedDoseReconciliationService =
      const MissedDoseReconciliationService();

  final ProfileService _profileService = ProfileService();

  AnalyticsSummary? _summary;
  Profile? _profile;

  List<WeightRecord> _filteredWeightRecords = [];
  List<DoseRecord> _filteredDoseRecords = [];

  bool _isLoading = true;
  String? _loadError;

  AnalyticsRange _selectedRange = AnalyticsRange.thirtyDays;

  bool get _hasPremium => widget.dataService.hasPremium;

  @override
  void initState() {
    super.initState();

    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await _missedDoseReconciliationService.reconcile(
        dataService: widget.dataService,
        protocols: widget.protocols,
      );

      final doseRecords = await widget.dataService.getAllDoseRecords();

      final weightRecords = await widget.dataService.getWeightRecords();

      final profile = await _profileService.getActiveProfile();

      final now = DateTime.now();

      final startDate = _selectedRange.startDate(now);

      final filteredDoseRecords = startDate == null
          ? List<DoseRecord>.from(doseRecords)
          : doseRecords.where((record) {
              return !record.scheduledFor.isBefore(startDate);
            }).toList();

      filteredDoseRecords.sort(
        (first, second) => first.scheduledFor.compareTo(second.scheduledFor),
      );

      final filteredWeightRecords = startDate == null
          ? List<WeightRecord>.from(weightRecords)
          : weightRecords.where((record) {
              return !record.recordedAt.isBefore(startDate);
            }).toList();

      filteredWeightRecords.sort(
        (first, second) => first.recordedAt.compareTo(second.recordedAt),
      );

      final summary = _analyticsService.calculate(
        doseRecords: doseRecords,
        protocols: widget.protocols,
        weightRecords: weightRecords,
        startDate: startDate,
        now: now,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
        _profile = profile;
        _filteredDoseRecords = filteredDoseRecords;
        _filteredWeightRecords = filteredWeightRecords;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAnalytics,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_loadError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: 80),
          _AnalyticsErrorState(onRetry: _loadAnalytics),
        ],
      );
    }

    final summary = _summary;

    if (!_hasPremium) {
      return _PremiumAnalyticsPreview(onUpgrade: _openPremium);
    }

    if (summary == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No analytics data available.')),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        80,
      ),
      children: [
        _AnalyticsRangeSelector(
          selectedRange: _selectedRange,
          onChanged: (range) {
            if (range == _selectedRange) {
              return;
            }

            setState(() {
              _selectedRange = range;
            });

            _loadAnalytics();
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        _OverviewCard(
          weight: summary.weight,
          adherence: summary.adherence,
          profile: _profile,
          measurementSystem: widget.measurementSystem,
        ),

        const SizedBox(height: AppSpacing.lg),

        _SectionHeader(
          title: 'Weight',
          subtitle: summary.weight.hasData
              ? '${summary.weight.entryCount} weight entries'
              : 'No weight data yet',
        ),

        const SizedBox(height: AppSpacing.sm),

        _WeightTrendChart(
          records: _filteredWeightRecords,
          measurementSystem: widget.measurementSystem,
        ),

        const SizedBox(height: AppSpacing.sm),

        _WeightAnalyticsSection(
          analytics: summary.weight,
          measurementSystem: widget.measurementSystem,
        ),

        const SizedBox(height: AppSpacing.lg),

        _SectionHeader(
          title: 'BMI',
          subtitle: (_profile?.heightCm ?? 0) > 0
              ? 'Estimated from your saved height and weight history'
              : 'Add height to your profile to unlock BMI trends',
        ),

        const SizedBox(height: AppSpacing.sm),

        _BmiAnalyticsSection(
          records: _filteredWeightRecords,
          heightCm: _profile?.heightCm,
        ),

        const SizedBox(height: AppSpacing.lg),

        _SectionHeader(
          title: 'Protocol Adherence',
          subtitle: summary.adherence.hasData
              ? '${summary.adherence.totalRecords} tracked dose records'
              : 'No dose history yet',
        ),

        const SizedBox(height: AppSpacing.sm),

        _AdherenceTrendCard(records: _filteredDoseRecords),

        const SizedBox(height: AppSpacing.sm),

        _AdherenceSection(analytics: summary.adherence),

        const SizedBox(height: AppSpacing.lg),

        const _SectionHeader(
          title: 'Activity',
          subtitle: 'Recent logging activity',
        ),

        const SizedBox(height: AppSpacing.sm),

        _ActivitySection(analytics: summary.activity),

        const SizedBox(height: AppSpacing.lg),

        _ProtocolBreakdownSection(analytics: summary.adherence),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.weight,
    required this.adherence,
    required this.profile,
    required this.measurementSystem,
  });

  final WeightAnalytics weight;
  final AdherenceAnalytics adherence;
  final Profile? profile;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final goalProgress = _calculateGoalProgress(
      currentWeight: weight.currentWeight,
      startingWeight: profile?.startingWeight ?? weight.startingWeight,
      goalWeight: profile?.goalWeight,
    );

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
          const Text(
            'Progress Overview',
            style: TextStyle(
              fontSize: AppTypography.pageTitle,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your weight and protocol performance at a glance.',
            style: TextStyle(
              fontSize: AppTypography.body,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'WEIGHT CHANGE',
                  value: _formatWeightChange(
                    weight.totalChange,
                    measurementSystem,
                  ),
                  icon: ArcticIcons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewMetric(
                  label: 'ADHERENCE',
                  value: adherence.hasData
                      ? '${adherence.adherencePercent.toStringAsFixed(1)}%'
                      : '—',
                  icon: ArcticIcons.task_alt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'CURRENT STREAK',
                  value: adherence.hasData
                      ? '${adherence.currentStreak} '
                            '${adherence.currentStreak == 1 ? 'dose' : 'doses'}'
                      : '—',
                  icon: ArcticIcons.local_fire_department_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewMetric(
                  label: 'GOAL PROGRESS',
                  value: goalProgress == null
                      ? '—'
                      : '${goalProgress.toStringAsFixed(0)}%',
                  icon: ArcticIcons.flag_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTypography.title,
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
      ],
    );
  }
}

class _WeightTrendChart extends StatelessWidget {
  const _WeightTrendChart({
    required this.records,
    required this.measurementSystem,
  });

  final List<WeightRecord> records;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (records.isEmpty) {
      return const _EmptyAnalyticsCard(
        icon: ArcticIcons.show_chart,
        text: 'Weight trend will appear after weight entries are logged.',
      );
    }

    final sorted = List<WeightRecord>.from(records)
      ..sort((first, second) => first.recordedAt.compareTo(second.recordedAt));

    final minimumWeight = sorted
        .map((record) => record.weight)
        .reduce((first, second) => first < second ? first : second);

    final maximumWeight = sorted
        .map((record) => record.weight)
        .reduce((first, second) => first > second ? first : second);

    final displayedMinimum = WeightDisplay.displayValue(
      minimumWeight,
      measurementSystem,
    );

    final displayedMaximum = WeightDisplay.displayValue(
      maximumWeight,
      measurementSystem,
    );

    final unit = WeightDisplay.unit(measurementSystem);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  ArcticIcons.show_chart_rounded,
                  color: colors.primary,
                  size: AppIcon.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Weight Trend',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${displayedMinimum.toStringAsFixed(1)}–'
                '${displayedMaximum.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _AnalyticsWeightChartPainter(
                  records: sorted,
                  lineColor: colors.primary,
                  guideColor: colors.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatAnalyticsDate(sorted.first.recordedAt),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                _formatAnalyticsDate(sorted.last.recordedAt),
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsWeightChartPainter extends CustomPainter {
  _AnalyticsWeightChartPainter({
    required List<WeightRecord> records,
    required this.lineColor,
    required this.guideColor,
  }) : records = List<WeightRecord>.from(records)
         ..sort(
           (first, second) => first.recordedAt.compareTo(second.recordedAt),
         );

  final List<WeightRecord> records;
  final Color lineColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) {
      return;
    }

    const horizontalPadding = 12.0;
    const verticalPadding = 16.0;

    final chartWidth = size.width - horizontalPadding * 2;

    final chartHeight = size.height - verticalPadding * 2;

    final weights = records.map((record) => record.weight).toList();

    final minimumWeight = weights.reduce(
      (first, second) => first < second ? first : second,
    );

    final maximumWeight = weights.reduce(
      (first, second) => first > second ? first : second,
    );

    final range = maximumWeight - minimumWeight;

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final y = verticalPadding + chartHeight * (index / 3);

      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        guidePaint,
      );
    }

    if (records.length == 1) {
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, pointPaint);

      return;
    }

    final firstDate = records.first.recordedAt;

    final lastDate = records.last.recordedAt;

    final totalMinutes = lastDate.difference(firstDate).inMinutes.abs();

    final points = <Offset>[];

    for (final record in records) {
      final elapsedMinutes = record.recordedAt
          .difference(firstDate)
          .inMinutes
          .abs();

      final xRatio = totalMinutes == 0 ? 0.5 : elapsedMinutes / totalMinutes;

      final weightRatio = range == 0
          ? 0.5
          : (record.weight - minimumWeight) / range;

      final x = horizontalPadding + chartWidth * xRatio;

      final y = verticalPadding + chartHeight * (1 - weightRatio);

      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(points.last, 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalyticsWeightChartPainter oldDelegate) {
    if (lineColor != oldDelegate.lineColor ||
        guideColor != oldDelegate.guideColor ||
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

class _WeightAnalyticsSection extends StatelessWidget {
  const _WeightAnalyticsSection({
    required this.analytics,
    required this.measurementSystem,
  });

  final WeightAnalytics analytics;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    if (!analytics.hasData) {
      return const _EmptyAnalyticsCard(
        icon: ArcticIcons.monitor_weight_outlined,
        text: 'Log weight entries to unlock weight analytics.',
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Current',
                value: analytics.currentWeight == null
                    ? '—'
                    : WeightDisplay.format(
                        analytics.currentWeight!,
                        measurementSystem,
                      ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Total change',
                value: _formatWeightChange(
                  analytics.totalChange,
                  measurementSystem,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '7-day change',
                value: _formatSignedWeight(
                  analytics.change7Days,
                  measurementSystem,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: '30-day change',
                value: _formatSignedWeight(
                  analytics.change30Days,
                  measurementSystem,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Lowest',
                value: analytics.lowestWeight == null
                    ? '—'
                    : WeightDisplay.format(
                        analytics.lowestWeight!,
                        measurementSystem,
                      ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Highest',
                value: analytics.highestWeight == null
                    ? '—'
                    : WeightDisplay.format(
                        analytics.highestWeight!,
                        measurementSystem,
                      ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Avg weekly change',
                value: _formatSignedWeight(
                  analytics.averageWeeklyChange,
                  measurementSystem,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Body-weight change',
                value: analytics.percentChange == null
                    ? '—'
                    : '${analytics.percentChange!.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BmiAnalyticsSection extends StatelessWidget {
  const _BmiAnalyticsSection({required this.records, required this.heightCm});

  final List<WeightRecord> records;
  final double? heightCm;

  @override
  Widget build(BuildContext context) {
    final height = heightCm;

    if (height == null || height <= 0) {
      return const _EmptyAnalyticsCard(
        icon: ArcticIcons.height_rounded,
        text: 'Add height to your profile to calculate BMI analytics.',
      );
    }

    if (records.isEmpty) {
      return const _EmptyAnalyticsCard(
        icon: ArcticIcons.monitor_heart_outlined,
        text: 'BMI trends will appear after weight entries are logged.',
      );
    }

    final sorted = List<WeightRecord>.from(records)
      ..sort((first, second) => first.recordedAt.compareTo(second.recordedAt));

    final startingBmi = _calculateBmi(sorted.first.weight, height);
    final currentBmi = _calculateBmi(sorted.last.weight, height);
    final bmiChange = currentBmi - startingBmi;

    return Column(
      children: [
        _BmiTrendChart(records: sorted, heightCm: height),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Starting BMI',
                value: startingBmi.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'Current BMI',
                value: currentBmi.toStringAsFixed(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'BMI change',
                value: _formatSignedBmi(bmiChange),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'Current range',
                value: _bmiCategory(currentBmi),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BmiTrendChart extends StatelessWidget {
  const _BmiTrendChart({required this.records, required this.heightCm});

  final List<WeightRecord> records;
  final double heightCm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    final bmiValues = records
        .map((record) => _calculateBmi(record.weight, heightCm))
        .toList(growable: false);

    final minimumBmi = bmiValues.reduce(
      (first, second) => first < second ? first : second,
    );
    final maximumBmi = bmiValues.reduce(
      (first, second) => first > second ? first : second,
    );

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  ArcticIcons.monitor_heart_outlined,
                  color: colors.primary,
                  size: AppIcon.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'BMI Trend',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${minimumBmi.toStringAsFixed(1)}–'
                '${maximumBmi.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _BmiTrendPainter(
                  records: records,
                  heightCm: heightCm,
                  lineColor: colors.primary,
                  guideColor: colors.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatAnalyticsDate(records.first.recordedAt),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                _formatAnalyticsDate(records.last.recordedAt),
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BmiTrendPainter extends CustomPainter {
  _BmiTrendPainter({
    required this.records,
    required this.heightCm,
    required this.lineColor,
    required this.guideColor,
  });

  final List<WeightRecord> records;
  final double heightCm;
  final Color lineColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    const horizontalPadding = 12.0;
    const verticalPadding = 16.0;

    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;

    final values = records
        .map((record) => _calculateBmi(record.weight, heightCm))
        .toList(growable: false);

    final minimum = values.reduce(
      (first, second) => first < second ? first : second,
    );
    final maximum = values.reduce(
      (first, second) => first > second ? first : second,
    );
    final range = maximum - minimum;

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final y = verticalPadding + chartHeight * (index / 3);
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        guidePaint,
      );
    }

    if (records.length == 1) {
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, pointPaint);
      return;
    }

    final firstDate = records.first.recordedAt;
    final lastDate = records.last.recordedAt;
    final totalMinutes = lastDate.difference(firstDate).inMinutes.abs();

    final points = <Offset>[];

    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      final elapsedMinutes = record.recordedAt
          .difference(firstDate)
          .inMinutes
          .abs();

      final xRatio = totalMinutes == 0 ? 0.5 : elapsedMinutes / totalMinutes;
      final bmiRatio = range == 0 ? 0.5 : (values[index] - minimum) / range;

      points.add(
        Offset(
          horizontalPadding + chartWidth * xRatio,
          verticalPadding + chartHeight * (1 - bmiRatio),
        ),
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(points.last, 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _BmiTrendPainter oldDelegate) {
    if (heightCm != oldDelegate.heightCm ||
        lineColor != oldDelegate.lineColor ||
        guideColor != oldDelegate.guideColor ||
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

double _calculateBmi(double weightLb, double heightCm) {
  final heightMeters = heightCm / 100;
  final weightKg = weightLb * 0.45359237;
  return weightKg / (heightMeters * heightMeters);
}

String _formatSignedBmi(double value) {
  if (value.abs() < 0.05) {
    return '0.0';
  }

  return '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}';
}

String _bmiCategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Healthy range';
  if (bmi < 30) return 'Overweight';
  if (bmi < 35) return 'Obesity class I';
  if (bmi < 40) return 'Obesity class II';
  return 'Obesity class III';
}

class _AdherenceTrendCard extends StatelessWidget {
  const _AdherenceTrendCard({required this.records});

  final List<DoseRecord> records;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final points = _buildWeeklyAdherencePoints(records);

    if (points.isEmpty) {
      return const _EmptyAnalyticsCard(
        icon: ArcticIcons.insights_outlined,
        text: 'Adherence trend will appear after dose history is tracked.',
      );
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  ArcticIcons.insights_rounded,
                  color: colors.primary,
                  size: AppIcon.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Weekly Adherence',
                  style: TextStyle(
                    fontSize: AppTypography.body,
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
                  '${points.length} ${points.length == 1 ? 'week' : 'weeks'}',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _AdherenceTrendPainter(
                  points: points,
                  lineColor: colors.primary,
                  guideColor: colors.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatAnalyticsDate(points.first.weekStart),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                _formatAnalyticsDate(points.last.weekStart),
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyAdherencePoint {
  const _WeeklyAdherencePoint({
    required this.weekStart,
    required this.total,
    required this.taken,
  });

  final DateTime weekStart;
  final int total;
  final int taken;

  double get percent {
    if (total == 0) {
      return 0;
    }

    return taken / total * 100;
  }
}

class _AdherenceTrendPainter extends CustomPainter {
  _AdherenceTrendPainter({
    required this.points,
    required this.lineColor,
    required this.guideColor,
  });

  final List<_WeeklyAdherencePoint> points;
  final Color lineColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const horizontalPadding = 12.0;
    const verticalPadding = 14.0;

    final chartWidth = size.width - horizontalPadding * 2;

    final chartHeight = size.height - verticalPadding * 2;

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    for (var index = 0; index < 3; index++) {
      final y = verticalPadding + chartHeight * (index / 2);

      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        guidePaint,
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final offsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : horizontalPadding + chartWidth * (index / (points.length - 1));

      final percent = points[index].percent.clamp(0.0, 100.0);

      final y = verticalPadding + chartHeight * (1 - percent / 100);

      offsets.add(Offset(x, y));
    }

    if (offsets.length == 1) {
      canvas.drawCircle(offsets.first, 4, pointPaint);

      return;
    }

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);

    for (var index = 1; index < offsets.length; index++) {
      path.lineTo(offsets[index].dx, offsets[index].dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in offsets) {
      canvas.drawCircle(point, 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdherenceTrendPainter oldDelegate) {
    if (lineColor != oldDelegate.lineColor ||
        guideColor != oldDelegate.guideColor ||
        points.length != oldDelegate.points.length) {
      return true;
    }

    for (var index = 0; index < points.length; index++) {
      if (points[index].weekStart != oldDelegate.points[index].weekStart ||
          points[index].total != oldDelegate.points[index].total ||
          points[index].taken != oldDelegate.points[index].taken) {
        return true;
      }
    }

    return false;
  }
}

class _AdherenceSection extends StatelessWidget {
  const _AdherenceSection({required this.analytics});

  final AdherenceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    if (!analytics.hasData) {
      return const _EmptyAnalyticsCard(
        icon: LucideIcons.syringe,
        text: 'Dose history will appear here as records are logged.',
      );
    }

    return Column(
      children: [
        _AdherenceProgressCard(
          adherencePercent: analytics.adherencePercent,
          taken: analytics.takenDoses,
          total: analytics.totalRecords,
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Taken',
                value: '${analytics.takenDoses}',
                icon: Icons.check_rounded,
                accentColor: Colors.green,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Skipped',
                value: '${analytics.skippedDoses}',
                icon: Icons.remove_rounded,
                accentColor: Colors.amber,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Missed',
                value: '${analytics.missedDoses}',
                icon: ArcticIcons.priority_high_rounded,
                accentColor: Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Current streak',
                value:
                    '${analytics.currentStreak} '
                    '${analytics.currentStreak == 1 ? 'dose' : 'doses'}',
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Longest streak',
                value:
                    '${analytics.longestStreak} '
                    '${analytics.longestStreak == 1 ? 'dose' : 'doses'}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdherenceProgressCard extends StatelessWidget {
  const _AdherenceProgressCard({
    required this.adherencePercent,
    required this.taken,
    required this.total,
  });

  final double adherencePercent;
  final int taken;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (adherencePercent / 100).clamp(0.0, 1.0);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  ArcticIcons.task_alt_rounded,
                  color: colors.primary,
                  size: AppIcon.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Overall Adherence',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${adherencePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colors.primary.withValues(alpha: 0.10),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$taken of $total tracked doses taken',
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

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.analytics});

  final ActivityAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Doses this week',
                value: '${analytics.dosesThisWeek}',
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Doses this month',
                value: '${analytics.dosesThisMonth}',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Weights this week',
                value: '${analytics.weightEntriesThisWeek}',
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _MetricCard(
                label: 'Weights this month',
                value: '${analytics.weightEntriesThisMonth}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProtocolBreakdownSection extends StatelessWidget {
  const _ProtocolBreakdownSection({required this.analytics});

  final AdherenceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Protocol Breakdown',
          subtitle: 'Adherence by protocol',
        ),

        const SizedBox(height: AppSpacing.sm),

        if (analytics.byProtocol.isEmpty)
          const _EmptyAnalyticsCard(
            icon: ArcticIcons.analytics_outlined,
            text: 'Protocol breakdown will appear after doses are tracked.',
          )
        else
          for (var index = 0; index < analytics.byProtocol.length; index++) ...[
            _ProtocolAdherenceCard(analytics: analytics.byProtocol[index]),
            if (index < analytics.byProtocol.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],

        const SizedBox(height: AppSpacing.sm),

        Text(
          'Premium analytics summarize your logged history. '
          'They do not determine whether a protocol caused a weight change.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProtocolAdherenceCard extends StatelessWidget {
  const _ProtocolAdherenceCard({required this.analytics});

  final ProtocolAdherenceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (analytics.adherencePercent / 100).clamp(0.0, 1.0);
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
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  LucideIcons.syringe,
                  color: colors.primary,
                  size: AppIcon.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  analytics.protocolName,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${analytics.adherencePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.primary.withValues(alpha: 0.10),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniStatusMetric(
                  label: 'Taken',
                  value: analytics.takenDoses,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _MiniStatusMetric(
                  label: 'Skipped',
                  value: analytics.skippedDoses,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _MiniStatusMetric(
                  label: 'Missed',
                  value: analytics.missedDoses,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatusMetric extends StatelessWidget {
  const _MiniStatusMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAnalyticsPreview extends StatelessWidget {
  const _PremiumAnalyticsPreview({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            colors.primary.withValues(alpha: 0.26),
            colors.primaryContainer.withValues(alpha: 0.12),
          ]
        : [
            colors.primary.withValues(alpha: 0.14),
            colors.primaryContainer.withValues(alpha: 0.50),
          ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
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
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    colors.primary,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/branding/modose_premium_mark.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Advanced Progress Analytics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.pageTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Turn your logged history into detailed progress, adherence, and activity insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.body,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _AnalyticsPremiumFeature(
          icon: ArcticIcons.show_chart,
          text: 'Weight trends and progress metrics',
        ),
        const _AnalyticsPremiumFeature(
          icon: ArcticIcons.monitor_heart_outlined,
          text: 'BMI trends and change over time',
        ),
        const _AnalyticsPremiumFeature(
          icon: LucideIcons.syringe,
          text: 'Protocol adherence and streak tracking',
        ),
        const _AnalyticsPremiumFeature(
          icon: ArcticIcons.insights_outlined,
          text: 'Weekly adherence trends',
        ),
        const _AnalyticsPremiumFeature(
          icon: ArcticIcons.analytics_outlined,
          text: 'Per-protocol performance breakdown',
        ),
        const _AnalyticsPremiumFeature(
          icon: ArcticIcons.history_outlined,
          text: 'Activity and logging insights',
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: onUpgrade,
          icon: ColorFiltered(
            colorFilter: ColorFilter.mode(
              colors.onPrimary,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/branding/modose_premium_mark.png',
              width: 23,
              height: 23,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          label: const Text(
            'Upgrade to MODOSE Premium',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsPremiumFeature extends StatelessWidget {
  const _AnalyticsPremiumFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.60),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: colors.primary, size: AppIcon.sm),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;
    final accent = accentColor ?? colors.primary;

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
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
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

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(icon, size: 24, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            textAlign: TextAlign.center,
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

class _AnalyticsErrorState extends StatelessWidget {
  const _AnalyticsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.error.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(ArcticIcons.error_outline_rounded, size: 42, color: colors.error),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Could not load analytics.',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsRangeSelector extends StatelessWidget {
  const _AnalyticsRangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  final AnalyticsRange selectedRange;
  final ValueChanged<AnalyticsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          for (final range in AnalyticsRange.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => onChanged(range),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: selectedRange == range
                            ? colors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        range.label,
                        textAlign: TextAlign.center,
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

List<_WeeklyAdherencePoint> _buildWeeklyAdherencePoints(
  List<DoseRecord> records,
) {
  if (records.isEmpty) {
    return const [];
  }

  final grouped = <DateTime, List<DoseRecord>>{};

  for (final record in records) {
    final date = record.scheduledFor;

    final day = DateTime(date.year, date.month, date.day);

    final weekStart = day.subtract(
      Duration(days: day.weekday - DateTime.monday),
    );

    grouped.putIfAbsent(weekStart, () => <DoseRecord>[]);

    grouped[weekStart]!.add(record);
  }

  final points = grouped.entries.map((entry) {
    final recordsForWeek = entry.value;

    final taken = recordsForWeek.where((record) {
      return record.status == DoseRecordStatus.taken;
    }).length;

    return _WeeklyAdherencePoint(
      weekStart: entry.key,
      total: recordsForWeek.length,
      taken: taken,
    );
  }).toList();

  points.sort((first, second) => first.weekStart.compareTo(second.weekStart));

  return points;
}

double? _calculateGoalProgress({
  required double? currentWeight,
  required double? startingWeight,
  required double? goalWeight,
}) {
  if (currentWeight == null || startingWeight == null || goalWeight == null) {
    return null;
  }

  final totalDistance = startingWeight - goalWeight;

  if (totalDistance == 0) {
    return null;
  }

  final completedDistance = startingWeight - currentWeight;

  return (completedDistance / totalDistance * 100).clamp(0.0, 100.0);
}

String _formatAnalyticsDate(DateTime value) {
  return '${value.month}/'
      '${value.day}/'
      '${value.year}';
}

String _formatSignedWeight(double? value, MeasurementSystem measurementSystem) {
  if (value == null) {
    return '—';
  }

  final displayedValue = WeightDisplay.displayValue(
    value.abs(),
    measurementSystem,
  );

  final unit = WeightDisplay.unit(measurementSystem);

  if (value == 0) {
    return '0.0 $unit';
  }

  final prefix = value > 0 ? '+' : '-';

  return '$prefix'
      '${displayedValue.toStringAsFixed(1)} $unit';
}

String _formatWeightChange(double? value, MeasurementSystem measurementSystem) {
  if (value == null) {
    return '—';
  }

  if (value == 0) {
    return 'No change';
  }

  final displayedValue = WeightDisplay.displayValue(
    value.abs(),
    measurementSystem,
  );

  final unit = WeightDisplay.unit(measurementSystem);

  if (value < 0) {
    return '${displayedValue.toStringAsFixed(1)} '
        '$unit lost';
  }

  return '${displayedValue.toStringAsFixed(1)} '
      '$unit gained';
}

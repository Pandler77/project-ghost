import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/symptom_entry.dart';
import '../services/symptom_service.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';
import '../widgets/app_select_field.dart';

enum _SymptomRange { sevenDays, thirtyDays, ninetyDays, sixMonths, oneYear }

class SymptomHistoryScreen extends StatefulWidget {
  const SymptomHistoryScreen({super.key, this.initialSymptom});

  final String? initialSymptom;

  @override
  State<SymptomHistoryScreen> createState() => _SymptomHistoryScreenState();
}

class _SymptomHistoryScreenState extends State<SymptomHistoryScreen> {
  final SymptomService _symptomService = SymptomService();

  List<SymptomEntry> _allEntries = [];
  List<String> _symptomNames = [];

  String? _selectedSymptom;
  _SymptomRange _selectedRange = _SymptomRange.thirtyDays;

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _symptomService.getAllEntries(),
        _symptomService.getSymptomNames(),
      ]);

      final entries = results[0] as List<SymptomEntry>;
      final names = results[1] as List<String>;

      entries.sort(
        (first, second) => first.recordedAt.compareTo(second.recordedAt),
      );

      String? selected = _selectedSymptom;

      if (selected == null && widget.initialSymptom != null) {
        for (final name in names) {
          if (name.toLowerCase() == widget.initialSymptom!.toLowerCase()) {
            selected = name;
            break;
          }
        }
      }

      if (selected == null && names.isNotEmpty) {
        selected = names.first;
      }

      if (selected != null &&
          !names.any((name) => name.toLowerCase() == selected!.toLowerCase())) {
        selected = names.isEmpty ? null : names.first;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _allEntries = entries;
        _symptomNames = names;
        _selectedSymptom = selected;
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

  List<SymptomEntry> get _filteredEntries {
    final symptom = _selectedSymptom;

    if (symptom == null) {
      return [];
    }

    final now = DateTime.now();
    final start = _rangeStart(now);

    return _allEntries.where((entry) {
      return entry.symptomName.toLowerCase() == symptom.toLowerCase() &&
          !entry.recordedAt.isBefore(start);
    }).toList();
  }

  DateTime _rangeStart(DateTime now) {
    switch (_selectedRange) {
      case _SymptomRange.sevenDays:
        return now.subtract(const Duration(days: 7));

      case _SymptomRange.thirtyDays:
        return now.subtract(const Duration(days: 30));

      case _SymptomRange.ninetyDays:
        return now.subtract(const Duration(days: 90));

      case _SymptomRange.sixMonths:
        return DateTime(now.year, now.month - 6, now.day);

      case _SymptomRange.oneYear:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  double get _averageSeverity {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return 0;
    }

    final total = entries.fold<int>(0, (sum, entry) => sum + entry.severity);

    return total / entries.length;
  }

  int get _highestSeverity {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return 0;
    }

    return entries.map((entry) => entry.severity).reduce(math.max);
  }

  int get _latestSeverity {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return 0;
    }

    return entries.last.severity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom History')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(ArcticIcons.error_outline, size: 48),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Could not load symptom history.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_symptomNames.isEmpty) {
      return _buildEmptyState();
    }

    final entries = _filteredEntries;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          40,
        ),
        children: [
          _buildSymptomSelector(),
          const SizedBox(height: AppSpacing.md),
          _buildRangeSelector(),
          const SizedBox(height: AppSpacing.lg),
          _buildSummary(entries),
          const SizedBox(height: AppSpacing.lg),
          _buildChartCard(entries),
          const SizedBox(height: AppSpacing.lg),
          _buildHistory(entries),
        ],
      ),
    );
  }

  Widget _buildSymptomSelector() {
    return AppSelectField<String>(
      value: _selectedSymptom,
      values: _symptomNames,
      label: 'Symptom',
      placeholder: 'Choose a symptom',
      prefixIcon: const Icon(ArcticIcons.monitor_heart_outlined),
      labelBuilder: (value) => value,
      onChanged: (value) {
        setState(() {
          _selectedSymptom = value;
        });
      },
    );
  }

  Widget _buildRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_SymptomRange>(
        segments: const [
          ButtonSegment(value: _SymptomRange.sevenDays, label: Text('7D')),
          ButtonSegment(value: _SymptomRange.thirtyDays, label: Text('30D')),
          ButtonSegment(value: _SymptomRange.ninetyDays, label: Text('90D')),
          ButtonSegment(value: _SymptomRange.sixMonths, label: Text('6M')),
          ButtonSegment(value: _SymptomRange.oneYear, label: Text('1Y')),
        ],
        selected: {_selectedRange},
        onSelectionChanged: (selection) {
          setState(() {
            _selectedRange = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildSummary(List<SymptomEntry> entries) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(label: 'Reports', value: '${entries.length}'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'Average',
            value: entries.isEmpty
                ? '—'
                : '${_averageSeverity.toStringAsFixed(1)}/5',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'Highest',
            value: entries.isEmpty ? '—' : '$_highestSeverity/5',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricCard(
            label: 'Latest',
            value: entries.isEmpty ? '—' : '$_latestSeverity/5',
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(List<SymptomEntry> entries) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Severity Trend',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reported severity from 1–5.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            SizedBox(
              height: 210,
              child: Center(
                child: Text(
                  'No reports in this range.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else
            SizedBox(
              height: 230,
              width: double.infinity,
              child: CustomPaint(
                painter: _SymptomChartPainter(
                  entries: entries,
                  lineColor: colors.primary,
                  gridColor: colors.outlineVariant,
                  labelColor: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistory(List<SymptomEntry> entries) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          Text(
            'No symptom reports in this range.',
            style: TextStyle(color: colors.onSurfaceVariant),
          )
        else
          for (final entry in entries.reversed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(
                      '${entry.severity}',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(entry.recordedAt),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${entry.severity}/5 • '
                          '${_severityDescription(entry.severity)}',
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (entry.notes != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            entry.notes!,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ArcticIcons.monitor_heart_outlined,
              size: 56,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No symptom history yet',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Symptoms you log will appear here over time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomChartPainter extends CustomPainter {
  const _SymptomChartPainter({
    required this.entries,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<SymptomEntry> entries;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) {
      return;
    }

    const leftPadding = 30.0;
    const rightPadding = 12.0;
    const topPadding = 12.0;
    const bottomPadding = 28.0;

    final chartWidth = size.width - leftPadding - rightPadding;

    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (var severity = 1; severity <= 5; severity++) {
      final y = topPadding + chartHeight * (1 - ((severity - 1) / 4));

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      final painter = TextPainter(
        text: TextSpan(
          text: '$severity',
          style: TextStyle(fontSize: 11, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(leftPadding - painter.width - 8, y - painter.height / 2),
      );
    }

    final firstDate = entries.first.recordedAt;
    final lastDate = entries.last.recordedAt;

    final totalMilliseconds = math.max(
      1,
      lastDate.difference(firstDate).inMilliseconds,
    );

    Offset pointFor(SymptomEntry entry) {
      final elapsed = entry.recordedAt.difference(firstDate).inMilliseconds;

      final xRatio = entries.length == 1 ? 0.5 : elapsed / totalMilliseconds;

      final severityRatio = (entry.severity - 1) / 4;

      final x = leftPadding + chartWidth * xRatio;

      final y = topPadding + chartHeight * (1 - severityRatio);

      return Offset(x, y);
    }

    if (entries.length > 1) {
      final path = Path();

      for (var index = 0; index < entries.length; index++) {
        final point = pointFor(entries[index]);

        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(path, linePaint);
    }

    for (final entry in entries) {
      canvas.drawCircle(pointFor(entry), 4.5, pointPaint);
    }

    final startLabel = TextPainter(
      text: TextSpan(
        text: _shortDate(firstDate),
        style: TextStyle(fontSize: 10, color: labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    startLabel.paint(
      canvas,
      Offset(leftPadding, size.height - startLabel.height),
    );

    if (entries.length > 1) {
      final endLabel = TextPainter(
        text: TextSpan(
          text: _shortDate(lastDate),
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      endLabel.paint(
        canvas,
        Offset(
          size.width - rightPadding - endLabel.width,
          size.height - endLabel.height,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SymptomChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}

String _severityDescription(int severity) {
  return switch (severity) {
    1 => 'Very mild',
    2 => 'Mild',
    3 => 'Moderate',
    4 => 'Strong',
    5 => 'Severe',
    _ => '',
  };
}

String _formatDate(DateTime date) {
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

String _shortDate(DateTime date) {
  return '${date.month}/${date.day}';
}

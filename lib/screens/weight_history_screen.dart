import 'package:flutter/material.dart';

import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../theme/app_theme.dart';
import 'premium_screen.dart';

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
  const WeightHistoryScreen({required this.dataService, super.key});

  final AppDataService dataService;

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  List<WeightRecord> _records = [];

  WeightChartRange _selectedRange = WeightChartRange.oneMonth;

  bool _isLoading = true;
  bool _didChangeData = false;

  bool get _hasPremium => widget.dataService.hasPremium;

  @override
  void initState() {
    super.initState();
    _loadRecords();
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
    final weight = await showDialog<double>(
      context: context,
      builder: (_) => _WeightEntryDialog(
        initialWeight: _records.isEmpty ? null : _records.first.weight,
        isFirstEntry: _records.isEmpty,
      ),
    );

    if (weight == null || !mounted) {
      return;
    }

    final now = DateTime.now();

    final existingRecord = await widget.dataService.getWeightRecordForDate(now);

    final record = WeightRecord(
      id: existingRecord?.id ?? now.microsecondsSinceEpoch.toString(),
      weight: weight,
      recordedAt: now,
    );

    await widget.dataService.saveWeightRecord(record);

    if (!mounted) {
      return;
    }

    _didChangeData = true;

    await _loadRecords();
  }

  Future<void> _deleteRecord(WeightRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete weight entry?'),
          content: Text(
            'Delete ${record.weight.toStringAsFixed(1)} lb from '
            '${_formatFullDate(record.recordedAt)}?',
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
    if (_records.isEmpty) {
      return null;
    }

    return _records.last.weight;
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

    if (value == 0) {
      return '0.0 lb';
    }

    final prefix = value > 0 ? '+' : '';

    return '$prefix${value.toStringAsFixed(1)} lb';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        110,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              Text(
                'Current weight',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${currentWeight.toStringAsFixed(1)} lb',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasLostWeight
                        ? Icons.south_east
                        : totalChange > 0
                        ? Icons.north_east
                        : Icons.horizontal_rule,
                    size: 18,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    totalChange == 0
                        ? 'No change since start'
                        : '${totalChange.abs().toStringAsFixed(1)} lb '
                              '${hasLostWeight ? 'lost' : 'gained'} '
                              'since start',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Started at '
                '${startingWeight.toStringAsFixed(1)} lb',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        if (_hasPremium)
          _buildAnalytics(context)
        else
          _PremiumAnalyticsCard(onTap: _openPremium),

        const SizedBox(height: AppSpacing.lg),

        _buildChart(context),

        const SizedBox(height: AppSpacing.lg),

        Row(
          children: [
            const Expanded(
              child: Text(
                'History',
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${_records.length} entries',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
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
              onDelete: () => _deleteRecord(record),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalytics(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: '7-day change',
                value: _formatChange(_changeSinceDays(7)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: '30-day change',
                value: _formatChange(_changeSinceDays(30)),
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
                value: '${_lowestWeight!.toStringAsFixed(1)} lb',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'Highest',
                value: '${_highestWeight!.toStringAsFixed(1)} lb',
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
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weight trend',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!_hasPremium)
                InkWell(
                  onTap: _openPremium,
                  borderRadius: BorderRadius.circular(999),
                  child: const _PremiumBadge(),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (_hasPremium)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final range in WeightChartRange.values) ...[
                    ChoiceChip(
                      label: Text(range.label),
                      selected: _selectedRange == range,
                      onSelected: (_) {
                        setState(() {
                          _selectedRange = range;
                        });
                      },
                    ),
                    if (range != WeightChartRange.values.last)
                      const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openPremium,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Upgrade to unlock date ranges and '
                      'detailed weight analytics.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.chevron_right, size: 20, color: colors.primary),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          SizedBox(
            height: 230,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeightChartPainter(
                records: visibleRecords,
                lineColor: colors.primary,
                fillColor: colors.primary.withValues(alpha: 0.12),
                guideColor: colors.outlineVariant,
                labelColor: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(Icons.insights_outlined, color: colors.primary),
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
                            'Advanced analytics',
                            style: TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _PremiumBadge(),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Unlock weekly changes, monthly trends, '
                      'records, projections, and advanced '
                      'chart ranges.',
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
    required this.onDelete,
  });

  final WeightRecord record;
  final String dateLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
            '${record.weight.toStringAsFixed(1)} lb',
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_weight_outlined, size: 56),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No weight entries',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Log your first weight to begin '
              'tracking progress.',
              textAlign: TextAlign.center,
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
    );
  }
}

class _WeightEntryDialog extends StatefulWidget {
  const _WeightEntryDialog({
    required this.initialWeight,
    required this.isFirstEntry,
  });

  final double? initialWeight;
  final bool isFirstEntry;

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
        decoration: const InputDecoration(
          labelText: 'Weight',
          suffixText: 'lb',
          hintText: '350.0',
          border: OutlineInputBorder(),
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
  }) : records = List<WeightRecord>.from(records)
         ..sort(
           (first, second) => first.recordedAt.compareTo(second.recordedAt),
         );

  final List<WeightRecord> records;

  final Color lineColor;
  final Color fillColor;
  final Color guideColor;
  final Color labelColor;

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

      final labelPainter = TextPainter(
        text: TextSpan(
          text: weight.toStringAsFixed(1),
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
    if (lineColor != oldDelegate.lineColor ||
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

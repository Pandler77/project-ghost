import 'package:flutter/material.dart';

import '../models/measurement_system.dart';
import '../models/weight_record.dart';
import '../theme/app_theme.dart';
import '../utils/weight_display.dart';

class WeightCard extends StatelessWidget {
  const WeightCard({
    required this.currentWeight,
    required this.startingWeight,
    required this.weightRecords,
    required this.measurementSystem,
    required this.onLogWeight,
    required this.onOpenHistory,
    super.key,
  });

  final double currentWeight;
  final double startingWeight;
  final List<WeightRecord> weightRecords;
  final MeasurementSystem measurementSystem;
  final VoidCallback onLogWeight;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final displayedCurrentWeight = WeightDisplay.displayValue(
      currentWeight,
      measurementSystem,
    );

    final displayedStartingWeight = WeightDisplay.displayValue(
      startingWeight,
      measurementSystem,
    );

    final weightChange = currentWeight - startingWeight;

    final displayedWeightChange = WeightDisplay.displayValue(
      weightChange.abs(),
      measurementSystem,
    );

    final hasLostWeight = weightChange < 0;
    final hasGainedWeight = weightChange > 0;

    final unit = WeightDisplay.unit(measurementSystem);

    final trendIcon = hasLostWeight
        ? Icons.south_east
        : hasGainedWeight
        ? Icons.north_east
        : Icons.horizontal_rule;

    final changeText = hasLostWeight
        ? '${displayedWeightChange.toStringAsFixed(1)} $unit lost'
        : hasGainedWeight
        ? '${displayedWeightChange.toStringAsFixed(1)} $unit gained'
        : 'No change';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.45),
              width: 1.35,
            ),
          ),
          child: InkWell(
            onTap: onOpenHistory,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            maxLines: 1,
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: displayedCurrentWeight.toStringAsFixed(
                                    1,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' $unit',
                                  style: TextStyle(
                                    fontSize: AppTypography.body,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colorScheme.primary.withValues(alpha: 0.45),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        Row(
                          children: [
                            Icon(
                              trendIcon,
                              size: 17,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                changeText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTypography.caption,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Starting Weight: '
                            '${displayedStartingWeight.toStringAsFixed(1)} '
                            '$unit',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 72,
                      child: CustomPaint(
                        painter: _WeightTrendPainter(
                          records: weightRecords,
                          lineColor: colorScheme.primary,
                          guideColor: colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xs),

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
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  _WeightTrendPainter({
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

    final guidePaint = Paint()
      ..color = guideColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      guidePaint,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    const horizontalPadding = 5.0;
    const verticalPadding = 8.0;

    final graphWidth = size.width - (horizontalPadding * 2);

    final graphHeight = size.height - (verticalPadding * 2);

    if (records.length == 1) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, pointPaint);

      return;
    }

    final weights = records.map((record) => record.weight).toList();

    final minimumWeight = weights.reduce(
      (first, second) => first < second ? first : second,
    );

    final maximumWeight = weights.reduce(
      (first, second) => first > second ? first : second,
    );

    final range = maximumWeight - minimumWeight;

    final points = <Offset>[];

    for (var index = 0; index < records.length; index++) {
      final x = horizontalPadding + graphWidth * (index / (records.length - 1));

      final normalizedWeight = range == 0
          ? 0.5
          : (records[index].weight - minimumWeight) / range;

      final y = verticalPadding + graphHeight * (1 - normalizedWeight);

      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }

    canvas.drawPath(path, linePaint);

    canvas.drawCircle(points.last, 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) {
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

import 'package:flutter/material.dart';

import '../models/weight_record.dart';
import '../theme/app_theme.dart';

class WeightCard extends StatelessWidget {
  const WeightCard({
    required this.currentWeight,
    required this.startingWeight,
    required this.weightRecords,
    required this.onLogWeight,
    super.key,
  });

  final double currentWeight;
  final double startingWeight;
  final List<WeightRecord> weightRecords;
  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    final weightChange = currentWeight - startingWeight;
    final hasLostWeight = weightChange < 0;
    final hasGainedWeight = weightChange > 0;
    final changeAmount = weightChange.abs();

    final trendIcon = hasLostWeight
        ? Icons.trending_down
        : hasGainedWeight
        ? Icons.trending_up
        : Icons.trending_flat;

    final changeText = hasLostWeight
        ? '${changeAmount.toStringAsFixed(1)} lb lost'
        : hasGainedWeight
        ? '${changeAmount.toStringAsFixed(1)} lb gained'
        : 'No weight change';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Weight',
                    style: TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(onPressed: onLogWeight, child: const Text('Log')),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: currentWeight.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' lb',
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  trendIcon,
                  size: AppIcon.sm,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  changeText,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightTrendPainter(
                  records: weightRecords,
                  lineColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  _WeightTrendPainter({
    required List<WeightRecord> records,
    required this.lineColor,
  }) : records = List<WeightRecord>.from(records)
         ..sort(
           (first, second) => first.recordedAt.compareTo(second.recordedAt),
         );

  final List<WeightRecord> records;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) {
      return;
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

    const horizontalPadding = 4.0;
    const verticalPadding = 6.0;

    final graphWidth = size.width - (horizontalPadding * 2);

    final graphHeight = size.height - (verticalPadding * 2);

    if (records.length == 1) {
      final point = Offset(size.width / 2, size.height / 2);

      canvas.drawCircle(point, 4, pointPaint);

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
    if (lineColor != oldDelegate.lineColor) {
      return true;
    }

    if (records.length != oldDelegate.records.length) {
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

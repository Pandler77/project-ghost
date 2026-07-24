import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WeightCard extends StatelessWidget {
  const WeightCard({
    required this.currentWeight,
    required this.startingWeight,
    required this.onLogWeight,
    super.key,
  });

  final double currentWeight;
  final double startingWeight;
  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    final weightChange = currentWeight - startingWeight;
    final hasLostWeight = weightChange < 0;
    final changeAmount = weightChange.abs();

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
                      fontSize: 28,
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
                  hasLostWeight ? Icons.trending_down : Icons.trending_up,
                  size: AppIcon.sm,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  hasLostWeight
                      ? '${changeAmount.toStringAsFixed(1)} lb lost'
                      : '${changeAmount.toStringAsFixed(1)} lb gained',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            const SizedBox(
              height: 48,
              width: double.infinity,
              child: CustomPaint(painter: _WeightTrendPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  const _WeightTrendPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * .18)
      ..quadraticBezierTo(
        size.width * .15,
        size.height * .28,
        size.width * .30,
        size.height * .24,
      )
      ..quadraticBezierTo(
        size.width * .45,
        size.height * .42,
        size.width * .60,
        size.height * .46,
      )
      ..quadraticBezierTo(
        size.width * .80,
        size.height * .72,
        size.width,
        size.height * .80,
      );

    canvas.drawPath(path, linePaint);

    canvas.drawCircle(Offset(size.width, size.height * .80), 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Weight',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: onLogWeight,
                  icon: const Icon(Icons.add),
                  label: const Text('Log Weight'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${currentWeight.toStringAsFixed(1)} lb',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  hasLostWeight ? Icons.trending_down : Icons.trending_up,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  hasLostWeight
                      ? '${changeAmount.toStringAsFixed(1)} lb lost'
                      : '${changeAmount.toStringAsFixed(1)} lb gained',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SizedBox(
              height: 90,
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
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.18)
      ..lineTo(size.width * 0.18, size.height * 0.28)
      ..lineTo(size.width * 0.35, size.height * 0.25)
      ..lineTo(size.width * 0.52, size.height * 0.48)
      ..lineTo(size.width * 0.68, size.height * 0.45)
      ..lineTo(size.width * 0.84, size.height * 0.72)
      ..lineTo(size.width, size.height * 0.82);

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_WeightTrendPainter oldDelegate) => false;
}

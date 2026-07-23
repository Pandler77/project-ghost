import 'package:flutter/material.dart';

import '../models/dose.dart';

class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({required this.doses, super.key});

  final List<Dose> doses;

  @override
  Widget build(BuildContext context) {
    final completedCount = doses.where((dose) => dose.isCompleted).length;

    final remainingCount = doses.length - completedCount;

    final summaryText = remainingCount == 0
        ? 'All Complete'
        : '$remainingCount ';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              remainingCount == 0
                  ? '✓ All Complete'
                  : '$completedCount of ${doses.length} Completed',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: doses.isEmpty ? 0 : completedCount / doses.length,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/dose.dart';

class DoseCard extends StatelessWidget {
  const DoseCard({
    required this.dose,
    required this.onPressed,
    super.key,
  });

  final Dose dose;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dose.protocolName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${dose.amount} • ${_formatScheduledTime()}',
            ),
            const SizedBox(height: 12),
            if (!dose.isCompleted)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  child: const Text('Mark Complete'),
                ),
              )
            else
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completed at ${_formatTime(dose.completedAt!)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onPressed,
                    child: const Text('Undo'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatScheduledTime() {
    return _formatTime(dose.scheduledFor);
  }
}
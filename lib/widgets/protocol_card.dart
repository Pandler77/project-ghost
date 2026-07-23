import 'package:flutter/material.dart';

import '../models/protocol.dart';

class ProtocolCard extends StatelessWidget {
  const ProtocolCard({
    required this.protocol,
    required this.isTaken,
    required this.onPressed,
    super.key,
  });

  final Protocol protocol;
  final bool isTaken;
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
              protocol.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${protocol.dose} • ${_formatScheduleTime()}',
            ),
            const SizedBox(height: 12),
            if (!isTaken)
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
                      'Completed at ${_formatTime(protocol.completedAt!)}',
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

  String _formatScheduleTime() {
    final hour = protocol.schedule.hour;

    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;

    final minute = protocol.schedule.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:$minute $period';
  }
}
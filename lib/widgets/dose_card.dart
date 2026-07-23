import 'package:flutter/material.dart';

import '../models/dose.dart';

class DoseCard extends StatelessWidget {
  const DoseCard({required this.dose, required this.onPressed, super.key});

  final Dose dose;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: dose.isCompleted
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    dose.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: dose.isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                          dose.isCompleted
                              ? 'Completed at ${_formatTime(dose.completedAt!)}'
                              : '${dose.amount} • ${_formatScheduledTime()}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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

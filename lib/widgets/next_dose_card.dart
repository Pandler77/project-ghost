import 'package:flutter/material.dart';

import '../models/dose.dart';

class NextDoseCard extends StatelessWidget {
  const NextDoseCard({required this.dose, super.key});

  final Dose? dose;

  @override
  Widget build(BuildContext context) {
    if (dose == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Next Dose',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _formatTime(dose!.scheduledFor),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              _formatRelativeTime(dose!.scheduledFor),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              dose!.protocolName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            Text(
              dose!.amount,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRelativeTime(DateTime scheduledFor) {
    final now = DateTime.now();
    final difference = scheduledFor.difference(now);

    final today = DateTime(now.year, now.month, now.day);

    final scheduledDay = DateTime(
      scheduledFor.year,
      scheduledFor.month,
      scheduledFor.day,
    );

    final dayDifference = scheduledDay.difference(today).inDays;

    if (difference.inMinutes <= 1 && difference.inMinutes >= 0) {
      return 'Due now';
    }

    if (dayDifference == 0) {
      if (difference.inMinutes < 60) {
        return 'Due in ${difference.inMinutes} min';
      }

      final hours = difference.inHours;

      return hours == 1 ? 'Due in 1 hour' : 'Due in $hours hours';
    }

    if (dayDifference == 1) {
      return 'Tomorrow';
    }

    if (dayDifference < 7) {
      return _weekdayName(scheduledFor.weekday);
    }

    return '${scheduledFor.month}/${scheduledFor.day}/${scheduledFor.year}';
  }

  static String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

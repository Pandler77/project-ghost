import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';

class WeeklyPreviewCard extends StatelessWidget {
  const WeeklyPreviewCard({
    required this.protocols,
    required this.onDayTapped,
    super.key,
  });

  final List<Protocol> protocols;
  final ValueChanged<DateTime> onDayTapped;

  static const _scheduleService = ProtocolScheduleService();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final week = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day + index),
    );

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
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            for (final day in week)
              _WeeklyRow(
                date: day,
                protocols: _scheduleService.protocolsForDate(protocols, day),
                onTap: () => onDayTapped(day),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyRow extends StatelessWidget {
  const _WeeklyRow({
    required this.date,
    required this.protocols,
    required this.onTap,
  });

  final DateTime date;
  final List<Protocol> protocols;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleProtocols = protocols.take(3).toList();
    final remainingCount = protocols.length - visibleProtocols.length;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weekdayLabel(date),
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: _isToday(date)
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: _isToday(date)
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: protocols.isEmpty
                  ? Text(
                      'Nothing scheduled',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Row(
                      children: [
                        for (final protocol in visibleProtocols)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: Color(protocol.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (remainingCount > 0)
                          Text(
                            '+$remainingCount',
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right, size: AppIcon.sm),
          ],
        ),
      ),
    );
  }
}

String _weekdayLabel(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  if (_isToday(date)) {
    return 'Today';
  }

  return weekdays[date.weekday - 1];
}

bool _isToday(DateTime date) {
  final now = DateTime.now();

  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

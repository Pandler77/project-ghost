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
    final upcomingItems = _buildUpcomingItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UPCOMING',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (upcomingItems.isEmpty)
          _EmptyUpcomingState()
        else
          for (var index = 0; index < upcomingItems.length; index++) ...[
            _UpcomingDoseRow(
              item: upcomingItems[index],
              onTap: () {
                onDayTapped(upcomingItems[index].scheduledFor);
              },
            ),
            if (index < upcomingItems.length - 1)
              const Divider(height: AppSpacing.lg),
          ],
      ],
    );
  }

  List<_UpcomingDoseItem> _buildUpcomingItems() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);

    final items = <_UpcomingDoseItem>[];

    for (var dayOffset = 1; dayOffset <= 60; dayOffset++) {
      final date = startDate.add(Duration(days: dayOffset));

      final scheduledProtocols = _scheduleService.protocolsForDate(
        protocols,
        date,
      );

      for (final protocol in scheduledProtocols) {
        items.add(
          _UpcomingDoseItem(
            protocol: protocol,
            scheduledFor: _scheduleService.scheduledDateTime(protocol, date),
          ),
        );

        if (items.length == 5) {
          return items;
        }
      }
    }

    return items;
  }
}

class _UpcomingDoseRow extends StatelessWidget {
  const _UpcomingDoseRow({required this.item, required this.onTap});

  final _UpcomingDoseItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final protocolColor = Color(item.protocol.colorValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 48,
                decoration: BoxDecoration(
                  color: protocolColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateLabel(item.scheduledFor),
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.protocol.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.protocol.dose}  •  '
                      '${_formatTime(item.scheduledFor)}',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyUpcomingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        'Nothing scheduled in the next 60 days.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _UpcomingDoseItem {
  const _UpcomingDoseItem({required this.protocol, required this.scheduledFor});

  final Protocol protocol;
  final DateTime scheduledFor;
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final target = DateTime(date.year, date.month, date.day);

  final difference = target.difference(today).inDays;

  if (difference == 1) {
    return 'Tomorrow';
  }

  if (difference < 7) {
    return _weekdayName(date.weekday);
  }

  return '${_monthName(date.month)} ${date.day}';
}

String _weekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return weekdays[weekday - 1];
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}

String _formatTime(DateTime time) {
  final displayHour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;

  final formattedMinute = time.minute.toString().padLeft(2, '0');

  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$displayHour:$formattedMinute $period';
}

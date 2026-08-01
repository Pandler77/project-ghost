import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';

class UpcomingCarousel extends StatefulWidget {
  const UpcomingCarousel({
    required this.protocols,
    required this.onDayTapped,
    super.key,
  });

  final List<Protocol> protocols;
  final ValueChanged<DateTime> onDayTapped;

  @override
  State<UpcomingCarousel> createState() => _UpcomingCarouselState();
}

class _UpcomingCarouselState extends State<UpcomingCarousel> {
  static const ProtocolScheduleService _scheduleService =
      ProtocolScheduleService();

  late final PageController _pageController;

  int _selectedPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_UpcomingDay> _buildUpcomingDays() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final upcomingDays = <_UpcomingDay>[];

    for (var dayOffset = 1; dayOffset <= 90; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));

      final protocols = _scheduleService.protocolsForDate(
        widget.protocols,
        date,
      );

      if (protocols.isEmpty) {
        continue;
      }

      upcomingDays.add(_UpcomingDay(date: date, protocols: protocols));

      if (upcomingDays.length == 5) {
        break;
      }
    }

    return upcomingDays;
  }

  @override
  Widget build(BuildContext context) {
    final upcomingDays = _buildUpcomingDays();

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

        if (upcomingDays.isEmpty)
          const _EmptyUpcomingState()
        else ...[
          SizedBox(
            height: 172,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: upcomingDays.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedPage = index;
                });
              },
              itemBuilder: (context, index) {
                final day = upcomingDays[index];

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == upcomingDays.length - 1 ? 0 : AppSpacing.sm,
                  ),
                  child: _UpcomingDayCard(
                    day: day,
                    onTap: () {
                      widget.onDayTapped(day.date);
                    },
                  ),
                );
              },
            ),
          ),

          if (upcomingDays.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < upcomingDays.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _selectedPage ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _selectedPage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _UpcomingDayCard extends StatelessWidget {
  const _UpcomingDayCard({required this.day, required this.onTap});

  final _UpcomingDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final visibleProtocols = day.protocols.take(3).toList();

    final remainingCount = day.protocols.length - visibleProtocols.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dateLabel(day.date),
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${day.protocols.length}',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                Expanded(
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < visibleProtocols.length;
                        index++
                      ) ...[
                        _ProtocolPreviewRow(
                          protocol: visibleProtocols[index],
                          date: day.date,
                        ),
                        if (index < visibleProtocols.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),

                if (remainingCount > 0)
                  Text(
                    '+$remainingCount more',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProtocolPreviewRow extends StatelessWidget {
  const _ProtocolPreviewRow({required this.protocol, required this.date});

  final Protocol protocol;
  final DateTime date;

  static const ProtocolScheduleService _scheduleService =
      ProtocolScheduleService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final scheduledFor = _scheduleService.scheduledDateTime(protocol, date);

    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: Color(protocol.colorValue),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                protocol.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${protocol.dose} • '
                '${_formatTime(scheduledFor)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyUpcomingState extends StatelessWidget {
  const _EmptyUpcomingState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Nothing scheduled in the next 90 days.',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _UpcomingDay {
  const _UpcomingDay({required this.date, required this.protocols});

  final DateTime date;
  final List<Protocol> protocols;
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final difference = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(today).inDays;

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
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;

  final minute = time.minute.toString().padLeft(2, '0');

  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}

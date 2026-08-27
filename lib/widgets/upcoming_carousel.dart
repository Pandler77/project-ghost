import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../models/schedule_override.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';

class UpcomingCarousel extends StatefulWidget {
  const UpcomingCarousel({
    required this.protocols,
    required this.overrides,
    required this.onDayTapped,
    super.key,
  });

  final List<Protocol> protocols;
  final List<ScheduleOverride> overrides;
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

      final occurrences = _scheduleService.occurrencesForDate(
        widget.protocols,
        date,
        overrides: widget.overrides,
      );

      if (occurrences.isEmpty) {
        continue;
      }

      final protocolById = <String, Protocol>{
        for (final protocol in widget.protocols) protocol.id: protocol,
      };

      final entries = occurrences
          .map((occurrence) {
            final protocol = protocolById[occurrence.protocolId];

            if (protocol == null) {
              return null;
            }

            return _UpcomingOccurrence(
              protocol: protocol,
              scheduledFor: occurrence.scheduledFor,
            );
          })
          .whereType<_UpcomingOccurrence>()
          .toList();

      if (entries.isEmpty) {
        continue;
      }

      upcomingDays.add(_UpcomingDay(date: date, occurrences: entries));

      if (upcomingDays.length == 5) {
        break;
      }
    }

    return upcomingDays;
  }

  @override
  Widget build(BuildContext context) {
    final upcomingDays = _buildUpcomingDays();

    if (_selectedPage >= upcomingDays.length && upcomingDays.isNotEmpty) {
      _selectedPage = upcomingDays.length - 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (upcomingDays.isEmpty)
          const _EmptyUpcomingState()
        else ...[
          SizedBox(
            height: 190,
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
    final visibleOccurrences = day.occurrences.take(2).toList();
    final remainingCount = day.occurrences.length - visibleOccurrences.length;

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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        '${day.occurrences.length}',
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
                for (
                  var index = 0;
                  index < visibleOccurrences.length;
                  index++
                ) ...[
                  _ProtocolPreviewRow(
                    occurrence: visibleOccurrences[index],
                  ),
                  if (index < visibleOccurrences.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
                if (remainingCount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '+$remainingCount more',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProtocolPreviewRow extends StatelessWidget {
  const _ProtocolPreviewRow({required this.occurrence});

  final _UpcomingOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocol = occurrence.protocol;

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 26,
            decoration: BoxDecoration(
              color: Color(protocol.colorValue),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              protocol.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${protocol.dose} • ${_formatTime(occurrence.scheduledFor)}',
            maxLines: 1,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
  const _UpcomingDay({
    required this.date,
    required this.occurrences,
  });

  final DateTime date;
  final List<_UpcomingOccurrence> occurrences;
}

class _UpcomingOccurrence {
  const _UpcomingOccurrence({
    required this.protocol,
    required this.scheduledFor,
  });

  final Protocol protocol;
  final DateTime scheduledFor;
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

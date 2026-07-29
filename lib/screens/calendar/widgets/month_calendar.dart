import 'package:flutter/material.dart';

import '../../../models/calendar_day_summary.dart';
import '../../../theme/app_theme.dart';
import '../calendar_helpers.dart';
import 'calendar_day.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.displayedMonth,
    required this.selectedDate,
    required this.summaryForDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onMonthPressed,
    required this.onDateSelected,
    super.key,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;

  final CalendarDaySummary Function(DateTime date) summaryForDate;

  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onMonthPressed;
  final ValueChanged<DateTime> onDateSelected;

  List<DateTime?> _buildCalendarCells() {
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);

    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;

    final leadingEmptyCells = firstDay.weekday - 1;

    return List<DateTime?>.generate(42, (index) {
      final dayNumber = index - leadingEmptyCells + 1;

      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return null;
      }

      return DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cells = _buildCalendarCells();

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.button),
                onTap: onMonthPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formatMonthYear(displayedMonth),
                        style: const TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Row(
          children: [
            _WeekdayLabel('M'),
            _WeekdayLabel('T'),
            _WeekdayLabel('W'),
            _WeekdayLabel('T'),
            _WeekdayLabel('F'),
            _WeekdayLabel('S'),
            _WeekdayLabel('S'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rowHeight = constraints.maxHeight / 6;

              return Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  for (var week = 0; week < 6; week++)
                    TableRow(
                      children: [
                        for (var day = 0; day < 7; day++)
                          SizedBox(
                            height: rowHeight,
                            child: Builder(
                              builder: (context) {
                                final date = cells[(week * 7) + day];

                                if (date == null) {
                                  return const SizedBox.shrink();
                                }

                                return CalendarDay(
                                  summary: summaryForDate(date),
                                  isSelected: isSameDay(date, selectedDate),
                                  isToday: isSameDay(date, DateTime.now()),
                                  onTap: () {
                                    onDateSelected(date);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

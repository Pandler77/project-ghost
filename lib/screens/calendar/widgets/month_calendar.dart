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
    required this.onDateSelected,
    super.key,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;

  final CalendarDaySummary Function(DateTime date) summaryForDate;
  final ValueChanged<DateTime> onDateSelected;

  List<DateTime> _buildCalendarCells() {
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final lastDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    );

    final leadingDays = firstDayOfMonth.weekday % 7;

    final trailingDays = (6 - (lastDayOfMonth.weekday % 7));

    final firstVisibleDate = firstDayOfMonth.subtract(
      Duration(days: leadingDays),
    );

    final totalCells = leadingDays + lastDayOfMonth.day + trailingDays;

    return List<DateTime>.generate(
      totalCells,
      (index) => firstVisibleDate.add(Duration(days: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cells = _buildCalendarCells();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              formatMonthYear(displayedMonth),
              style: const TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          const Row(
            children: [
              _WeekdayLabel('S'),
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              mainAxisExtent: 74,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];

              final isOutsideMonth =
                  date.month != displayedMonth.month ||
                  date.year != displayedMonth.year;

              return CalendarDay(
                summary: summaryForDate(date),
                isSelected: isSameDay(date, selectedDate),
                isToday: isSameDay(date, DateTime.now()),
                isOutsideMonth: isOutsideMonth,
                onTap: () {
                  onDateSelected(date);
                },
              );
            },
          ),
        ],
      ),
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

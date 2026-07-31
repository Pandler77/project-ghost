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

    final leadingDays = firstDayOfMonth.weekday - DateTime.monday;

    final trailingDays = DateTime.sunday - lastDayOfMonth.weekday;

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
              const columns = 7;
              const spacing = 5.0;

              final rowCount = (cells.length / columns).ceil();

              final cellWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              final cellHeight =
                  (constraints.maxHeight - (spacing * (rowCount - 1))) /
                  rowCount;

              final aspectRatio = cellWidth / cellHeight;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                itemCount: cells.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
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

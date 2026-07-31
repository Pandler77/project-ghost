import 'package:flutter/material.dart';

import '../../../models/calendar_day_summary.dart';
import '../../../theme/app_theme.dart';

class CalendarDay extends StatelessWidget {
  const CalendarDay({
    required this.summary,
    required this.isSelected,
    required this.isToday,
    required this.isOutsideMonth,
    required this.onTap,
    super.key,
  });

  final CalendarDaySummary summary;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;
  final VoidCallback onTap;

  static const Color _completionColor = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final visibleProtocols = summary.protocols.take(3).toList();
    final remainingCount = summary.protocols.length - visibleProtocols.length;

    final completionOpacity = switch (summary.completionRatio) {
      <= 0 => 0.0,
      < 1 => 0.14,
      _ => 0.32,
    };

    final backgroundColor = completionOpacity > 0
        ? _completionColor.withValues(alpha: completionOpacity)
        : colorScheme.surface;

    final normalBorder = colorScheme.outline.withValues(alpha: 0.55);

    final borderColor = isSelected
        ? colorScheme.primary
        : isToday
        ? colorScheme.primary.withValues(alpha: 0.75)
        : normalBorder;

    final borderWidth = isSelected
        ? 2.0
        : isToday
        ? 1.5
        : 1.0;

    return Opacity(
      opacity: isOutsideMonth ? 0.38 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: isSelected ? 0.12 : 0.05,
                  ),
                  blurRadius: isSelected ? 6 : 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? colorScheme.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${summary.date.day}',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isToday
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: [
                      for (final protocol in visibleProtocols)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(protocol.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (remainingCount > 0)
                        Text(
                          '+$remainingCount',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../models/calendar_day_summary.dart';
import '../../../theme/app_theme.dart';

class CalendarDay extends StatelessWidget {
  const CalendarDay({
    required this.summary,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    super.key,
  });

  final CalendarDaySummary summary;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  static const Color _completionColor = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final visibleProtocols = summary.protocols.take(2).toList();

    final remainingCount = summary.protocols.length - visibleProtocols.length;

    final completionOpacity = switch (summary.completionRatio) {
      <= 0 => 0.0,
      < 1 => 0.16,
      _ => 0.38,
    };

    final backgroundColor = completionOpacity > 0
        ? _completionColor.withValues(alpha: completionOpacity)
        : Colors.transparent;

    final borderColor = isSelected
        ? colorScheme.primary
        : isToday
        ? colorScheme.primary.withValues(alpha: 0.65)
        : Colors.transparent;

    final borderWidth = isSelected
        ? 2.0
        : isToday
        ? 1.25
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: borderWidth == 0
                  ? null
                  : Border.all(color: borderColor, width: borderWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              child: Column(
                children: [
                  Text(
                    '${summary.date.day}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final protocol in visibleProtocols)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Color(protocol.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (remainingCount > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '+$remainingCount',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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

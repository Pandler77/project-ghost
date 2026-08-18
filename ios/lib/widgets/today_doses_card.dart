import 'package:flutter/material.dart';

import '../models/cycle_status.dart';
import '../models/display_preferences.dart';
import '../models/dose.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class TodayDosesCard extends StatefulWidget {
  const TodayDosesCard({
    required this.doses,
    required this.onDosePressed,
    required this.displayPreferences,
    super.key,
  });

  final List<Dose> doses;
  final Future<void> Function(Dose dose) onDosePressed;
  final DisplayPreferences displayPreferences;

  @override
  State<TodayDosesCard> createState() => _TodayDosesCardState();
}

class _TodayDosesCardState extends State<TodayDosesCard> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final resolvedDoses = widget.doses
        .where((dose) => dose.isResolved)
        .toList();

    final pendingDoses = widget.doses
        .where((dose) => !dose.isResolved)
        .toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.doses.isEmpty)
            const _EmptyTodayState()
          else ...[
            for (var index = 0; index < pendingDoses.length; index++) ...[
              _PendingDoseRow(
                key: ValueKey(
                  '${pendingDoses[index].protocolId}-'
                  '${pendingDoses[index].scheduledFor.microsecondsSinceEpoch}',
                ),
                dose: pendingDoses[index],
                displayPreferences: widget.displayPreferences,
                onPressed: () async {
                  await widget.onDosePressed(pendingDoses[index]);
                },
              ),
              if (index < pendingDoses.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],

            if (resolvedDoses.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),

              _CompletedHeader(
                count: resolvedDoses.length,
                isExpanded: _showCompleted,
                onPressed: () {
                  setState(() {
                    _showCompleted = !_showCompleted;
                  });
                },
              ),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _showCompleted
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    for (
                      var index = 0;
                      index < resolvedDoses.length;
                      index++
                    ) ...[
                      _CompletedDoseRow(
                        dose: resolvedDoses[index],
                        onPressed: () async {
                          await widget.onDosePressed(resolvedDoses[index]);
                        },
                      ),
                      if (index < resolvedDoses.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyTodayState extends StatelessWidget {
  const _EmptyTodayState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        'Nothing is scheduled for today.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _PendingDoseRow extends StatefulWidget {
  const _PendingDoseRow({
    required this.dose,
    required this.onPressed,
    required this.displayPreferences,
    super.key,
  });

  final Dose dose;
  final Future<void> Function() onPressed;
  final DisplayPreferences displayPreferences;

  @override
  State<_PendingDoseRow> createState() => _PendingDoseRowState();
}

class _PendingDoseRowState extends State<_PendingDoseRow> {
  bool _isCompleting = false;

  Future<void> _markTaken() async {
    if (_isCompleting) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(widget.dose.protocolColorValue);
    final cycleStatus = widget.dose.cycleStatus;

    final cyclePrimary = _cyclePrimaryText(
      cycleStatus,
      widget.displayPreferences,
    );

    final cycleSecondary = _cycleSecondaryText(
      cycleStatus,
      widget.displayPreferences,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: protocolColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: protocolColor.withValues(alpha: 0.45),
          width: 1.25,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dose.protocolName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.dose.amount} • '
                  '${_formatTime(widget.dose.scheduledFor)}',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (cyclePrimary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Cycle: $cyclePrimary',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (cycleSecondary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      cycleSecondary,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _isCompleting
                ? SizedBox(
                    key: const ValueKey('dose-loading'),
                    width: 96,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: protocolColor.withValues(alpha: 0.75),
                        ),
                      ),
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : OutlinedButton(
                    key: const ValueKey('take-dose'),
                    onPressed: _markTaken,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: protocolColor.withValues(alpha: 0.75),
                      ),
                      minimumSize: const Size(96, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text(
                      'Take Dose',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({
    required this.count,
    required this.isExpanded,
    required this.onPressed,
  });

  final int count;
  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Completed ($count)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedDoseRow extends StatelessWidget {
  const _CompletedDoseRow({
    required this.dose,
    required this.onPressed,
  });

  final Dose dose;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(dose.protocolColorValue);

    final completionText = dose.isSkipped
        ? dose.completedAt == null
              ? 'Skipped'
              : 'Skipped at ${_formatTime(dose.completedAt!)}'
        : dose.completedAt == null
        ? 'Taken'
        : 'Taken at ${_formatTime(dose.completedAt!)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: protocolColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: protocolColor.withValues(alpha: 0.45),
          width: 1.25,
        ),
      ),
      child: Row(
        children: [
          Icon(
            dose.isSkipped ? Icons.remove_circle_outline : Icons.check_circle,
            color: protocolColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.protocolName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dose.amount} • $completionText',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (dose.hasInjectionSite) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            ArcticIcons.location_on_outlined,
                            size: 14,
                            color: protocolColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dose.injectionSiteLabel!,
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                fontWeight: FontWeight.w600,
                                color: protocolColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await onPressed();
            },
            child: const Text('Details'),
          ),
        ],
      ),
    );
  }
}

String _cyclePrimaryText(
  CycleStatus? status,
  DisplayPreferences preferences,
) {
  if (status == null || !status.isCycled || !preferences.showCycleStatus) {
    return '';
  }

  if (status.isBeforeStart) {
    return 'Starts soon';
  }

  if (status.phaseLabel == 'Cycle complete') {
    return 'Cycle complete';
  }

  if (!status.isActive) {
    return 'Off cycle';
  }

  final totalDays = status.totalDaysInCurrentPhase;
  final currentDay = status.dayInCurrentPhase;

  if (totalDays <= 0 || currentDay <= 0) {
    return 'On cycle';
  }

  if (totalDays >= 7) {
    final currentWeek = ((currentDay - 1) ~/ 7) + 1;
    final totalWeeks = (totalDays / 7).ceil();
    return 'Week $currentWeek of $totalWeeks';
  }

  return 'Day $currentDay of $totalDays';
}

String _cycleSecondaryText(
  CycleStatus? status,
  DisplayPreferences preferences,
) {
  if (status == null || !status.isCycled || !preferences.showCycleStatus) {
    return '';
  }

  final parts = <String>[];

  if (status.isBeforeStart) {
    final startDate = status.nextTransitionDate;

    if (startDate != null && preferences.showCycleResumeDate) {
      parts.add('Starts ${_formatCycleDate(startDate)}');
    }

    if (preferences.showCycleRemainingDays) {
      parts.add(_remainingCycleText(status.daysRemainingInCurrentPhase));
    }

    return parts.join(' • ');
  }

  if (status.phaseLabel == 'Cycle complete') {
    return 'This cycle has ended';
  }

  if (status.isActive) {
    final transitionDate = status.nextTransitionDate;

    if (transitionDate != null && preferences.showCycleEndDate) {
      final endDate = transitionDate.subtract(const Duration(days: 1));
      parts.add('Ends ${_formatCycleDate(endDate)}');
    }

    if (preferences.showCycleRemainingDays) {
      final remaining = status.daysRemainingInCurrentPhase;
      parts.add(
        remaining <= 0
            ? 'Last active day'
            : _remainingCycleText(remaining),
      );
    }

    return parts.join(' • ');
  }

  final resumeDate = status.nextTransitionDate;

  if (resumeDate != null && preferences.showCycleResumeDate) {
    parts.add('Resumes ${_formatCycleDate(resumeDate)}');
  }

  if (preferences.showCycleRemainingDays) {
    parts.add(_remainingCycleText(status.daysRemainingInCurrentPhase));
  }

  return parts.join(' • ');
}

String _remainingCycleText(int days) {
  if (days <= 0) {
    return 'Last Day';
  }

  return '$days ${days == 1 ? 'Day' : 'Days'} Remaining';
}

String _formatCycleDate(DateTime date) {
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

  return '${months[date.month - 1]} ${date.day}';
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

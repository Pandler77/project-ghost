import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../theme/app_theme.dart';

class TodayDosesCard extends StatefulWidget {
  const TodayDosesCard({
    required this.doses,
    required this.onDosePressed,
    super.key,
  });

  final List<Dose> doses;
  final void Function(Dose dose) onDosePressed;

  @override
  State<TodayDosesCard> createState() => _TodayDosesCardState();
}

class _TodayDosesCardState extends State<TodayDosesCard> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final completedDoses = widget.doses
        .where((dose) => dose.isCompleted)
        .toList();

    final pendingDoses = widget.doses
        .where((dose) => !dose.isCompleted)
        .toList();

    final completedCount = completedDoses.length;
    final totalCount = widget.doses.length;

    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            completedCount: completedCount,
            totalCount: totalCount,
          ),

          const SizedBox(height: AppSpacing.sm),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return LinearProgressIndicator(
                  value: animatedProgress,
                  minHeight: 5,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.md),

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
                onPressed: () {
                  final isLastPending = pendingDoses.length == 1;

                  widget.onDosePressed(pendingDoses[index]);

                  if (isLastPending) {
                    setState(() {
                      _showCompleted = false;
                    });
                  }
                },
              ),
              if (index < pendingDoses.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],

            if (pendingDoses.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              const _FinishedTodayBanner(),
            ],

            if (completedDoses.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),

              _CompletedHeader(
                count: completedDoses.length,
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
                      index < completedDoses.length;
                      index++
                    ) ...[
                      _CompletedDoseRow(
                        dose: completedDoses[index],
                        onRemove: () {
                          widget.onDosePressed(completedDoses[index]);
                        },
                      ),
                      if (index < completedDoses.length - 1)
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final remainingCount = totalCount - completedCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Text(
            'TODAY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Text(
          totalCount == 0
              ? 'Nothing due'
              : remainingCount == 0
              ? 'Complete'
              : '$remainingCount remaining',
          style: TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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

class _FinishedTodayBanner extends StatelessWidget {
  const _FinishedTodayBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Everything is complete for today.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDoseRow extends StatefulWidget {
  const _PendingDoseRow({
    required this.dose,
    required this.onPressed,
    super.key,
  });

  final Dose dose;
  final VoidCallback onPressed;

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

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) {
      return;
    }

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(widget.dose.protocolColorValue);

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
                if (widget.dose.hasCycleStatus) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Cycle: '
                    '${widget.dose.cyclePrimaryLabel!}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (widget.dose.cycleSecondaryLabel?.trim().isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.dose.cycleSecondaryLabel!,
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
                ? FilledButton.icon(
                    key: const ValueKey('taken-confirmed'),
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: protocolColor,
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size(92, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 19),
                    label: const Text('Taken'),
                  )
                : OutlinedButton(
                    key: const ValueKey('taken-pending'),
                    onPressed: _markTaken,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: protocolColor.withValues(alpha: 0.75),
                      ),
                      minimumSize: const Size(82, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text(
                      'Taken',
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
  const _CompletedDoseRow({required this.dose, required this.onRemove});

  final Dose dose;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(dose.protocolColorValue);

    final completionText = dose.completedAt == null
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
          Icon(Icons.check_circle, color: protocolColor),
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
                Text(
                  '${dose.amount} • $completionText',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRemove, child: const Text('Undo')),
        ],
      ),
    );
  }
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

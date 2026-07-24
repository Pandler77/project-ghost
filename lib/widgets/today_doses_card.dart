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

    final progress = widget.doses.isEmpty
        ? 0.0
        : completedCount / widget.doses.length;

    final allCompleted = widget.doses.isNotEmpty && pendingDoses.isEmpty;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Today\'s Doses',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$completedCount/${widget.doses.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: animatedProgress,
                      minHeight: 6,
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              if (widget.doses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('Nothing scheduled today.'),
                ),

              if (allCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: AppIcon.md,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Finished for today',
                          style: TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              for (var index = 0; index < pendingDoses.length; index++) ...[
                _PendingDoseRow(
                  dose: pendingDoses[index],
                  onPressed: () {
                    final isLastPendingDose = pendingDoses.length == 1;

                    widget.onDosePressed(pendingDoses[index]);

                    if (isLastPendingDose) {
                      setState(() {
                        _showCompleted = false;
                      });
                    }
                  },
                ),
                if (index < pendingDoses.length - 1)
                  const Divider(height: AppSpacing.lg),
              ],

              if (completedDoses.isNotEmpty) ...[
                if (pendingDoses.isNotEmpty)
                  const Divider(height: AppSpacing.lg),

                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  onTap: () {
                    setState(() {
                      _showCompleted = !_showCompleted;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _showCompleted
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showCompleted) ...[
                  const SizedBox(height: AppSpacing.xs),

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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingDoseRow extends StatelessWidget {
  const _PendingDoseRow({required this.dose, required this.onPressed});

  final Dose dose;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.radio_button_unchecked,
              color: Theme.of(context).colorScheme.outline,
              size: AppIcon.md,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.protocolName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${dose.amount} • ${_formatTime(dose.scheduledFor)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: AppTypography.caption,
                    ),
                  ),
                ],
              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: AppIcon.md,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.protocolName,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${dose.amount} • Taken',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: AppTypography.caption,
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

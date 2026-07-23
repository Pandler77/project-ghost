import 'package:flutter/material.dart';

import '../models/dose.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Today\'s Doses',
                      style: TextStyle(
                        fontSize: 22,
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

              const SizedBox(height: 10),

              // Progress bar
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: animatedProgress,
                      minHeight: 8,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Empty state
              if (widget.doses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nothing scheduled today.'),
                ),

              // Finished banner
              if (allCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        child: const Icon(Icons.check),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Finished for today',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text('All scheduled items are complete.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Pending doses
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
                if (index < pendingDoses.length - 1) const Divider(height: 24),
              ],
              // Completed section
              if (completedDoses.isNotEmpty) ...[
                if (pendingDoses.isNotEmpty) const Divider(height: 28),

                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _showCompleted = !_showCompleted;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 6),

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
                      const SizedBox(height: 10),
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
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.radio_button_unchecked,
              color: Theme.of(context).colorScheme.outline,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.protocolName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${dose.amount} • ${_formatTime(dose.scheduledFor)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.check, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.protocolName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dose.amount} • Taken',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRemove, child: const Text('Remove')),
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

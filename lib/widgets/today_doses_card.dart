import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/dose_unit.dart';
import '../models/protocol.dart';
import '../theme/app_theme.dart';

class TodayDosesCard extends StatefulWidget {
  const TodayDosesCard({
    required this.doses,
    required this.protocols,
    required this.onDosePressed,
    super.key,
  });

  final List<Dose> doses;
  final List<Protocol> protocols;
  final Future<void> Function(Dose dose) onDosePressed;

  @override
  State<TodayDosesCard> createState() => _TodayDosesCardState();
}

class _TodayDosesCardState extends State<TodayDosesCard> {
  bool _showCompleted = false;

  Protocol? _protocolForDose(Dose dose) {
    for (final protocol in widget.protocols) {
      if (protocol.id == dose.protocolId) {
        return protocol;
      }
    }

    return null;
  }

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
                protocol: _protocolForDose(pendingDoses[index]),
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PendingDoseRow extends StatefulWidget {
  const _PendingDoseRow({
    required this.dose,
    required this.protocol,
    required this.onPressed,
    super.key,
  });

  final Dose dose;
  final Protocol? protocol;
  final Future<void> Function() onPressed;

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

  Widget _buildDetailLine(
    BuildContext context,
    Color protocolColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocol = widget.protocol;
    final timeText = _formatTime(widget.dose.scheduledFor);
    final drawText = protocol?.drawUnitsDisplay;

    final baseStyle = TextStyle(
      fontSize: AppTypography.caption,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );

    if (drawText != null && drawText.trim().isNotEmpty) {
      return Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: '${widget.dose.amount} • '),
            TextSpan(
              text: drawText,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' • $timeText'),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final details = protocol?.doseDetails;

    if (details != null && details.hasPhysicalDose) {
      final quantity = _formatDoseNumber(details.scheduledQuantity!);
      final strength = _formatDoseNumber(details.strengthAmount!);
      final quantityUnit = details.quantityUnitLabel;
      final displayUnit =
          details.scheduledQuantity == 1 ||
              quantityUnit == 'mL' ||
              quantityUnit == 'g'
          ? quantityUnit
          : '${quantityUnit}s';

      return Text(
        '$quantity $displayUnit × $strength '
        '${details.strengthUnit!.label} • $timeText',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return Text(
      '${widget.dose.amount} • $timeText',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protocolColor = Color(widget.dose.protocolColorValue);
    final buttonForeground =
        ThemeData.estimateBrightnessForColor(protocolColor) == Brightness.light
        ? Colors.black87
        : Colors.white;

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
                _buildDetailLine(
                  context,
                  protocolColor,
                ),
                if (widget.dose.hasCycleStatus) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Cycle: ${widget.dose.cyclePrimaryLabel!}',
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
                ? SizedBox(
                    key: const ValueKey('dose-loading'),
                    width: 96,
                    height: 42,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        backgroundColor: protocolColor.withValues(alpha: 0.82),
                        disabledBackgroundColor:
                            protocolColor.withValues(alpha: 0.42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.button,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: buttonForeground,
                        ),
                      ),
                    ),
                  )
                : FilledButton(
                    key: const ValueKey('take-dose'),
                    onPressed: _markTaken,
                    style: FilledButton.styleFrom(
                      backgroundColor: protocolColor,
                      foregroundColor: buttonForeground,
                      minimumSize: const Size(96, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Take Dose',
                      style: TextStyle(fontWeight: FontWeight.w800),
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
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
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
            dose.isSkipped
                ? Icons.remove_circle_outline
                : Icons.check_circle,
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
                        Icons.location_on_outlined,
                        size: 14,
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dose.injectionSiteLabel!,
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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


String _formatDoseNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

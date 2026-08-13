import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

import '../inventory_setup_screen.dart';
import '../widgets/step_header.dart';

enum RemainingAmountMethod { manual, dosesUsed, openedDate, ghostHistory }

class RemainingAmountStep extends StatefulWidget {
  const RemainingAmountStep({
    required this.containerType,
    required this.containerSize,
    required this.unit,
    required this.source,
    required this.currentAmount,
    required this.protocolDoseAmount,
    required this.protocolDoseUnit,
    required this.onCurrentAmountChanged,
    super.key,
  });

  final String containerType;
  final double containerSize;
  final String unit;
  final ActiveContainerSource source;
  final double currentAmount;

  final double? protocolDoseAmount;
  final String? protocolDoseUnit;

  final ValueChanged<double> onCurrentAmountChanged;

  @override
  State<RemainingAmountStep> createState() => _RemainingAmountStepState();
}

class _RemainingAmountStepState extends State<RemainingAmountStep> {
  RemainingAmountMethod _method = RemainingAmountMethod.manual;

  late final TextEditingController _remainingController;
  late final TextEditingController _dosesUsedController;

  @override
  void initState() {
    super.initState();

    _remainingController = TextEditingController(
      text: _formatNumber(widget.currentAmount),
    );

    _dosesUsedController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _remainingController.dispose();
    _dosesUsedController.dispose();
    super.dispose();
  }

  bool get _canUseProtocolDose {
    final dose = widget.protocolDoseAmount;

    if (dose == null || dose <= 0) {
      return false;
    }

    if (widget.protocolDoseUnit == null) {
      return false;
    }

    return widget.protocolDoseUnit!.toLowerCase() == widget.unit.toLowerCase();
  }

  void _applyManualAmount() {
    final parsed = double.tryParse(_remainingController.text.trim());

    if (parsed == null) {
      return;
    }

    final normalized = parsed.clamp(0.0, widget.containerSize);

    widget.onCurrentAmountChanged(normalized);

    _remainingController.text = _formatNumber(normalized);
  }

  void _calculateFromDoses() {
    if (!_canUseProtocolDose) {
      return;
    }

    final dosesUsed = int.tryParse(_dosesUsedController.text.trim());

    if (dosesUsed == null || dosesUsed < 0) {
      return;
    }

    final doseAmount = widget.protocolDoseAmount!;

    final usedAmount = doseAmount * dosesUsed;

    final remaining = (widget.containerSize - usedAmount).clamp(
      0.0,
      widget.containerSize,
    );

    widget.onCurrentAmountChanged(remaining);

    _remainingController.text = _formatNumber(remaining);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = widget.containerType.toLowerCase();

    if (widget.source == ActiveContainerSource.none) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Active container',
            subtitle: 'There is no active container to estimate.',
            currentStep: 4,
            totalSteps: 7,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (Theme.of(context).cardTheme.color ?? colors.surface),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All containers will remain unopened.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: 'How much is left?',
          subtitle: 'Ghost can help estimate what remains in the active $name.',
          currentStep: 4,
          totalSteps: 7,
        ),

        const SizedBox(height: AppSpacing.lg),

        _MethodCard(
          title: 'Enter remaining amount',
          subtitle: 'Use this if you already know what is left.',
          icon: Icons.edit_outlined,
          selected: _method == RemainingAmountMethod.manual,
          onTap: () {
            setState(() {
              _method = RemainingAmountMethod.manual;
            });
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        _MethodCard(
          title: 'Estimate from doses used',
          subtitle: _canUseProtocolDose
              ? 'Ghost will use the protocol dose automatically.'
              : 'Protocol dose and inventory unit must match.',
          icon: Icons.calculate_outlined,
          selected: _method == RemainingAmountMethod.dosesUsed,
          enabled: _canUseProtocolDose,
          onTap: () {
            setState(() {
              _method = RemainingAmountMethod.dosesUsed;
            });
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        _MethodCard(
          title: 'Estimate from opened date',
          subtitle:
              'Ghost will calculate expected use from the protocol schedule.',
          icon: Icons.calendar_month_outlined,
          selected: _method == RemainingAmountMethod.openedDate,
          enabled: false,
          onTap: () {},
        ),

        const SizedBox(height: AppSpacing.sm),

        _MethodCard(
          title: 'Use Ghost dose history',
          subtitle:
              'Automatically calculate doses recorded since the vial was opened.',
          icon: Icons.history,
          selected: _method == RemainingAmountMethod.ghostHistory,
          enabled: false,
          onTap: () {},
        ),

        const SizedBox(height: AppSpacing.lg),

        if (_method == RemainingAmountMethod.manual) ...[
          TextField(
            controller: _remainingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final parsed = double.tryParse(value.trim());

              if (parsed != null) {
                final normalized = parsed.clamp(0.0, widget.containerSize);

                widget.onCurrentAmountChanged(normalized);
              }
            },
            onSubmitted: (_) {
              _applyManualAmount();
            },
            decoration: InputDecoration(
              labelText: 'Remaining amount',
              suffixText: widget.unit,
              helperText:
                  'Maximum ${_formatNumber(widget.containerSize)} ${widget.unit}',
              border: const OutlineInputBorder(),
            ),
          ),
        ],

        if (_method == RemainingAmountMethod.dosesUsed) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (Theme.of(context).cardTheme.color ?? colors.surface),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Text(
              'Starting amount: '
              '${_formatNumber(widget.containerSize)} ${widget.unit}\n'
              'Dose: '
              '${_formatNumber(widget.protocolDoseAmount ?? 0)} '
              '${widget.protocolDoseUnit ?? widget.unit}',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _dosesUsedController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              _calculateFromDoses();
            },
            decoration: const InputDecoration(
              labelText: 'Doses used from this container',
              hintText: 'Example: 12',
              border: OutlineInputBorder(),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.primary.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated remaining',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatNumber(widget.currentAmount)} ${widget.unit}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'of ${_formatNumber(widget.containerSize)} ${widget.unit}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary.withValues(alpha: 0.10)
                  : (Theme.of(context).cardTheme.color ?? colors.surface),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

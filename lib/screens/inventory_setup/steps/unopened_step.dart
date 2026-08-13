import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/step_header.dart';

class UnopenedStep extends StatefulWidget {
  const UnopenedStep({
    required this.containerType,
    required this.unopenedQuantity,
    required this.onUnopenedQuantityChanged,
    super.key,
  });

  final String containerType;

  // Temporary legacy name.
  // This now represents TOTAL containers owned during setup.
  final int unopenedQuantity;

  final ValueChanged<int> onUnopenedQuantityChanged;

  @override
  State<UnopenedStep> createState() => _UnopenedStepState();
}

class _UnopenedStepState extends State<UnopenedStep> {
  late final TextEditingController _quantityController;
  late final FocusNode _quantityFocusNode;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.unopenedQuantity.toString(),
    );
    _quantityFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant UnopenedStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.unopenedQuantity != widget.unopenedQuantity &&
        !_quantityFocusNode.hasFocus) {
      _quantityController.text = widget.unopenedQuantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  String get _singular => widget.containerType.toLowerCase();
  String get _plural => _pluralize(_singular);

  void _applyQuantity(int value) {
    final normalized = value < 0 ? 0 : value;
    widget.onUnopenedQuantityChanged(normalized);

    if (!_quantityFocusNode.hasFocus) {
      _quantityController.text = normalized.toString();
    }
  }

  void _commitTypedQuantity() {
    final parsed = int.tryParse(_quantityController.text.trim());

    if (parsed == null || parsed < 0) {
      _quantityController.text = widget.unopenedQuantity.toString();
      return;
    }

    widget.onUnopenedQuantityChanged(parsed);
    _quantityController.text = parsed.toString();
  }

  void _setQuickQuantity(int quantity) {
    widget.onUnopenedQuantityChanged(quantity);
    _quantityController.text = quantity.toString();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = widget.unopenedQuantity;
    final quantityLabel = quantity == 1 ? _singular : _plural;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: 'How many $_plural do you have?',
          subtitle: 'Enter the total number you physically have right now.',
          currentStep: 5,
          totalSteps: 7,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.60),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.inventory_2_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Count everything you own. If you bought a 10-$_singular kit, '
                  'enter 10. Ghost will handle the active $_singular separately.',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: _quantityController,
                  focusNode: _quantityFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _commitTypedQuantity(),
                  onEditingComplete: () {
                    _commitTypedQuantity();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                quantityLabel,
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: quantity <= 0
                    ? null
                    : () => _applyQuantity(quantity - 1),
                icon: const Icon(Icons.remove_rounded),
                label: const Text('1'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _applyQuantity(quantity + 1),
                icon: const Icon(Icons.add_rounded),
                label: const Text('1'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Quick select',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final quantityOption in [1, 2, 3, 5, 10])
              ChoiceChip(
                label: Text(
                  quantityOption == 10 ? 'Kit · 10' : '$quantityOption',
                ),
                selected: quantity == quantityOption,
                onSelected: (_) => _setQuickQuantity(quantityOption),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  quantity == 0
                      ? 'No $_plural are currently being added.'
                      : 'You are adding $quantity $quantityLabel to Ghost Supply.',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _pluralize(String value) {
    if (value == 'box') {
      return 'boxes';
    }
    if (value.endsWith('s')) {
      return value;
    }
    return '${value}s';
  }
}

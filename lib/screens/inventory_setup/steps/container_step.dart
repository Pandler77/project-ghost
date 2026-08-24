import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

import '../../../models/inventory_preset.dart';
import '../widgets/step_header.dart';

class ContainerStep extends StatefulWidget {
  const ContainerStep({
    required this.protocolName,
    required this.preset,
    required this.containerType,
    required this.containerSize,
    required this.unit,
    required this.onContainerTypeChanged,
    required this.onContainerSizeChanged,
    required this.onUnitChanged,
    super.key,
  });

  final String protocolName;
  final InventoryPreset? preset;

  final String containerType;
  final double containerSize;
  final String unit;

  final ValueChanged<String> onContainerTypeChanged;
  final ValueChanged<double> onContainerSizeChanged;
  final ValueChanged<String> onUnitChanged;

  @override
  State<ContainerStep> createState() => _ContainerStepState();
}

class _ContainerStepState extends State<ContainerStep> {
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;

  static const List<String> _primaryContainerTypes = ['Vial', 'Bottle', 'Pen'];

  static const List<String> _allContainerTypes = [
    'Vial',
    'Bottle',
    'Pen',
    'Box',
    'Tube',
    'Package',
    'Container',
  ];

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text: _formatNumber(widget.containerSize),
    );

    _amountFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant ContainerStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.containerSize != widget.containerSize &&
        !_amountFocusNode.hasFocus) {
      _amountController.text = _formatNumber(widget.containerSize);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  List<String> get _primaryUnits {
    switch (widget.containerType) {
      case 'Vial':
        return ['mg', 'mcg', 'mL', 'IU'];

      case 'Bottle':
        return ['mL', 'mg', 'tablets', 'capsules'];

      case 'Pen':
        return ['mg', 'mL', 'IU'];

      case 'Box':
      case 'Package':
        return ['tablets', 'capsules', 'pills', 'softgels'];

      case 'Tube':
        return ['g', 'mg', 'mL'];

      default:
        return ['mg', 'mcg', 'mL', 'IU'];
    }
  }

  List<String> get _allUnits {
    return const [
      'mg',
      'mcg',
      'g',
      'mL',
      'IU',
      'tablets',
      'capsules',
      'pills',
      'softgels',
      'drops',
    ];
  }

  double get _stepSize {
    switch (widget.unit) {
      case 'mcg':
        return widget.containerSize >= 1000 ? 100 : 50;

      case 'IU':
      case 'tablets':
      case 'capsules':
      case 'pills':
      case 'softgels':
      case 'drops':
        return 1;

      case 'mL':
        return 0.1;

      case 'mg':
        if (widget.containerSize >= 1000) {
          return 100;
        }

        if (widget.containerSize >= 100) {
          return 10;
        }

        if (widget.containerSize >= 10) {
          return 5;
        }

        return 0.5;

      case 'g':
        return 0.1;

      default:
        return 1;
    }
  }

  void _applyAmount(double value) {
    final normalized = value < 0.1 ? 0.1 : value;

    widget.onContainerSizeChanged(normalized);

    if (!_amountFocusNode.hasFocus) {
      _amountController.text = _formatNumber(normalized);
    }
  }

  void _commitTypedAmount() {
    final parsed = double.tryParse(_amountController.text.trim());

    if (parsed == null || parsed <= 0) {
      _amountController.text = _formatNumber(widget.containerSize);
      return;
    }

    widget.onContainerSizeChanged(parsed);
  }

  Future<void> _showContainerTypes() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Container type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final type in _allContainerTypes)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(type),
                            trailing: widget.containerType == type
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () {
                              Navigator.pop(context, type);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      widget.onContainerTypeChanged(selected);
    }
  }

  Future<void> _showUnits() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final option in _allUnits)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(option),
                            trailing: widget.unit == option
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () {
                              Navigator.pop(context, option);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      widget.onUnitChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final visibleContainerTypes = <String>{
      ..._primaryContainerTypes,
      if (!_primaryContainerTypes.contains(widget.containerType))
        widget.containerType,
    }.toList();

    final visibleUnits = <String>{
      ..._primaryUnits,
      if (!_primaryUnits.contains(widget.unit)) widget.unit,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'What are you adding?',
          subtitle: 'Tell MODOSE what each container is and how much it holds.',
          currentStep: 2,
          totalSteps: 7,
        ),

        const SizedBox(height: AppSpacing.lg),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: (Theme.of(context).cardTheme.color ?? colorScheme.surface),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.protocolName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.preset == null
                    ? 'Enter the inventory that matches what you physically have.'
                    : 'MODOSE filled in a common starting point. Change anything that does not match your supply.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Container type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final type in visibleContainerTypes)
              ChoiceChip(
                label: Text(type),
                selected: widget.containerType == type,
                onSelected: (_) {
                  widget.onContainerTypeChanged(type);
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.more_horiz, size: 18),
              label: const Text('More'),
              onPressed: _showContainerTypes,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          'How much is in each ${widget.containerType.toLowerCase()}?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 6),

        Text(
          'Tap the number to type an exact value.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),

        const SizedBox(height: AppSpacing.md),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: (Theme.of(context).cardTheme.color ?? colorScheme.surface),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.trim());

                      if (parsed != null && parsed > 0) {
                        widget.onContainerSizeChanged(parsed);
                      }
                    },
                    onSubmitted: (_) {
                      _commitTypedAmount();
                    },
                    onEditingComplete: () {
                      _commitTypedAmount();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _applyAmount(widget.containerSize - _stepSize);
                },
                icon: const Icon(Icons.remove),
                label: Text('- ${_formatNumber(_stepSize)}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () {
                  _applyAmount(widget.containerSize + _stepSize);
                },
                icon: const Icon(Icons.add),
                label: Text('+ ${_formatNumber(_stepSize)}'),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Unit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in visibleUnits)
              ChoiceChip(
                label: Text(option),
                selected: widget.unit == option,
                onSelected: (_) {
                  widget.onUnitChanged(option);
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.more_horiz, size: 18),
              label: const Text('More'),
              onPressed: _showUnits,
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}


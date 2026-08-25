import 'package:flutter/material.dart';

import '../widgets/app_select_field.dart';

import '../models/dose_details.dart';
import '../models/dose_unit.dart';
import '../models/protocol_type.dart';
import '../theme/app_theme.dart';

class AdvancedDoseDetailsScreen extends StatefulWidget {
  const AdvancedDoseDetailsScreen({
    required this.protocolType,
    required this.scheduledDoseAmount,
    required this.scheduledDoseUnit,
    this.initialDetails,
    this.presetName,
    super.key,
  });

  final ProtocolType protocolType;
  final double scheduledDoseAmount;
  final DoseUnit scheduledDoseUnit;
  final DoseDetails? initialDetails;
  final String? presetName;

  @override
  State<AdvancedDoseDetailsScreen> createState() =>
      _AdvancedDoseDetailsScreenState();
}

class _AdvancedDoseDetailsScreenState extends State<AdvancedDoseDetailsScreen> {
  late DoseForm? _form;
  late final TextEditingController _strengthController;
  late DoseUnit _strengthUnit;
  late final TextEditingController _quantityController;
  late final TextEditingController _vialAmountController;
  late DoseUnit _vialUnit;
  late final TextEditingController _bacController;

  String _syringeType = 'U-100';
  bool _showDrawUnits = false;

  final List<_BlendEditorRow> _blendRows = [];

  bool get _isInjection => widget.protocolType == ProtocolType.injection;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialDetails;

    _form =
        initial?.form ??
        _defaultFormForDoseUnit(
          widget.protocolType,
          widget.scheduledDoseUnit,
        );

    _strengthController = TextEditingController(
      text: _formatNullable(initial?.strengthAmount),
    );

    final savedStrengthUnit = initial?.strengthUnit;
    _strengthUnit = savedStrengthUnit != null &&
            _strengthUnits.contains(savedStrengthUnit)
        ? savedStrengthUnit
        : _strengthUnits.contains(widget.scheduledDoseUnit)
            ? widget.scheduledDoseUnit
            : DoseUnit.mg;

    _quantityController = TextEditingController(
      text: initial?.scheduledQuantity != null
          ? _formatNullable(initial?.scheduledQuantity)
          : _isPhysicalDoseUnit(widget.scheduledDoseUnit)
              ? '1'
              : '',
    );

    _vialAmountController = TextEditingController(
      text: _formatNullable(initial?.vialAmount),
    );
    _vialUnit = initial?.vialUnit ?? widget.scheduledDoseUnit;
    _bacController = TextEditingController(
      text: _formatNullable(initial?.reconstitutionVolumeMl),
    );

    _syringeType = initial?.syringeType ?? 'U-100';
    _showDrawUnits = initial?.showDrawUnitsOnCards ?? false;

    for (final component
        in initial?.blendComponents ?? const <BlendComponent>[]) {
      _blendRows.add(_BlendEditorRow.fromComponent(component));
    }

    if (_blendRows.isEmpty) {
      final suggestedNames = _suggestedBlendComponentNames(widget.presetName);

      if (suggestedNames.isNotEmpty) {
        for (final name in suggestedNames) {
          _blendRows.add(
            _BlendEditorRow(
              nameController: TextEditingController(text: name),
              amountController: TextEditingController(),
              unit: widget.scheduledDoseUnit,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _strengthController.dispose();
    _quantityController.dispose();
    _vialAmountController.dispose();
    _bacController.dispose();

    for (final row in _blendRows) {
      row.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advanced Dose Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Text(
                    _isInjection
                        ? 'Add optional vial, reconstitution, syringe, or blend details.'
                        : 'Add optional form, strength, quantity, or composition details.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (!_isInjection) ...[
                    _sectionTitle('Form & strength'),
                    const SizedBox(height: AppSpacing.sm),
                    AppSelectField<DoseForm>(
                      value: _form,
                      values: _formsForType(widget.protocolType),
                      label: 'Dose form',
                      placeholder: 'Choose a form',
                      labelBuilder: (form) => form.label,
                      onChanged: (form) => setState(() => _form = form),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _strengthController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Strength per item',
                              hintText: '500',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppSelectField<DoseUnit>(
                            value: _strengthUnit,
                            values: _strengthUnits,
                            label: 'Unit',
                            labelBuilder: (unit) => unit.label,
                            onChanged: (unit) {
                              setState(() => _strengthUnit = unit);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Scheduled quantity',
                        hintText: '1',
                        suffixText: _form?.label.toLowerCase(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_oralTotalText != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _summaryCard(_oralTotalText!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  if (_isInjection) ...[
                    _sectionTitle('Reconstitution & syringe'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _vialAmountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Amount in vial',
                              hintText: '10',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppSelectField<DoseUnit>(
                            value: _vialUnit,
                            values: _injectableUnits,
                            label: 'Unit',
                            labelBuilder: (unit) => unit.label,
                            onChanged: (unit) {
                              setState(() => _vialUnit = unit);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _bacController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'BAC / reconstitution volume',
                        hintText: '2',
                        suffixText: 'mL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSelectField<String>(
                      value: _syringeType,
                      values: const ['U-100'],
                      label: 'Syringe type',
                      labelBuilder: (value) =>
                          value == 'U-100' ? 'U-100 insulin syringe' : value,
                      onChanged: (value) {
                        setState(() => _syringeType = value);
                      },
                    ),
                    if (_drawSummary != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _summaryCard(_drawSummary!),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Show draw units on protocol cards',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Example: “Draw 20 units” beneath the scheduled dose.',
                      ),
                      value: _showDrawUnits,
                      onChanged: _drawSummary == null
                          ? null
                          : (value) => setState(() => _showDrawUnits = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  _sectionTitle('Blend / composition'),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Optional. Add each active component separately.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  for (var index = 0; index < _blendRows.length; index++) ...[
                    _BlendComponentEditor(
                      row: _blendRows[index],
                      onChanged: () => setState(() {}),
                      onRemove: () {
                        setState(() {
                          final removed = _blendRows.removeAt(index);
                          removed.dispose();
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _blendRows.add(
                          _BlendEditorRow(
                            nameController: TextEditingController(),
                            amountController: TextEditingController(),
                            unit: widget.scheduledDoseUnit,
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add component'),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Save Details',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppTypography.body,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _summaryCard(String text) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
      ),
    );
  }

  String? get _oralTotalText {
    final strength = double.tryParse(_strengthController.text.trim());
    final quantity = double.tryParse(_quantityController.text.trim());

    if (strength == null ||
        strength <= 0 ||
        quantity == null ||
        quantity <= 0) {
      return null;
    }

    final total = strength * quantity;
    final form = _form?.label.toLowerCase() ?? 'item';

    return '${_format(quantity)} $form${quantity == 1 ? '' : 's'} × '
        '${_format(strength)} ${_strengthUnit.label} = '
        '${_format(total)} ${_strengthUnit.label}';
  }

  String? get _drawSummary {
    final vialAmount = double.tryParse(_vialAmountController.text.trim());
    final bac = double.tryParse(_bacController.text.trim());

    if (vialAmount == null || vialAmount <= 0 || bac == null || bac <= 0) {
      return null;
    }

    final details = DoseDetails(
      vialAmount: vialAmount,
      vialUnit: _vialUnit,
      reconstitutionVolumeMl: bac,
      syringeType: _syringeType,
    );

    final concentration = details.concentrationPerMl(
      scheduledDoseUnit: widget.scheduledDoseUnit,
    );
    final drawUnits = details.drawUnits(
      scheduledDoseAmount: widget.scheduledDoseAmount,
      scheduledDoseUnit: widget.scheduledDoseUnit,
    );

    if (concentration == null || drawUnits == null) {
      return 'Vial and scheduled dose units are not directly convertible.';
    }

    return 'Concentration: ${_format(concentration)} '
        '${widget.scheduledDoseUnit.label}/mL • '
        'Draw ${_format(drawUnits)} units';
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();

    final components = <BlendComponent>[];

    for (final row in _blendRows) {
      final name = row.nameController.text.trim();
      final amount = double.tryParse(row.amountController.text.trim());

      if (name.isEmpty && amount == null) continue;

      if (name.isEmpty || amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Each blend component needs a name and amount.',
            ),
          ),
        );
        return;
      }

      components.add(
        BlendComponent(
          name: name,
          amount: amount,
          unit: row.unit,
        ),
      );
    }

    final strength = _positiveDouble(_strengthController.text);
    final vialAmount = _positiveDouble(_vialAmountController.text);

    final details = DoseDetails(
      form: _form,
      strengthAmount: strength,
      strengthUnit: strength == null ? null : _strengthUnit,
      scheduledQuantity: _positiveDouble(_quantityController.text),
      vialAmount: vialAmount,
      vialUnit: vialAmount == null ? null : _vialUnit,
      reconstitutionVolumeMl: _positiveDouble(_bacController.text),
      syringeType: _syringeType,
      showDrawUnitsOnCards: _showDrawUnits && _drawSummary != null,
      blendComponents: components,
    );

    Navigator.pop(context, details);
  }

  double? _positiveDouble(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static List<String> _suggestedBlendComponentNames(String? presetName) {
    if (presetName == null || presetName.trim().isEmpty) {
      return const [];
    }

    final normalized = presetName.trim().toLowerCase();

    switch (normalized) {
      case 'wolverine (blend)':
        return const [
          'BPC-157',
          'TB-500',
        ];

      case 'glow (blend)':
        return const [
          'GHK-Cu',
          'BPC-157',
          'TB-500',
        ];

      case 'klow (blend)':
        return const [
          'GHK-Cu',
          'BPC-157',
          'TB-500',
          'KPV',
        ];
    }

    final cleaned = presetName
        .replaceAll(RegExp(r'\s*\(Blend\)\s*', caseSensitive: false), '')
        .trim();

    if (!cleaned.contains('+')) {
      return const [];
    }

    return cleaned
        .split('+')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static DoseForm? _defaultForm(ProtocolType type) {
    return switch (type) {
      ProtocolType.injection => DoseForm.injection,
      ProtocolType.oral => DoseForm.tablet,
      ProtocolType.topical => DoseForm.cream,
      ProtocolType.nasal => DoseForm.spray,
      ProtocolType.sublingual => DoseForm.drop,
      ProtocolType.other => DoseForm.other,
    };
  }

  static DoseForm? _defaultFormForDoseUnit(
    ProtocolType type,
    DoseUnit scheduledDoseUnit,
  ) {
    return switch (scheduledDoseUnit) {
      DoseUnit.tablets => DoseForm.tablet,
      DoseUnit.capsules => DoseForm.capsule,
      DoseUnit.pills => DoseForm.pill,
      DoseUnit.sprays => DoseForm.spray,
      DoseUnit.drops => DoseForm.drop,
      DoseUnit.patches => DoseForm.patch,
      _ => _defaultForm(type),
    };
  }

  static bool _isPhysicalDoseUnit(DoseUnit unit) {
    return switch (unit) {
      DoseUnit.tablets ||
      DoseUnit.capsules ||
      DoseUnit.pills ||
      DoseUnit.sprays ||
      DoseUnit.drops ||
      DoseUnit.patches ||
      DoseUnit.servings => true,
      _ => false,
    };
  }

  static List<DoseForm> _formsForType(ProtocolType type) {
    return switch (type) {
      ProtocolType.injection => const [DoseForm.injection],
      ProtocolType.oral => const [
          DoseForm.tablet,
          DoseForm.capsule,
          DoseForm.pill,
          DoseForm.liquid,
          DoseForm.powder,
          DoseForm.other,
        ],
      ProtocolType.topical => const [
          DoseForm.cream,
          DoseForm.gel,
          DoseForm.patch,
          DoseForm.liquid,
          DoseForm.other,
        ],
      ProtocolType.nasal => const [
          DoseForm.spray,
          DoseForm.drop,
          DoseForm.other,
        ],
      ProtocolType.sublingual => const [
          DoseForm.drop,
          DoseForm.tablet,
          DoseForm.liquid,
          DoseForm.other,
        ],
      ProtocolType.other => DoseForm.values,
    };
  }

  static const _strengthUnits = [
    DoseUnit.mg,
    DoseUnit.mcg,
    DoseUnit.g,
    DoseUnit.mL,
    DoseUnit.units,
    DoseUnit.iu,
  ];

  static const _injectableUnits = [
    DoseUnit.mg,
    DoseUnit.mcg,
    DoseUnit.g,
    DoseUnit.units,
    DoseUnit.iu,
    DoseUnit.mL,
  ];

  static String _formatNullable(double? value) {
    if (value == null) return '';
    return _format(value);
  }

  static String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _BlendEditorRow {
  _BlendEditorRow({
    required this.nameController,
    required this.amountController,
    required this.unit,
  });

  factory _BlendEditorRow.fromComponent(BlendComponent component) {
    return _BlendEditorRow(
      nameController: TextEditingController(text: component.name),
      amountController: TextEditingController(
        text: _AdvancedDoseDetailsScreenState._format(component.amount),
      ),
      unit: component.unit,
    );
  }

  final TextEditingController nameController;
  final TextEditingController amountController;
  DoseUnit unit;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class _BlendComponentEditor extends StatelessWidget {
  const _BlendComponentEditor({
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final _BlendEditorRow row;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: row.nameController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Component',
            hintText: 'BPC-157',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: row.amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: AppSelectField<DoseUnit>(
                value: row.unit,
                values: const [
                  DoseUnit.mg,
                  DoseUnit.mcg,
                  DoseUnit.g,
                  DoseUnit.units,
                  DoseUnit.iu,
                ],
                label: 'Unit',
                labelBuilder: (unit) => unit.label,
                onChanged: (unit) {
                  row.unit = unit;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Remove component',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ],
    );
  }
}

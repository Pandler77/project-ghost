import 'package:flutter/material.dart';

import '../widgets/app_select_field.dart';

import '../../models/dose_details.dart';
import '../../models/dose_unit.dart';
import '../../models/protocol.dart';
import '../../models/protocol_type.dart';
import '../../theme/app_theme.dart';

class EditProtocolDetailsScreen extends StatefulWidget {
  const EditProtocolDetailsScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditProtocolDetailsScreen> createState() =>
      _EditProtocolDetailsScreenState();
}

class _EditProtocolDetailsScreenState extends State<EditProtocolDetailsScreen> {
  static const List<DoseUnit> _injectionUnits = [
    DoseUnit.mg,
    DoseUnit.mcg,
    DoseUnit.g,
    DoseUnit.iu,
    DoseUnit.mL,
    DoseUnit.units,
  ];

  static const List<DoseUnit> _otherUnits = [
    DoseUnit.mg,
    DoseUnit.mcg,
    DoseUnit.g,
    DoseUnit.iu,
    DoseUnit.mL,
    DoseUnit.units,
    DoseUnit.tablets,
    DoseUnit.capsules,
    DoseUnit.pills,
    DoseUnit.sprays,
    DoseUnit.drops,
    DoseUnit.patches,
    DoseUnit.servings,
  ];

  static const List<DoseUnit> _strengthUnits = [
    DoseUnit.mcg,
    DoseUnit.mg,
    DoseUnit.g,
    DoseUnit.iu,
    DoseUnit.units,
    DoseUnit.mL,
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _doseAmountController;
  late final TextEditingController _strengthController;
  late final TextEditingController _quantityController;

  late DoseUnit _selectedUnit;
  late DoseUnit _strengthUnit;
  late DoseForm _doseForm;

  bool get _usesPhysicalDoseEditor {
    return switch (widget.protocol.type) {
      ProtocolType.oral ||
      ProtocolType.topical ||
      ProtocolType.nasal ||
      ProtocolType.sublingual => true,
      _ => false,
    };
  }

  List<DoseUnit> get _availableUnits =>
      widget.protocol.type == ProtocolType.injection
          ? _injectionUnits
          : _otherUnits;

  List<DoseForm> get _availableForms {
    return switch (widget.protocol.type) {
      ProtocolType.oral => const [
          DoseForm.tablet,
          DoseForm.capsule,
          DoseForm.pill,
          DoseForm.liquid,
          DoseForm.powder,
          DoseForm.scoop,
          DoseForm.serving,
        ],
      ProtocolType.topical => const [
          DoseForm.cream,
          DoseForm.gel,
          DoseForm.liquid,
          DoseForm.patch,
          DoseForm.pump,
        ],
      ProtocolType.nasal => const [
          DoseForm.spray,
          DoseForm.drop,
        ],
      ProtocolType.sublingual => const [
          DoseForm.drop,
          DoseForm.liquid,
          DoseForm.spray,
        ],
      _ => const [DoseForm.other],
    };
  }

  @override
  void initState() {
    super.initState();

    final details = widget.protocol.doseDetails;

    _nameController = TextEditingController(text: widget.protocol.name);
    _doseAmountController = TextEditingController(
      text: _formatNumber(widget.protocol.doseAmount),
    );

    _selectedUnit = _availableUnits.contains(widget.protocol.doseUnit)
        ? widget.protocol.doseUnit
        : _availableUnits.first;

    _doseForm = details?.form != null && _availableForms.contains(details!.form)
        ? details.form!
        : _availableForms.first;

    _strengthUnit = details?.strengthUnit != null &&
            _strengthUnits.contains(details!.strengthUnit)
        ? details.strengthUnit!
        : _strengthUnits.contains(widget.protocol.doseUnit)
            ? widget.protocol.doseUnit
            : DoseUnit.mg;

    _strengthController = TextEditingController(
      text: details?.strengthAmount == null
          ? _formatNumber(widget.protocol.doseAmount)
          : _formatNumber(details!.strengthAmount!),
    );

    _quantityController = TextEditingController(
      text: _formatNumber(details?.scheduledQuantity ?? 1),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseAmountController.dispose();
    _strengthController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  double? get _totalPhysicalDose {
    final strength = double.tryParse(_strengthController.text.trim());
    final quantity = double.tryParse(_quantityController.text.trim());

    if (strength == null || strength <= 0 || quantity == null || quantity <= 0) {
      return null;
    }

    return strength * quantity;
  }

  String get _strengthLabel {
    return switch (_doseForm) {
      DoseForm.liquid => 'Strength per mL',
      DoseForm.powder => 'Strength per g',
      DoseForm.cream => 'Strength per mL',
      DoseForm.gel => 'Strength per mL',
      _ => 'Strength per ${_doseForm.label.toLowerCase()}',
    };
  }

  String get _quantityLabel {
    return switch (_doseForm) {
      DoseForm.liquid => 'mL per dose',
      DoseForm.powder => 'Grams per dose',
      DoseForm.cream => 'mL per application',
      DoseForm.gel => 'mL per application',
      _ => '${_doseForm.label}s per dose',
    };
  }

  String get _quantitySuffix {
    return switch (_doseForm) {
      DoseForm.liquid || DoseForm.cream || DoseForm.gel => 'mL',
      DoseForm.powder => 'g',
      _ => _doseForm.label.toLowerCase(),
    };
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('Protocol name is required.');
      return;
    }

    if (_usesPhysicalDoseEditor) {
      final strength = double.tryParse(_strengthController.text.trim());
      final quantity = double.tryParse(_quantityController.text.trim());

      if (strength == null || strength <= 0) {
        _showError('Enter a valid strength.');
        return;
      }

      if (quantity == null || quantity <= 0) {
        _showError('Enter a valid quantity.');
        return;
      }

      final existing = widget.protocol.doseDetails;

      final details = DoseDetails(
        form: _doseForm,
        strengthAmount: strength,
        strengthUnit: _strengthUnit,
        scheduledQuantity: quantity,
        vialAmount: existing?.vialAmount,
        vialUnit: existing?.vialUnit,
        reconstitutionVolumeMl: existing?.reconstitutionVolumeMl,
        syringeType: existing?.syringeType ?? 'U-100',
        showDrawUnitsOnCards: existing?.showDrawUnitsOnCards ?? false,
        blendComponents: existing?.blendComponents ?? const [],
      );

      Navigator.pop(
        context,
        widget.protocol.copyWith(
          name: name,
          doseAmount: strength * quantity,
          doseUnit: _strengthUnit,
          doseDetails: details,
        ),
      );

      return;
    }

    final amount = double.tryParse(_doseAmountController.text.trim());

    if (amount == null || amount <= 0) {
      _showError('Enter a valid dose amount.');
      return;
    }

    Navigator.pop(
      context,
      widget.protocol.copyWith(
        name: name,
        doseAmount: amount,
        doseUnit: _selectedUnit,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Protocol')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const Text(
              'Protocol details',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _usesPhysicalDoseEditor
                  ? 'Update the form, strength, and amount taken each time.'
                  : 'Update the protocol name and scheduled dose.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _nameController,
              autofocus: false,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Protocol name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            if (_usesPhysicalDoseEditor) ...[
              AppSelectField<DoseForm>(
                value: _doseForm,
                values: _availableForms,
                label: 'Dose form',
                labelBuilder: (form) => form.label,
                onChanged: (value) {
                  setState(() => _doseForm = value);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _strengthController,
                      autofocus: false,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _strengthLabel,
                        border: const OutlineInputBorder(),
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
                      onChanged: (value) {
                        setState(() => _strengthUnit = value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: _quantityController,
                autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _quantityLabel,
                  suffixText: _quantitySuffix,
                  border: const OutlineInputBorder(),
                ),
              ),

              if (_totalPhysicalDose != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    '${_formatNumber(_quantityValue)} $_quantityDisplay × '
                    '${_formatNumber(_strengthValue)} ${_strengthUnit.label} '
                    '= ${_formatNumber(_totalPhysicalDose!)} '
                    '${_strengthUnit.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ] else ...[
              TextField(
                controller: _doseAmountController,
                autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Dose amount',
                  hintText: '3',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSelectField<DoseUnit>(
                value: _selectedUnit,
                values: _availableUnits,
                label: 'Unit',
                labelBuilder: (unit) => unit.label,
                onChanged: (value) {
                  setState(() => _selectedUnit = value);
                },
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _quantityValue =>
      double.tryParse(_quantityController.text.trim()) ?? 0;

  double get _strengthValue =>
      double.tryParse(_strengthController.text.trim()) ?? 0;

  String get _quantityDisplay {
    final base = _quantitySuffix;
    if (_quantityValue == 1 || base == 'mL' || base == 'g') return base;
    return '${base}s';
  }
}

import 'package:flutter/material.dart';

import '../../widgets/app_select_field.dart';

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

  static const List<DoseUnit> _oralUnits = [
    DoseUnit.tablets,
    DoseUnit.capsules,
    DoseUnit.pills,
    DoseUnit.mg,
    DoseUnit.mcg,
    DoseUnit.g,
    DoseUnit.mL,
    DoseUnit.servings,
  ];

  static const List<DoseUnit> _topicalUnits = [
    DoseUnit.mg,
    DoseUnit.g,
    DoseUnit.mL,
    DoseUnit.patches,
  ];

  static const List<DoseUnit> _nasalUnits = [
    DoseUnit.sprays,
    DoseUnit.drops,
    DoseUnit.mg,
    DoseUnit.mcg,
  ];

  static const List<DoseUnit> _sublingualUnits = [
    DoseUnit.drops,
    DoseUnit.mg,
    DoseUnit.mcg,
    DoseUnit.mL,
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

  late final TextEditingController _nameController;
  late final TextEditingController _doseAmountController;
  late DoseUnit _selectedUnit;

  List<DoseUnit> get _availableUnits {
    return switch (widget.protocol.type) {
      ProtocolType.injection => _injectionUnits,
      ProtocolType.oral => _oralUnits,
      ProtocolType.topical => _topicalUnits,
      ProtocolType.nasal => _nasalUnits,
      ProtocolType.sublingual => _sublingualUnits,
      ProtocolType.other => _otherUnits,
    };
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.protocol.name);
    _doseAmountController = TextEditingController(
      text: _formatNumber(widget.protocol.doseAmount),
    );

    _selectedUnit = _availableUnits.contains(widget.protocol.doseUnit)
        ? widget.protocol.doseUnit
        : _availableUnits.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseAmountController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final amount = double.tryParse(_doseAmountController.text.trim());

    if (name.isEmpty) {
      _showError('Protocol name is required.');
      return;
    }

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
    final colorScheme = Theme.of(context).colorScheme;
    final hasAdvancedDetails = widget.protocol.hasAdvancedDoseDetails;

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
              'Update the protocol name and scheduled dose.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
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
                setState(() {
                  _selectedUnit = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    hasAdvancedDetails
                        ? Icons.sync_outlined
                        : Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasAdvancedDetails
                          ? 'Advanced Dose Details will stay attached to this '
                                'protocol. Draw-unit calculations will update '
                                'automatically from the dose saved here.'
                          : 'Only units that match this protocol\'s '
                                'administration method are shown.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}

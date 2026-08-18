import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../theme/app_theme.dart';

class EditProtocolDetailsScreen extends StatefulWidget {
  const EditProtocolDetailsScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditProtocolDetailsScreen> createState() =>
      _EditProtocolDetailsScreenState();
}

class _EditProtocolDetailsScreenState extends State<EditProtocolDetailsScreen> {
  static const List<String> _commonUnits = [
    'mg',
    'mcg',
    'g',
    'IU',
    'mL',
    'units',
    'tablet',
    'capsule',
    'drop',
    'patch',
    'serving',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _doseAmountController;
  late final TextEditingController _customUnitController;

  String? _selectedUnit;
  bool _useCustomUnit = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.protocol.name);

    final parsedDose = _parseDose(widget.protocol.dose);

    _doseAmountController = TextEditingController(text: parsedDose.amount);

    final normalizedUnit = _normalizeUnit(parsedDose.unit);

    if (_commonUnits.contains(normalizedUnit)) {
      _selectedUnit = normalizedUnit;
      _useCustomUnit = false;
      _customUnitController = TextEditingController();
    } else {
      _selectedUnit = null;
      _useCustomUnit = true;
      _customUnitController = TextEditingController(text: parsedDose.unit);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseAmountController.dispose();
    _customUnitController.dispose();

    super.dispose();
  }

  String get _currentUnit {
    if (_useCustomUnit) {
      return _customUnitController.text.trim();
    }

    return _selectedUnit?.trim() ?? '';
  }

  void _save() {
    final name = _nameController.text.trim();

    final amount = double.tryParse(_doseAmountController.text.trim());

    final unit = _currentUnit;

    if (name.isEmpty) {
      _showError('Protocol name is required.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showError('Enter a valid dose amount.');
      return;
    }

    if (unit.isEmpty) {
      _showError('Dose unit is required.');
      return;
    }

    final formattedDose = '${_formatNumber(amount)} $unit';

    Navigator.pop(
      context,
      widget.protocol.copyWith(name: name, dose: formattedDose),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  _ParsedDose _parseDose(String dose) {
    final trimmed = dose.trim();

    final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*(.*)$').firstMatch(trimmed);

    if (match == null) {
      return const _ParsedDose(amount: '', unit: 'mg');
    }

    final amount = match.group(1) ?? '';
    final unit = match.group(2)?.trim() ?? '';

    return _ParsedDose(amount: amount, unit: unit.isEmpty ? 'mg' : unit);
  }

  String _normalizeUnit(String unit) {
    final normalized = unit.trim().toLowerCase();

    return switch (normalized) {
      'mg' => 'mg',
      'mcg' || 'µg' || 'ug' => 'mcg',
      'g' => 'g',
      'iu' || 'i.u.' => 'IU',
      'ml' => 'mL',
      'unit' || 'units' || 'u' => 'units',
      'tablet' || 'tablets' || 'tab' || 'tabs' => 'tablet',
      'capsule' || 'capsules' || 'cap' || 'caps' => 'capsule',
      'drop' || 'drops' => 'drop',
      'patch' || 'patches' => 'patch',
      'serving' || 'servings' => 'serving',
      _ => unit.trim(),
    };
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final dropdownValue = _useCustomUnit
        ? 'Other'
        : _commonUnits.contains(_selectedUnit)
        ? _selectedUnit
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Protocol')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              'Update the protocol name, dose amount, or measurement unit.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Protocol name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _doseAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Dose amount',
                hintText: '10',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              key: ValueKey(dropdownValue),
              initialValue: dropdownValue,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose a unit'),
              items: [
                for (final unit in _commonUnits)
                  DropdownMenuItem<String>(value: unit, child: Text(unit)),
                const DropdownMenuItem<String>(
                  value: 'Other',
                  child: Text('Other...'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == 'Other') {
                    _useCustomUnit = true;
                    _selectedUnit = null;
                  } else {
                    _useCustomUnit = false;
                    _selectedUnit = value;
                    _customUnitController.clear();
                  }
                });
              },
            ),

            if (_useCustomUnit) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _customUnitController,
                textCapitalization: TextCapitalization.none,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Custom unit',
                  hintText: 'pump, scoop, spray...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                'Saved doses will appear as amount plus unit, such as '
                '10 mg, 500 mcg, or 2 mL.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colorScheme.onSurfaceVariant,
                ),
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

class _ParsedDose {
  const _ParsedDose({required this.amount, required this.unit});

  final String amount;
  final String unit;
}

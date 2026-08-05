import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ReconstitutionCalculatorScreen extends StatefulWidget {
  const ReconstitutionCalculatorScreen({super.key});

  @override
  State<ReconstitutionCalculatorScreen> createState() =>
      _ReconstitutionCalculatorScreenState();
}

class _ReconstitutionCalculatorScreenState
    extends State<ReconstitutionCalculatorScreen> {
  final TextEditingController _vialAmountController = TextEditingController();

  final TextEditingController _liquidVolumeController = TextEditingController();

  final TextEditingController _desiredDoseController = TextEditingController();

  String _vialUnit = 'mg';
  String _doseUnit = 'mg';

  double _selectedSyringeMl = 1.0;

  double? _resultUnits;
  double? _resultMilliliters;
  double? _concentrationPerMl;
  double? _dosesPerVial;

  String? _errorMessage;

  @override
  void dispose() {
    _vialAmountController.dispose();
    _liquidVolumeController.dispose();
    _desiredDoseController.dispose();

    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();

    final vialAmount = double.tryParse(_vialAmountController.text.trim());

    final liquidVolume = double.tryParse(_liquidVolumeController.text.trim());

    final desiredDose = double.tryParse(_desiredDoseController.text.trim());

    if (vialAmount == null || vialAmount <= 0) {
      _showError('Enter a valid vial amount.');
      return;
    }

    if (liquidVolume == null || liquidVolume <= 0) {
      _showError('Enter a valid liquid volume.');
      return;
    }

    if (desiredDose == null || desiredDose <= 0) {
      _showError('Enter a valid desired dose.');
      return;
    }

    final vialAmountInMcg = _toMcg(vialAmount, _vialUnit);

    final desiredDoseInMcg = _toMcg(desiredDose, _doseUnit);

    if (desiredDoseInMcg > vialAmountInMcg) {
      _showError(
        'The desired dose cannot be larger than the total vial amount.',
      );

      return;
    }

    final doseFraction = desiredDoseInMcg / vialAmountInMcg;
    final doseVolumeMl = liquidVolume * doseFraction;

    // All supported insulin syringes are U-100:
    // 100 syringe units = 1 mL.
    final syringeUnits = doseVolumeMl * 100;

    final concentrationPerMl = vialAmountInMcg / liquidVolume;
    final dosesPerVial = vialAmountInMcg / desiredDoseInMcg;

    setState(() {
      _resultUnits = syringeUnits;
      _resultMilliliters = doseVolumeMl;
      _concentrationPerMl = concentrationPerMl;
      _dosesPerVial = dosesPerVial;
      _errorMessage = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _resultUnits = null;
      _resultMilliliters = null;
      _concentrationPerMl = null;
      _dosesPerVial = null;
      _errorMessage = message;
    });
  }

  void _clear() {
    FocusScope.of(context).unfocus();

    setState(() {
      _vialAmountController.clear();
      _liquidVolumeController.clear();
      _desiredDoseController.clear();

      _vialUnit = 'mg';
      _doseUnit = 'mg';
      _selectedSyringeMl = 1.0;

      _resultUnits = null;
      _resultMilliliters = null;
      _concentrationPerMl = null;
      _dosesPerVial = null;
      _errorMessage = null;
    });
  }

  double _toMcg(double amount, String unit) {
    return switch (unit) {
      'mg' => amount * 1000,
      'mcg' => amount,
      _ => amount,
    };
  }

  String _formatNumber(double value, {int decimalPlaces = 3}) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(decimalPlaces)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String get _concentrationDisplay {
    final concentration = _concentrationPerMl;

    if (concentration == null) {
      return '';
    }

    if (concentration >= 1000) {
      return '${_formatNumber(concentration / 1000)} mg/mL';
    }

    return '${_formatNumber(concentration)} mcg/mL';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconstitution'),
        actions: [
          IconButton(
            onPressed: _clear,
            tooltip: 'Clear calculator',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Calculate syringe units',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter the vial amount, liquid added, and desired dose.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _AmountUnitField(
              controller: _vialAmountController,
              label: 'Vial amount',
              hint: '10',
              selectedUnit: _vialUnit,
              onUnitChanged: (value) {
                setState(() {
                  _vialUnit = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _liquidVolumeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Liquid added',
                hintText: '2',
                suffixText: 'mL',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _AmountUnitField(
              controller: _desiredDoseController,
              label: 'Desired dose',
              hint: '3',
              selectedUnit: _doseUnit,
              onUnitChanged: (value) {
                setState(() {
                  _doseUnit = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calculate'),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_resultUnits != null) ...[
              const SizedBox(height: AppSpacing.lg),

              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    Text(
                      'Draw',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_formatNumber(_resultUnits!)} units',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_formatNumber(_resultMilliliters!, decimalPlaces: 4)} mL',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SyringeScaleVisualization(
                      units: _resultUnits!,
                      syringeSizeMl: _selectedSyringeMl,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              _SyringeSizeSelector(
                selectedSizeMl: _selectedSyringeMl,
                onChanged: (value) {
                  setState(() {
                    _selectedSyringeMl = value;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    _ResultRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Volume per dose',
                      value:
                          '${_formatNumber(_resultMilliliters!, decimalPlaces: 4)} mL',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _ResultRow(
                      icon: Icons.science_outlined,
                      label: 'Concentration',
                      value: _concentrationDisplay,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _ResultRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Doses per vial',
                      value: _formatNumber(_dosesPerVial!, decimalPlaces: 2),
                    ),
                    const Divider(height: AppSpacing.lg),
                    _ResultRow(
                      icon: Icons.vaccines_outlined,
                      label: 'Selected syringe',
                      value: '${_formatNumber(_selectedSyringeMl)} mL U-100',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountUnitField extends StatelessWidget {
  const _AmountUnitField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedUnit,
            decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'mg', child: Text('mg')),
              DropdownMenuItem(value: 'mcg', child: Text('mcg')),
            ],
            onChanged: (value) {
              if (value != null) {
                onUnitChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _SyringeSizeSelector extends StatelessWidget {
  const _SyringeSizeSelector({
    required this.selectedSizeMl,
    required this.onChanged,
  });

  final double selectedSizeMl;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Syringe size',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SyringeSizeButton(
                  label: '1 mL',
                  isSelected: selectedSizeMl == 1.0,
                  onTap: () => onChanged(1.0),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SyringeSizeButton(
                  label: '0.5 mL',
                  isSelected: selectedSizeMl == 0.5,
                  onTap: () => onChanged(0.5),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SyringeSizeButton(
                  label: '0.3 mL',
                  isSelected: selectedSizeMl == 0.3,
                  onTap: () => onChanged(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyringeSizeButton extends StatelessWidget {
  const _SyringeSizeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w700,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SyringeScaleVisualization extends StatelessWidget {
  const SyringeScaleVisualization({
    required this.units,
    required this.syringeSizeMl,
    super.key,
  });

  final double units;
  final double syringeSizeMl;

  double get maximumUnits {
    if (syringeSizeMl == 0.3) {
      return 30;
    }

    if (syringeSizeMl == 0.5) {
      return 50;
    }

    return 100;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final exceedsCapacity = units > maximumUnits;

    return Column(
      children: [
        Text(
          exceedsCapacity
              ? '${_formatUnits(units)} units exceeds this syringe'
              : 'Fill to the ${_formatUnits(units)} unit line',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w700,
            color: exceedsCapacity
                ? colorScheme.error
                : colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 92,
          child: CustomPaint(
            painter: _SyringeScalePainter(
              units: units,
              maximumUnits: maximumUnits,
              outlineColor: exceedsCapacity
                  ? colorScheme.error
                  : colorScheme.onPrimaryContainer,
              liquidColor: exceedsCapacity
                  ? colorScheme.error
                  : colorScheme.primary,
              emptyColor: colorScheme.surface.withValues(alpha: 0.45),
              errorColor: colorScheme.error,
            ),
          ),
        ),

        if (exceedsCapacity) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select a larger syringe. '
            '${_formatUnits(units)} units requires at least '
            '${_requiredSyringeSize(units)}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  String _requiredSyringeSize(double value) {
    if (value <= 30) {
      return 'a 0.3 mL syringe';
    }

    if (value <= 50) {
      return 'a 0.5 mL syringe';
    }

    if (value <= 100) {
      return 'a 1 mL syringe';
    }

    return 'more than one 1 mL syringe';
  }

  String _formatUnits(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }
}

class _SyringeScalePainter extends CustomPainter {
  const _SyringeScalePainter({
    required this.units,
    required this.maximumUnits,
    required this.outlineColor,
    required this.liquidColor,
    required this.emptyColor,
    required this.errorColor,
  });

  final double units;
  final double maximumUnits;

  final Color outlineColor;
  final Color liquidColor;
  final Color emptyColor;
  final Color errorColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    final right = size.width - 8;

    const top = 8.0;
    const bottom = 54.0;

    final width = right - left;
    final height = bottom - top;

    final scaleRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(7),
    );

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      scaleRect,
      Paint()
        ..color = emptyColor
        ..style = PaintingStyle.fill,
    );

    final visibleUnits = units.clamp(0, maximumUnits).toDouble();

    final fillFraction = visibleUnits / maximumUnits;

    if (fillFraction > 0) {
      canvas.save();
      canvas.clipRRect(scaleRect);

      canvas.drawRect(
        Rect.fromLTWH(left, top, width * fillFraction, height),
        Paint()
          ..color = liquidColor.withValues(alpha: 0.60)
          ..style = PaintingStyle.fill,
      );

      canvas.restore();
    }

    canvas.drawRRect(scaleRect, outlinePaint);

    final minorIncrement = maximumUnits == 100 ? 2 : 1;

    final majorIncrement = maximumUnits == 30 ? 5 : 10;

    for (var mark = 0; mark <= maximumUnits.round(); mark += minorIncrement) {
      final x = left + width * (mark / maximumUnits);

      final isMajor = mark % majorIncrement == 0;

      final tickLength = isMajor ? 16.0 : 8.0;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + tickLength),
        Paint()
          ..color = outlineColor.withValues(alpha: isMajor ? 0.95 : 0.55)
          ..strokeWidth = isMajor ? 1.5 : 1,
      );
    }

    for (var label = 0; label <= maximumUnits.round(); label += 10) {
      final x = left + width * (label / maximumUnits);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.toString(),
          style: TextStyle(
            color: outlineColor.withValues(alpha: 0.85),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = (x - textPainter.width / 2).clamp(
        0.0,
        size.width - textPainter.width,
      );

      textPainter.paint(canvas, Offset(labelX, bottom + 8));
    }

    final resultX = left + width * fillFraction;
    final exceedsCapacity = units > maximumUnits;

    canvas.drawLine(
      Offset(resultX, top - 5),
      Offset(resultX, bottom + 4),
      Paint()
        ..color = exceedsCapacity ? errorColor : outlineColor
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _SyringeScalePainter oldDelegate) {
    return units != oldDelegate.units ||
        maximumUnits != oldDelegate.maximumUnits ||
        outlineColor != oldDelegate.outlineColor ||
        liquidColor != oldDelegate.liquidColor ||
        emptyColor != oldDelegate.emptyColor ||
        errorColor != oldDelegate.errorColor;
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Icon(icon, size: AppIcon.sm, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.body,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

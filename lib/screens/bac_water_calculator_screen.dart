import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class BacWaterCalculatorScreen extends StatefulWidget {
  const BacWaterCalculatorScreen({super.key});

  @override
  State<BacWaterCalculatorScreen> createState() =>
      _BacWaterCalculatorScreenState();
}

class _BacWaterCalculatorScreenState extends State<BacWaterCalculatorScreen> {
  final TextEditingController _vialAmountController = TextEditingController();

  final TextEditingController _desiredDoseController = TextEditingController();

  String _vialUnit = 'mg';
  String _doseUnit = 'mg';

  double _targetUnits = 20;

  double? _resultBacMl;
  double? _doseVolumeMl;
  double? _concentrationMcgPerMl;
  double? _dosesPerVial;
  double? _calculatedUnits;

  String? _errorMessage;
  String? _warningMessage;

  @override
  void dispose() {
    _vialAmountController.dispose();
    _desiredDoseController.dispose();

    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();

    final vialAmount = double.tryParse(_vialAmountController.text.trim());

    final desiredDose = double.tryParse(_desiredDoseController.text.trim());

    if (vialAmount == null || vialAmount <= 0) {
      _showError('Enter a valid vial amount.');
      return;
    }

    if (desiredDose == null || desiredDose <= 0) {
      _showError('Enter a valid desired dose.');
      return;
    }

    final vialAmountMcg = _toMcg(vialAmount, _vialUnit);

    final desiredDoseMcg = _toMcg(desiredDose, _doseUnit);

    if (_targetUnits <= 0) {
      _showError('Target units must be greater than zero.');
      return;
    }

    if (desiredDoseMcg > vialAmountMcg) {
      _showError('The desired dose cannot exceed the total vial amount.');
      return;
    }

    final doseVolumeMl = _targetUnits / 100;
    final dosesPerVial = vialAmountMcg / desiredDoseMcg;
    final bacMl = dosesPerVial * doseVolumeMl;
    final concentrationMcgPerMl = vialAmountMcg / bacMl;

    String? warning;

    if (bacMl < 0.25) {
      warning =
          'Very concentrated mixture. Small measuring errors may have a larger effect.';
    } else if (bacMl > 5) {
      warning =
          'Large liquid volume. Verify that the vial can physically hold this amount.';
    }

    setState(() {
      _resultBacMl = bacMl;
      _doseVolumeMl = doseVolumeMl;
      _concentrationMcgPerMl = concentrationMcgPerMl;
      _dosesPerVial = dosesPerVial;
      _calculatedUnits = _targetUnits;

      _errorMessage = null;
      _warningMessage = warning;
    });
  }

  void _showError(String message) {
    setState(() {
      _resultBacMl = null;
      _doseVolumeMl = null;
      _concentrationMcgPerMl = null;
      _dosesPerVial = null;
      _calculatedUnits = null;

      _warningMessage = null;
      _errorMessage = message;
    });
  }

  void _clear() {
    FocusScope.of(context).unfocus();

    setState(() {
      _vialAmountController.clear();
      _desiredDoseController.clear();

      _vialUnit = 'mg';
      _doseUnit = 'mg';
      _targetUnits = 20;

      _resultBacMl = null;
      _doseVolumeMl = null;
      _concentrationMcgPerMl = null;
      _dosesPerVial = null;
      _calculatedUnits = null;

      _errorMessage = null;
      _warningMessage = null;
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
    final concentration = _concentrationMcgPerMl;

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
        title: const Text('BAC Water'),
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
              'Calculate BAC water',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose the dose and syringe line you want, then Ghost will calculate the liquid volume.',
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

            _AmountUnitField(
              controller: _desiredDoseController,
              label: 'Desired dose',
              hint: '2',
              selectedUnit: _doseUnit,
              onUnitChanged: (value) {
                setState(() {
                  _doseUnit = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.md),

            _TargetUnitsSelector(
              value: _targetUnits,
              onChanged: (value) {
                setState(() {
                  _targetUnits = value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.md),

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
              _MessageCard(
                icon: Icons.error_outline,
                message: _errorMessage!,
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
            ],

            if (_resultBacMl != null) ...[
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
                      'Add',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_formatNumber(_resultBacMl!, decimalPlaces: 4)} mL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'BAC water',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              if (_warningMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _MessageCard(
                  icon: Icons.warning_amber_outlined,
                  message: _warningMessage!,
                  backgroundColor: colorScheme.tertiaryContainer,
                  foregroundColor: colorScheme.onTertiaryContainer,
                ),
              ],

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
                      icon: Icons.vaccines_outlined,
                      label: 'Each dose',
                      value: '${_formatNumber(_calculatedUnits!)} units',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _ResultRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Dose volume',
                      value:
                          '${_formatNumber(_doseVolumeMl!, decimalPlaces: 4)} mL',
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
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppIcon.sm,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'The syringe-line calculation uses a U-100 scale, where 100 units equals 1 mL.',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
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

class _TargetUnitsSelector extends StatefulWidget {
  const _TargetUnitsSelector({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_TargetUnitsSelector> createState() => _TargetUnitsSelectorState();
}

class _TargetUnitsSelectorState extends State<_TargetUnitsSelector> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.value.round().toString());

    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _TargetUnitsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value.round().toString();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _finishEditing();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.value.round().toString();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _focusNode.requestFocus();

      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _handleTypedValue(String value) {
    final parsed = int.tryParse(value.trim());

    if (parsed == null || parsed < 0 || parsed > 100) {
      return;
    }

    widget.onChanged(parsed.toDouble());
  }

  void _finishEditing() {
    if (!_isEditing) return;

    final entered = int.tryParse(_controller.text.trim());
    final fallback = widget.value.round();

    final value = (entered ?? fallback).clamp(0, 100).toDouble();

    widget.onChanged(value);

    if (!mounted) return;

    setState(() {
      _isEditing = false;
      _controller.text = value.round().toString();
    });
  }

  void _updateFromPosition(double position, double width) {
    const horizontalInset = 14.0;

    final usableWidth = width - (horizontalInset * 2);

    if (usableWidth <= 0) return;

    final normalized = ((position - horizontalInset) / usableWidth).clamp(
      0.0,
      1.0,
    );

    final units = (normalized * 100).roundToDouble();

    _controller.text = units.round().toString();
    widget.onChanged(units);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target units',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  _updateFromPosition(
                    details.localPosition.dx,
                    constraints.maxWidth,
                  );
                },
                onHorizontalDragStart: (details) {
                  _updateFromPosition(
                    details.localPosition.dx,
                    constraints.maxWidth,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  _updateFromPosition(
                    details.localPosition.dx,
                    constraints.maxWidth,
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: CustomPaint(
                    painter: _TargetUnitsPainter(
                      value: widget.value,
                      primaryColor: colorScheme.primary,
                      outlineColor: colorScheme.onSurfaceVariant,
                      fillColor: colorScheme.primary.withValues(alpha: 0.22),
                      emptyColor: colorScheme.surface,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _isEditing
                  ? SizedBox(
                      key: const ValueKey('unit-editor'),
                      width: 150,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onChanged: _handleTypedValue,
                        onSubmitted: (_) => _finishEditing(),
                        decoration: InputDecoration(
                          suffixText: 'units',
                          isDense: true,
                          filled: true,
                          fillColor: colorScheme.primary.withValues(
                            alpha: 0.10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Material(
                      key: const ValueKey('unit-pill'),
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _startEditing,
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colorScheme.primary.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.value.round().toString(),
                                style: TextStyle(
                                  fontSize: AppTypography.body,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Container(
                                height: 20,
                                width: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                color: colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                              Text(
                                'units',
                                style: TextStyle(
                                  fontSize: AppTypography.body,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Center(
            child: Text(
              'Tap the value to edit or drag the marker',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetUnitsPainter extends CustomPainter {
  const _TargetUnitsPainter({
    required this.value,
    required this.primaryColor,
    required this.outlineColor,
    required this.fillColor,
    required this.emptyColor,
  });

  final double value;
  final Color primaryColor;
  final Color outlineColor;
  final Color fillColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 14.0;
    final right = size.width - 14;

    const top = 30.0;
    const bottom = 104.0;

    final width = right - left;

    final rulerRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(12),
    );

    canvas.drawRRect(
      rulerRect,
      Paint()
        ..color = emptyColor
        ..style = PaintingStyle.fill,
    );

    final normalized = (value / 100).clamp(0.0, 1.0);
    final fillX = left + (width * normalized);

    canvas.save();
    canvas.clipRRect(rulerRect);

    canvas.drawRect(
      Rect.fromLTRB(left, top, fillX, bottom),
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    canvas.restore();

    canvas.drawRRect(
      rulerRect,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );

    // Skip 0 and 100 ticks because the outer border already marks them.
    for (var mark = 1; mark < 100; mark++) {
      final x = left + (width * mark / 100);

      final isMajor = mark % 10 == 0;
      final isMid = mark % 5 == 0;

      final tickLength = isMajor
          ? 28.0
          : isMid
          ? 20.0
          : 12.0;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + tickLength),
        Paint()
          ..color = outlineColor.withValues(
            alpha: isMajor
                ? 0.95
                : isMid
                ? 0.72
                : 0.42,
          )
          ..strokeWidth = isMajor ? 1.8 : 1,
      );
    }

    for (var label = 0; label <= 100; label += 10) {
      final x = left + (width * label / 100);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.toString(),
          style: TextStyle(
            color: outlineColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double labelX;

      if (label == 0) {
        labelX = left;
      } else if (label == 100) {
        labelX = right - textPainter.width;
      } else {
        labelX = x - (textPainter.width / 2);
      }

      textPainter.paint(canvas, Offset(labelX, bottom + 9));
    }

    // Keep the marker completely inside the drawable area.
    final markerX = fillX;

    final markerPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(markerX, top - 18),
      Offset(markerX, bottom + 8),
      markerPaint,
    );

    final arrowPath = Path()
      ..moveTo(markerX - 9, top - 21)
      ..lineTo(markerX + 9, top - 21)
      ..lineTo(markerX, top - 7)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(markerX, bottom + 9),
      6,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TargetUnitsPainter oldDelegate) {
    return value != oldDelegate.value ||
        primaryColor != oldDelegate.primaryColor ||
        outlineColor != oldDelegate.outlineColor ||
        fillColor != oldDelegate.fillColor ||
        emptyColor != oldDelegate.emptyColor;
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/protocol_colors.dart';

class AppColorPicker extends StatelessWidget {
  const AppColorPicker({
    required this.selectedColorValue,
    required this.onColorChanged,
    this.allowDefault = false,
    super.key,
  });

  final int? selectedColorValue;
  final ValueChanged<int?> onColorChanged;
  final bool allowDefault;

  Future<void> _openCustomPicker(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;

    final initialColor = selectedColorValue == null
        ? colors.primary
        : Color(selectedColorValue!);

    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (_) => _CustomColorDialog(initialColor: initialColor),
    );

    if (selectedColor != null) {
      onColorChanged(selectedColor.toARGB32());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final presetValues = ProtocolColors.available;

    final isCustomColor =
        selectedColorValue != null &&
        !presetValues.contains(selectedColorValue);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (allowDefault)
          _ColorChoice(
            color: colors.primaryContainer,
            selected: selectedColorValue == null,
            label: 'Default color',
            checkColor: colors.onPrimaryContainer,
            onTap: () => onColorChanged(null),
          ),
        for (final colorValue in presetValues)
          _ColorChoice(
            color: Color(colorValue),
            selected: selectedColorValue == colorValue,
            label: 'Select preset color',
            onTap: () => onColorChanged(colorValue),
          ),
        _CustomColorChoice(
          color: isCustomColor ? Color(selectedColorValue!) : null,
          selected: isCustomColor,
          onTap: () => _openCustomPicker(context),
        ),
      ],
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
    this.checkColor = Colors.white,
  });

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected
                ? Icon(Icons.check_rounded, color: checkColor, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}

class _CustomColorChoice extends StatelessWidget {
  const _CustomColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Choose custom color',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.onSurface : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : Icon(
                    Icons.add_rounded,
                    color: colors.onSurfaceVariant,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  Color get _selectedColor => _hsv.toColor();

  void _updateSaturationValue(Offset position, Size size) {
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final value = (1.0 - (position.dy / size.height)).clamp(0.0, 1.0);

    setState(() {
      _hsv = _hsv.withSaturation(saturation).withValue(value);
    });
  }

  void _updateHue(double hue) {
    setState(() {
      _hsv = _hsv.withHue(hue.clamp(0.0, 360.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = math.min(mediaWidth - 32, 380.0);
    final pickerWidth = dialogWidth - (AppSpacing.lg * 2);
    final pickerHeight = pickerWidth / 1.65;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Custom Color',
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SaturationValueArea(
                hsv: _hsv,
                width: pickerWidth,
                height: pickerHeight,
                onChanged: _updateSaturationValue,
              ),
              const SizedBox(height: AppSpacing.md),
              _HueSlider(
                hue: _hsv.hue,
                width: pickerWidth,
                onChanged: _updateHue,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected color',
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _toHex(_selectedColor),
                          style: TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selectedColor),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(118, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Save Color',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaturationValueArea extends StatelessWidget {
  const _SaturationValueArea({
    required this.hsv,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  final HSVColor hsv;
  final double width;
  final double height;
  final void Function(Offset position, Size size) onChanged;

  @override
  Widget build(BuildContext context) {
    final size = Size(width, height);

    void handle(Offset localPosition) {
      onChanged(
        Offset(
          localPosition.dx.clamp(0.0, size.width),
          localPosition.dy.clamp(0.0, size.height),
        ),
        size,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => handle(details.localPosition),
        onPanStart: (details) => handle(details.localPosition),
        onPanUpdate: (details) => handle(details.localPosition),
        child: CustomPaint(
          painter: _SaturationValuePainter(hsv: hsv),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({required this.hsv});

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(AppRadius.button);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, radius));

    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    canvas.drawRect(rect, Paint()..color = hueColor);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    canvas.restore();

    final selector = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );

    canvas.drawCircle(
      selector,
      10,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    canvas.drawCircle(
      selector,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hue,
    required this.width,
    required this.onChanged,
  });

  final double hue;
  final double width;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    void handle(double dx) {
      final normalized = (dx / width).clamp(0.0, 1.0);
      onChanged(normalized * 360);
    }

    return SizedBox(
      width: width,
      height: 30,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => handle(details.localPosition.dx),
        onPanStart: (details) => handle(details.localPosition.dx),
        onPanUpdate: (details) => handle(details.localPosition.dx),
        child: CustomPaint(
          painter: _HuePainter(hue: hue),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HuePainter extends CustomPainter {
  const _HuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final barRect = Rect.fromLTWH(0, (size.height - 12) / 2, size.width, 12);

    final barRRect = RRect.fromRectAndRadius(barRect, const Radius.circular(6));

    final colors = <Color>[
      for (var i = 0; i <= 6; i++)
        HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
    ];

    canvas.drawRRect(
      barRRect,
      Paint()..shader = LinearGradient(colors: colors).createShader(barRect),
    );

    final x = (hue / 360) * size.width;
    final center = Offset(
      math.min(math.max(x, 9), size.width - 9),
      size.height / 2,
    );

    final selectedHue = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    canvas.drawCircle(center, 9, Paint()..color = Colors.white);

    canvas.drawCircle(center, 7, Paint()..color = selectedHue);

    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

String _toHex(Color color) {
  final value = color.toARGB32() & 0x00FFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

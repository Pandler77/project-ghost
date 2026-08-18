import 'package:flex_color_picker/flex_color_picker.dart';
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

    final selectedColor = await showColorPickerDialog(
      context,
      initialColor,
      title: Text(
        'Choose Custom Color',
        style: TextStyle(
          fontSize: AppTypography.body,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.wheel: true,
      },
      showColorCode: true,
      colorCodeHasColor: true,
      colorCodeReadOnly: false,
      showRecentColors: false,
      enableShadesSelection: false,
      enableOpacity: false,
      actionButtons: ColorPickerActionButtons(
        okButton: false,
        closeButton: false,
        dialogActionButtons: true,
        dialogActionOnlyOkButton: false,
        dialogActionIcons: false,
        dialogCancelButtonLabel: 'Cancel',
        dialogOkButtonLabel: 'Save Color',
        dialogCancelButtonType: ColorPickerActionButtonType.text,
        dialogOkButtonType: ColorPickerActionButtonType.elevated,
        dialogOkButtonStyle: FilledButton.styleFrom(
          minimumSize: const Size(118, 46),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    onColorChanged(selectedColor.toARGB32());
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
            onTap: () {
              onColorChanged(null);
            },
          ),

        for (final colorValue in presetValues)
          _ColorChoice(
            color: Color(colorValue),
            selected: selectedColorValue == colorValue,
            label: 'Select preset color',
            onTap: () {
              onColorChanged(colorValue);
            },
          ),

        _CustomColorChoice(
          color: isCustomColor ? Color(selectedColorValue!) : null,
          selected: isCustomColor,
          onTap: () {
            _openCustomPicker(context);
          },
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
                ? Icon(Icons.check, color: checkColor, size: 20)
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
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Icon(Icons.add, color: colors.onSurfaceVariant, size: 22),
          ),
        ),
      ),
    );
  }
}

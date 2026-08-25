import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    required this.value,
    required this.values,
    required this.label,
    required this.labelBuilder,
    required this.onChanged,
    this.placeholder,
    this.prefixIcon,
    this.optionBuilder,
    super.key,
  });

  final T? value;
  final List<T> values;
  final String label;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;
  final String? placeholder;
  final Widget? prefixIcon;
  final Widget Function(BuildContext context, T value, bool isSelected)?
      optionBuilder;

  Future<void> _showPicker(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final colors = Theme.of(context).colorScheme;
    final selected = await showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.62,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: values.length,
                  itemBuilder: (context, index) {
                    final item = values[index];
                    final isSelected = item == value;

                    return ListTile(
                      title: optionBuilder?.call(
                            context,
                            item,
                            isSelected,
                          ) ??
                          Text(labelBuilder(item)),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: colors.primary)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedValue = value;
    final displayText = selectedValue == null
        ? (placeholder ?? 'Select')
        : labelBuilder(selectedValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: values.isEmpty ? null : () => _showPicker(context),
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: prefixIcon,
            border: const OutlineInputBorder(),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    color: selectedValue == null
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

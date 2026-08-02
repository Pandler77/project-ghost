import 'package:flutter/material.dart';

import '../../models/cycle_unit.dart';
import '../../theme/app_theme.dart';

class ProtocolCycleEditor extends StatelessWidget {
  const ProtocolCycleEditor({
    required this.useCycle,
    required this.cycleStartDate,
    required this.onDurationController,
    required this.onUnit,
    required this.offDurationController,
    required this.offUnit,
    required this.repeatCycle,
    required this.onUseCycleChanged,
    required this.onCycleStartDateChanged,
    required this.onOnUnitChanged,
    required this.onOffUnitChanged,
    required this.onRepeatCycleChanged,
    required this.onValuesChanged,
    super.key,
  });

  final bool useCycle;
  final DateTime cycleStartDate;

  final TextEditingController onDurationController;
  final CycleUnit onUnit;

  final TextEditingController offDurationController;
  final CycleUnit offUnit;

  final bool repeatCycle;

  final ValueChanged<bool> onUseCycleChanged;
  final ValueChanged<DateTime> onCycleStartDateChanged;
  final ValueChanged<CycleUnit> onOnUnitChanged;
  final ValueChanged<CycleUnit> onOffUnitChanged;
  final ValueChanged<bool> onRepeatCycleChanged;
  final VoidCallback onValuesChanged;

  Future<void> _chooseCycleStartDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: cycleStartDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );

    if (selected == null) {
      return;
    }

    onCycleStartDateChanged(
      DateTime(selected.year, selected.month, selected.day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Will you be cycling?',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose whether this protocol runs continuously or uses planned on and off periods.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _CycleModeTile(
          title: 'No',
          subtitle: 'Run continuously on its normal schedule.',
          icon: Icons.all_inclusive,
          isSelected: !useCycle,
          onTap: () {
            onUseCycleChanged(false);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _CycleModeTile(
          title: 'Yes',
          subtitle: 'Run during planned on-cycle periods.',
          icon: Icons.event_repeat_outlined,
          isSelected: useCycle,
          onTap: () {
            onUseCycleChanged(true);
          },
        ),
        if (useCycle) ...[
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Cycle start date'),
          const SizedBox(height: AppSpacing.sm),
          _DateTile(
            date: cycleStartDate,
            onTap: () {
              _chooseCycleStartDate(context);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _DurationCard(
            title: 'On cycle',
            subtitle: 'How long the protocol remains active.',
            controller: onDurationController,
            selectedUnit: onUnit,
            allowZero: false,
            onUnitChanged: onOnUnitChanged,
            onChanged: onValuesChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _DurationCard(
            title: 'Off cycle',
            subtitle: 'How long the protocol remains inactive.',
            controller: offDurationController,
            selectedUnit: offUnit,
            allowZero: true,
            onUnitChanged: onOffUnitChanged,
            onChanged: onValuesChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: const Icon(Icons.repeat),
              title: const Text(
                'Repeat cycle',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Begin another on-cycle period after the off period.',
              ),
              value: repeatCycle,
              onChanged: onRepeatCycleChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CyclePreview(
            startDate: cycleStartDate,
            onDuration: int.tryParse(onDurationController.text.trim()),
            onUnit: onUnit,
            offDuration: int.tryParse(offDurationController.text.trim()),
            offUnit: offUnit,
            repeatCycle: repeatCycle,
          ),
        ],
      ],
    );
  }
}

class _CycleModeTile extends StatelessWidget {
  const _CycleModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.selectedUnit,
    required this.allowZero,
    required this.onUnitChanged,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final CycleUnit selectedUnit;
  final bool allowZero;
  final ValueChanged<CycleUnit> onUnitChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      hintText: allowZero ? '0' : '1',
                      helperText: allowZero
                          ? 'Enter 0 for no off period.'
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<CycleUnit>(
                    initialValue: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final unit in CycleUnit.values)
                        DropdownMenuItem(value: unit, child: Text(unit.label)),
                    ],
                    onChanged: (unit) {
                      if (unit != null) {
                        onUnitChanged(unit);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyclePreview extends StatelessWidget {
  const _CyclePreview({
    required this.startDate,
    required this.onDuration,
    required this.onUnit,
    required this.offDuration,
    required this.offUnit,
    required this.repeatCycle,
  });

  final DateTime startDate;
  final int? onDuration;
  final CycleUnit onUnit;
  final int? offDuration;
  final CycleUnit offUnit;
  final bool repeatCycle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final validOnDuration = onDuration != null && onDuration! > 0;

    final validOffDuration = offDuration != null && offDuration! >= 0;

    final summary = validOnDuration && validOffDuration
        ? _buildSummary()
        : 'Enter valid durations to preview the cycle.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_repeat_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cycle preview',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary,
                  style: TextStyle(
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSummary() {
    final onText = _durationLabel(onDuration!, onUnit);

    if (!repeatCycle) {
      final endDate = _addDuration(
        startDate,
        onDuration!,
        onUnit,
      ).subtract(const Duration(days: 1));

      return '$onText on, beginning '
          '${_formatDate(startDate)}.\n'
          'Ends ${_formatDate(endDate)}.';
    }

    final offText = _durationLabel(offDuration!, offUnit);

    final onEndExclusive = _addDuration(startDate, onDuration!, onUnit);

    final offEndExclusive = _addDuration(onEndExclusive, offDuration!, offUnit);

    if (offDuration == 0) {
      return '$onText on with no off period.\n'
          'Repeats continuously.';
    }

    return '$onText on, then $offText off.\n'
        'First on period ends '
        '${_formatDate(onEndExclusive.subtract(const Duration(days: 1)))}.\n'
        'Next on period begins '
        '${_formatDate(offEndExclusive)}.';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppTypography.body,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

DateTime _addDuration(DateTime start, int amount, CycleUnit unit) {
  return switch (unit) {
    CycleUnit.days => start.add(Duration(days: amount)),
    CycleUnit.weeks => start.add(Duration(days: amount * 7)),
    CycleUnit.months => DateTime(start.year, start.month + amount, start.day),
  };
}

String _durationLabel(int amount, CycleUnit unit) {
  final label = amount == 1 ? unit.singularLabel : unit.label;

  return '$amount ${label.toLowerCase()}';
}

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} '
      '${date.day}, ${date.year}';
}

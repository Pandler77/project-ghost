import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../theme/app_theme.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late bool? _reminderEnabled;
  late int _minutesBefore;
  late bool? _followUpEnabled;
  late int _minutesAfter;

  @override
  void initState() {
    super.initState();
    _reminderEnabled = widget.protocol.reminderEnabled;
    _minutesBefore = widget.protocol.reminderMinutesBefore;
    _followUpEnabled = widget.protocol.missedDoseReminderEnabled;
    _minutesAfter = widget.protocol.missedDoseReminderMinutesAfter;
  }

  void _save() {
    Navigator.pop(
      context,
      widget.protocol.copyWith(
        reminderEnabled: _reminderEnabled == true,
        reminderMinutesBefore: _reminderEnabled == true ? _minutesBefore : 0,
        missedDoseReminderEnabled:
            _reminderEnabled == true && _followUpEnabled == true,
        missedDoseReminderMinutesAfter: _followUpEnabled == true
            ? _minutesAfter
            : 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dose Reminder')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Dose reminders',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Would you like to receive reminders for this protocol?',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _BinaryRow(
              yesSelected: _reminderEnabled == true,
              noSelected: _reminderEnabled == false,
              onYes: () => setState(() => _reminderEnabled = true),
              onNo: () {
                setState(() {
                  _reminderEnabled = false;
                  _followUpEnabled = false;
                });
              },
            ),
            if (_reminderEnabled == true) ...[
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Notify me',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceWrap(
                values: const [0, 5, 10, 15, 30, 60],
                selectedValue: _minutesBefore,
                labelBuilder: (value) => switch (value) {
                  0 => 'At time',
                  60 => '1h before',
                  _ => '${value}m before',
                },
                onSelected: (value) {
                  setState(() => _minutesBefore = value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Follow-up Reminder',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "If this dose isn't marked as taken, would you like another reminder?",
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _BinaryRow(
                yesSelected: _followUpEnabled == true,
                noSelected: _followUpEnabled == false,
                onYes: () => setState(() => _followUpEnabled = true),
                onNo: () => setState(() => _followUpEnabled = false),
              ),
              if (_followUpEnabled == true) ...[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'When should Ghost remind you again?',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ChoiceWrap(
                  values: const [15, 30, 60, 120],
                  selectedValue: _minutesAfter,
                  labelBuilder: (value) => switch (value) {
                    60 => '1h later',
                    120 => '2h later',
                    _ => '${value}m later',
                  },
                  onSelected: (value) {
                    setState(() => _minutesAfter = value);
                  },
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _reminderEnabled == null ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BinaryRow extends StatelessWidget {
  const _BinaryRow({
    required this.yesSelected,
    required this.noSelected,
    required this.onYes,
    required this.onNo,
  });

  final bool yesSelected;
  final bool noSelected;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BinaryChoiceTile(
            label: 'Yes',
            isSelected: yesSelected,
            onTap: onYes,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _BinaryChoiceTile(
            label: 'No',
            isSelected: noSelected,
            onTap: onNo,
          ),
        ),
      ],
    );
  }
}

class _BinaryChoiceTile extends StatelessWidget {
  const _BinaryChoiceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.10)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.check_circle,
                  size: AppIcon.sm,
                  color: colors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<int> values;
  final int selectedValue;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(labelBuilder(value)),
            selected: selectedValue == value,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}

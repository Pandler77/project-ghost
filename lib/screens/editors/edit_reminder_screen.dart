import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final SettingsService _settingsService = SettingsService();

  late bool? _reminderEnabled;
  late int _minutesBefore;
  late bool? _followUpEnabled;
  late int _minutesAfter;

  late final TextEditingController _customBodyController;
  late final TextEditingController _customFollowUpBodyController;

  bool _customNotificationTextEnabled = false;

  @override
  void initState() {
    super.initState();

    _reminderEnabled = widget.protocol.reminderEnabled;
    _minutesBefore = widget.protocol.reminderMinutesBefore;
    _followUpEnabled = widget.protocol.missedDoseReminderEnabled;
    _minutesAfter = widget.protocol.missedDoseReminderMinutesAfter;

    _customBodyController = TextEditingController(
      text: widget.protocol.customReminderBody ?? '',
    );
    _customFollowUpBodyController = TextEditingController(
      text: widget.protocol.customFollowUpBody ?? '',
    );

    _loadCustomNotificationPreference();
  }

  @override
  void dispose() {
    _customBodyController.dispose();
    _customFollowUpBodyController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomNotificationPreference() async {
    final preferences = await _settingsService.getNotificationPreferences();

    if (!mounted) {
      return;
    }

    setState(() {
      _customNotificationTextEnabled =
          preferences.customNotificationTextEnabled;
    });
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
        customReminderTitle: null,
        customReminderBody: _optionalText(_customBodyController.text),
        customFollowUpTitle: null,
        customFollowUpBody: _optionalText(_customFollowUpBodyController.text),
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
              _ReminderTimingDropdown(
                value: _minutesBefore,
                values: const [0, 5, 10, 15, 30, 60],
                label: 'Reminder timing',
                labelBuilder: _beforeLabel,
                onChanged: (value) {
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
                  'When should MODOSE remind you again?',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ReminderTimingDropdown(
                  value: _minutesAfter,
                  values: _followUpTimingValues,
                  label: 'Follow-up timing',
                  labelBuilder: _afterLabel,
                  onChanged: (value) {
                    setState(() => _minutesAfter = value);
                  },
                ),
              ],
              if (_customNotificationTextEnabled) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Main reminder message',
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Applies only to the main reminder. Leave blank to use “It\'s time for your protocol”.',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _customBodyController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 140,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Custom main reminder',
                    hintText: "It's time for your protocol",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_followUpEnabled == true) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Follow-up reminder message',
                    style: TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Applies only to the follow-up. Leave blank to use the MODOSE default.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _customFollowUpBodyController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 140,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Custom follow-up reminder',
                      hintText: "You haven't logged your protocol today.",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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

const List<int> _followUpTimingValues = [
  5,
  10,
  15,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
  60,
  120,
  180,
  240,
  300,
  360,
  420,
  480,
  540,
  600,
];

String _beforeLabel(int value) {
  if (value == 0) return 'At scheduled time';
  if (value == 60) return '1 hour before';
  return '$value minutes before';
}

String _afterLabel(int value) {
  if (value == 60) return '1 hour later';
  if (value > 60 && value % 60 == 0) {
    final hours = value ~/ 60;
    return '$hours hours later';
  }
  return '$value minutes later';
}

class _ReminderTimingDropdown extends StatelessWidget {
  const _ReminderTimingDropdown({
    required this.value,
    required this.values,
    required this.label,
    required this.labelBuilder,
    required this.onChanged,
  });

  final int value;
  final List<int> values;
  final String label;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = values.contains(value) ? value : values.first;

    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem<int>(value: item, child: Text(labelBuilder(item))),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

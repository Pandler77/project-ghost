import 'package:flutter/material.dart';

import '../models/display_preferences.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class DisplayPreferencesScreen extends StatefulWidget {
  const DisplayPreferencesScreen({required this.initialPreferences, super.key});

  final DisplayPreferences initialPreferences;

  @override
  State<DisplayPreferencesScreen> createState() =>
      _DisplayPreferencesScreenState();
}

class _DisplayPreferencesScreenState extends State<DisplayPreferencesScreen> {
  final SettingsService _settingsService = SettingsService();

  late DisplayPreferences _preferences;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await _settingsService.saveDisplayPreferences(_preferences);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, _preferences);
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset display preferences?'),
          content: const Text(
            'This restores all display settings to their defaults.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _preferences = const DisplayPreferences();
    });

    await _settingsService.resetDisplayPreferences();
  }

  void _update(DisplayPreferences preferences) {
    setState(() {
      _preferences = preferences;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Preferences'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _SectionHeader(title: 'Dashboard'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Greeting'),
                    subtitle: const Text(
                      'Show the greeting at the top of Home.',
                    ),
                    value: _preferences.showGreeting,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showGreeting: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Progress bar'),
                    subtitle: const Text(
                      'Show daily dose completion progress.',
                    ),
                    value: _preferences.showProgressBar,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showProgressBar: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Completed doses'),
                    subtitle: const Text(
                      'Show completed-dose history on Home.',
                    ),
                    value: _preferences.showCompletedDoses,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showCompletedDoses: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Upcoming'),
                    subtitle: const Text('Show the upcoming-dose carousel.'),
                    value: _preferences.showUpcoming,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showUpcoming: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Weight'),
                    subtitle: const Text('Show the weight summary on Home.'),
                    value: _preferences.showWeight,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showWeight: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Recent activity'),
                    subtitle: const Text(
                      'Show recent dose and weight activity.',
                    ),
                    value: _preferences.showRecentActivity,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showRecentActivity: value));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionHeader(title: 'Cycle Display'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Cycle status'),
                    subtitle: const Text('Show the current cycle phase.'),
                    value: _preferences.showCycleStatus,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showCycleStatus: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('End date'),
                    subtitle: const Text(
                      'Show when the current active period ends.',
                    ),
                    value: _preferences.showCycleEndDate,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showCycleEndDate: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Remaining days'),
                    subtitle: const Text(
                      'Show the countdown for the current phase.',
                    ),
                    value: _preferences.showCycleRemainingDays,
                    onChanged: (value) {
                      _update(
                        _preferences.copyWith(showCycleRemainingDays: value),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Resume date'),
                    subtitle: const Text(
                      'Show when an off-cycle protocol resumes.',
                    ),
                    value: _preferences.showCycleResumeDate,
                    onChanged: (value) {
                      _update(
                        _preferences.copyWith(showCycleResumeDate: value),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionHeader(title: 'Protocol Cards'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Protocol colors'),
                    subtitle: const Text(
                      'Use each protocol color on cards and borders.',
                    ),
                    value: _preferences.showProtocolColors,
                    onChanged: (value) {
                      _update(_preferences.copyWith(showProtocolColors: value));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Compact mode'),
                    subtitle: const Text('Reduce card padding and spacing.'),
                    value: _preferences.compactMode,
                    onChanged: (value) {
                      _update(_preferences.copyWith(compactMode: value));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset Display Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppTypography.title,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

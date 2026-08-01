import 'package:flutter/material.dart';

import '../models/app_theme_mode.dart';
import '../models/tracking_preferences.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'tracking_preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  TrackingPreferences _trackingPreferences = TrackingPreferences.defaults;

  bool _isLoadingTrackingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadTrackingPreferences();
  }

  Future<void> _loadTrackingPreferences() async {
    final preferences = await _settingsService.getTrackingPreferences();

    if (!mounted) {
      return;
    }

    setState(() {
      _trackingPreferences = preferences;
      _isLoadingTrackingPreferences = false;
    });
  }

  Future<void> _openTrackingPreferences() async {
    if (_isLoadingTrackingPreferences) {
      return;
    }

    final updatedPreferences = await Navigator.push<TrackingPreferences>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrackingPreferencesScreen(initialPreferences: _trackingPreferences),
      ),
    );

    if (updatedPreferences == null || !mounted) {
      return;
    }

    await _settingsService.saveTrackingPreferences(updatedPreferences);

    if (!mounted) {
      return;
    }

    setState(() {
      _trackingPreferences = updatedPreferences;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tracking preferences saved.')),
    );
  }

  String _trackingSummary() {
    final enabled = <String>[];

    if (_trackingPreferences.trackWeight) {
      enabled.add('Weight');
    }

    if (_trackingPreferences.trackPhotos) {
      enabled.add('Photos');
    }

    if (_trackingPreferences.trackNotes) {
      enabled.add('Notes');
    }

    if (enabled.isEmpty) {
      return 'Protocols only';
    }

    return enabled.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _SettingsSectionHeader(title: 'Appearance'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: RadioGroup<AppThemeMode>(
                groupValue: widget.themeMode,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  widget.onThemeModeChanged(value);
                },
                child: const Column(
                  children: [
                    RadioListTile<AppThemeMode>(
                      value: AppThemeMode.system,
                      title: Text('System'),
                      subtitle: Text('Follow your device appearance.'),
                      secondary: Icon(Icons.brightness_auto_outlined),
                    ),
                    Divider(height: 1),
                    RadioListTile<AppThemeMode>(
                      value: AppThemeMode.light,
                      title: Text('Light'),
                      secondary: Icon(Icons.light_mode_outlined),
                    ),
                    Divider(height: 1),
                    RadioListTile<AppThemeMode>(
                      value: AppThemeMode.dark,
                      title: Text('Dark'),
                      secondary: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSectionHeader(title: 'Tracking'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: const Text('Tracking Preferences'),
                subtitle: Text(
                  _isLoadingTrackingPreferences
                      ? 'Loading preferences...'
                      : _trackingSummary(),
                ),
                trailing: _isLoadingTrackingPreferences
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isLoadingTrackingPreferences
                    ? null
                    : _openTrackingPreferences,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSectionHeader(title: 'Coming Soon'),
            const SizedBox(height: AppSpacing.sm),
            const Card(
              child: Column(
                children: [
                  _DisabledSettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage protocol and progress reminders.',
                  ),
                  Divider(height: 1),
                  _DisabledSettingsTile(
                    icon: Icons.storage_outlined,
                    title: 'Data & Backup',
                    subtitle: 'Manage backups, exports, and stored data.',
                  ),
                  Divider(height: 1),
                  _DisabledSettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version, support, and application information.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});

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

class _DisabledSettingsTile extends StatelessWidget {
  const _DisabledSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

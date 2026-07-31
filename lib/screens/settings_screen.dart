import 'package:flutter/material.dart';

import '../models/app_theme_mode.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

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
                groupValue: themeMode,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  onThemeModeChanged(value);
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

            const _SettingsSectionHeader(title: 'Coming Soon'),

            const SizedBox(height: AppSpacing.sm),

            const Card(
              child: Column(
                children: [
                  _DisabledSettingsTile(
                    icon: Icons.tune_outlined,
                    title: 'Tracking Preferences',
                    subtitle: 'Choose weight, photos, notes, and reminders.',
                  ),
                  Divider(height: 1),
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

import 'package:flutter/material.dart';

import '../models/app_theme_mode.dart';
import '../models/display_preferences.dart';
import '../models/tracking_preferences.dart';
import '../services/app_data_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'display_preferences_screen.dart';
import 'premium_screen.dart';
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

  final AppDataService _dataService = AppDataService();

  TrackingPreferences _trackingPreferences = TrackingPreferences.defaults;

  DisplayPreferences _displayPreferences = const DisplayPreferences();

  bool _isLoadingTrackingPreferences = true;
  bool _isLoadingDisplayPreferences = true;

  @override
  void initState() {
    super.initState();

    _loadTrackingPreferences();
    _loadDisplayPreferences();
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

  Future<void> _loadDisplayPreferences() async {
    final preferences = await _settingsService.getDisplayPreferences();

    if (!mounted) {
      return;
    }

    setState(() {
      _displayPreferences = preferences;
      _isLoadingDisplayPreferences = false;
    });
  }

  Future<void> _openPremium() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumScreen(dataService: _dataService),
      ),
    );
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

  Future<void> _openDisplayPreferences() async {
    if (_isLoadingDisplayPreferences) {
      return;
    }

    final updatedPreferences = await Navigator.push<DisplayPreferences>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DisplayPreferencesScreen(initialPreferences: _displayPreferences),
      ),
    );

    if (updatedPreferences == null || !mounted) {
      return;
    }

    await _settingsService.saveDisplayPreferences(updatedPreferences);

    if (!mounted) {
      return;
    }

    setState(() {
      _displayPreferences = updatedPreferences;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Display preferences saved.')));
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

  String _displaySummary() {
    final enabled = <String>[];

    if (_displayPreferences.showUpcoming) {
      enabled.add('Upcoming');
    }

    if (_displayPreferences.showWeight) {
      enabled.add('Weight');
    }

    if (_displayPreferences.showCycleStatus) {
      enabled.add('Cycles');
    }

    if (_displayPreferences.compactMode) {
      enabled.add('Compact');
    }

    if (enabled.isEmpty) {
      return 'Minimal display';
    }

    return enabled.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: _openPremium,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ghost Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppTypography.title,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Unlimited logging, Ghost Supply™, '
                                'weight analytics, profiles, and more.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: AppTypography.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

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

            const _SettingsSectionHeader(title: 'Preferences'),

            const SizedBox(height: AppSpacing.sm),

            Card(
              child: Column(
                children: [
                  ListTile(
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: const Text('Display Preferences'),
                    subtitle: Text(
                      _isLoadingDisplayPreferences
                          ? 'Loading preferences...'
                          : _displaySummary(),
                    ),
                    trailing: _isLoadingDisplayPreferences
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isLoadingDisplayPreferences
                        ? null
                        : _openDisplayPreferences,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SettingsSectionHeader(title: 'Coming Soon'),

            const SizedBox(height: AppSpacing.sm),

            Card(
              child: Column(
                children: [
                  const _DisabledSettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage protocol and progress reminders.',
                  ),
                  const Divider(height: 1),
                  const _DisabledSettingsTile(
                    icon: Icons.storage_outlined,
                    title: 'Data & Backup',
                    subtitle: 'Manage backups, exports, and stored data.',
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Test Notification'),
                    subtitle: const Text('Verify notification setup.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await NotificationService.instance.showTestNotification();
                    },
                  ),
                  const Divider(height: 1),
                  const _DisabledSettingsTile(
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

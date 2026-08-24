import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/app_theme_mode.dart';
import '../models/display_preferences.dart';
import '../models/measurement_system.dart';
import '../models/tracking_preferences.dart';
import '../services/usage_analytics_service.dart';
import '../services/app_data_service.dart';
import '../services/app_reset_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'about_modose_screen.dart';
import 'display_preferences_screen.dart';
import 'notification_settings_screen.dart';
import 'premium_screen.dart';
import 'privacy_screen.dart';
import 'terms_of_use_screen.dart';
import 'tracking_preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.measurementSystem,
    required this.onMeasurementSystemChanged,
    super.key,
  });

  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

  final MeasurementSystem measurementSystem;
  final ValueChanged<MeasurementSystem> onMeasurementSystemChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AppDataService _dataService = AppDataService();

  TrackingPreferences _trackingPreferences = TrackingPreferences.defaults;

  DisplayPreferences _displayPreferences = const DisplayPreferences();

  late MeasurementSystem _measurementSystem;

  bool _isLoadingTrackingPreferences = true;
  bool _isLoadingDisplayPreferences = true;
  bool _isLoadingMeasurementSystem = true;
  bool _isResettingAppData = false;

  bool _celebrationsEnabled = true;
  bool _isLoadingCelebrations = true;
  bool _isSavingCelebrations = false;

  bool _anonymousAnalyticsEnabled = true;
  bool _isLoadingAnonymousAnalytics = true;
  bool _isSavingAnonymousAnalytics = false;

  bool get _hasPremium => _dataService.hasPremium;

  @override
  void initState() {
    super.initState();

    _measurementSystem = widget.measurementSystem;

    _loadTrackingPreferences();
    _loadDisplayPreferences();
    _loadMeasurementSystem();
    _loadCelebrations();
    _loadAnonymousAnalytics();
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

  Future<void> _loadMeasurementSystem() async {
    final measurementSystem = await _settingsService.getMeasurementSystem();

    if (!mounted) {
      return;
    }

    setState(() {
      _measurementSystem = measurementSystem;
      _isLoadingMeasurementSystem = false;
    });
  }

  Future<void> _loadCelebrations() async {
    final enabled = await _settingsService.getCelebrationsEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _celebrationsEnabled = enabled;
      _isLoadingCelebrations = false;
    });
  }

  Future<void> _setCelebrationsEnabled(bool enabled) async {
    if (_isSavingCelebrations) {
      return;
    }

    setState(() {
      _isSavingCelebrations = true;
      _celebrationsEnabled = enabled;
    });

    try {
      await _settingsService.saveCelebrationsEnabled(enabled);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingCelebrations = false;
        });
      }
    }
  }

  Future<void> _loadAnonymousAnalytics() async {
    final enabled = await _settingsService.getAnonymousAnalyticsEnabled();

    if (!mounted) {
      return;
    }

    setState(() {
      _anonymousAnalyticsEnabled = enabled;
      _isLoadingAnonymousAnalytics = false;
    });
  }

  Future<void> _setAnonymousAnalyticsEnabled(bool enabled) async {
    if (_isSavingAnonymousAnalytics) {
      return;
    }

    setState(() {
      _isSavingAnonymousAnalytics = true;
      _anonymousAnalyticsEnabled = enabled;
    });

    try {
      await UsageAnalyticsService.instance.setEnabled(enabled);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAnonymousAnalytics = false;
        });
      }
    }
  }

  Future<void> _openPremium() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumScreen(dataService: _dataService),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
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

  Future<void> _openNotificationSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationSettingsScreen(dataService: _dataService),
      ),
    );
  }

  Future<void> _openPrivacy() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
    );
  }

  Future<void> _openTermsOfUse() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
    );
  }

  Future<void> _openAboutMODOSE() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AboutMODOSEScreen()),
    );
  }

  Future<void> _selectMeasurementSystem() async {
    if (_isLoadingMeasurementSystem) {
      return;
    }

    final selected = await showModalBottomSheet<MeasurementSystem>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Units & Measurements',
                  style: TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Choose how measurements are displayed throughout MODOSE.',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                _MeasurementOption(
                  title: 'Imperial',
                  subtitle: 'Weight in lb • Height in ft / in',
                  icon: LucideIcons.ruler,
                  selected: _measurementSystem == MeasurementSystem.imperial,
                  onTap: () {
                    Navigator.pop(sheetContext, MeasurementSystem.imperial);
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                _MeasurementOption(
                  title: 'Metric',
                  subtitle: 'Weight in kg • Height in cm',
                  icon: LucideIcons.ruler,
                  selected: _measurementSystem == MeasurementSystem.metric,
                  onTap: () {
                    Navigator.pop(sheetContext, MeasurementSystem.metric);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == _measurementSystem || !mounted) {
      return;
    }

    await _settingsService.saveMeasurementSystem(selected);

    if (!mounted) {
      return;
    }

    setState(() {
      _measurementSystem = selected;
    });

    widget.onMeasurementSystemChanged(selected);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Measurement system changed to ${selected.label}.'),
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.instance.showTestNotification();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test notification sent.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send test notification: $error')),
      );
    }
  }

  Future<void> _resetAppData() async {
    if (_isResettingAppData) {
      return;
    }

    final continueReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            LucideIcons.triangleAlert,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Reset all MODOSE data?'),
          content: const Text(
            'This permanently deletes protocols, dose history, weight data, '
            'MODOSE Supply, progress photos, symptoms, profiles, and local '
            'settings from this device. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (continueReset != true || !mounted) {
      return;
    }

    var confirmationText = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canReset = confirmationText.trim().toUpperCase() == 'RESET';

            return AlertDialog(
              title: const Text('Type RESET to confirm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This is the final confirmation. All local MODOSE data '
                    'will be erased.',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Confirmation',
                      hintText: 'RESET',
                    ),
                    onChanged: (value) {
                      confirmationText = value;
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Theme.of(
                      dialogContext,
                    ).colorScheme.onError,
                  ),
                  onPressed: canReset
                      ? () {
                          Navigator.pop(dialogContext, true);
                        }
                      : null,
                  child: const Text('Reset MODOSE'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isResettingAppData = true;
    });

    try {
      await AppResetService.instance.resetAllAppData();

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isResettingAppData = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset MODOSE data: $error')),
      );
    }
  }

  Future<void> _resetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset onboarding?'),
          content: const Text(
            'MODOSE will show onboarding again the next time the onboarding flow is checked.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _settingsService.resetOnboarding();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Onboarding reset.')));
  }

  Future<void> _resetMODOSESupplyBeta() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset MODOSE Supply beta notice?'),
          content: const Text(
            'The MODOSE Supply beta notice will be allowed to appear again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _settingsService.resetGhostSupplyBetaDismissed();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('MODOSE Supply beta notice reset.')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            60,
          ),
          children: [
            const _SettingsSectionHeader(
              title: 'Account',
              subtitle: 'Premium access and account status.',
            ),

            const SizedBox(height: AppSpacing.sm),

            _PremiumCard(hasPremium: _hasPremium, onTap: _openPremium),

            const SizedBox(height: AppSpacing.lg),

            const _SettingsSectionHeader(
              title: 'Preferences',
              subtitle: 'Control how MODOSE looks, tracks, and displays data.',
            ),

            const SizedBox(height: AppSpacing.sm),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: LucideIcons.palette,
                  title: 'Appearance',
                  subtitle: switch (widget.themeMode) {
                    AppThemeMode.system => 'System appearance',
                    AppThemeMode.light => 'Light appearance',
                    AppThemeMode.dark => 'Dark appearance',
                  },
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (sheetContext) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Appearance',
                                style: TextStyle(
                                  fontSize: AppTypography.title,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xs),

                              Text(
                                'Choose how MODOSE appears on this device.',
                                style: TextStyle(
                                  fontSize: AppTypography.caption,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              _ThemeOption(
                                icon: LucideIcons.monitorCog,
                                title: 'System',
                                subtitle: 'Follow your device appearance.',
                                selected:
                                    widget.themeMode == AppThemeMode.system,
                                onTap: () {
                                  widget.onThemeModeChanged(
                                    AppThemeMode.system,
                                  );

                                  Navigator.pop(sheetContext);
                                },
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              _ThemeOption(
                                icon: LucideIcons.sun,
                                title: 'Light',
                                subtitle: 'Always use light appearance.',
                                selected:
                                    widget.themeMode == AppThemeMode.light,
                                onTap: () {
                                  widget.onThemeModeChanged(AppThemeMode.light);

                                  Navigator.pop(sheetContext);
                                },
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              _ThemeOption(
                                icon: LucideIcons.moon,
                                title: 'Dark',
                                subtitle: 'Always use dark appearance.',
                                selected: widget.themeMode == AppThemeMode.dark,
                                onTap: () {
                                  widget.onThemeModeChanged(AppThemeMode.dark);

                                  Navigator.pop(sheetContext);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const _SettingsDivider(),

                _SettingsTile(
                  icon: LucideIcons.ruler,
                  title: 'Units & Measurements',
                  subtitle: _isLoadingMeasurementSystem
                      ? 'Loading preferences...'
                      : '${_measurementSystem.label} • '
                            '${_measurementSystem.description}',
                  isLoading: _isLoadingMeasurementSystem,
                  onTap: _isLoadingMeasurementSystem
                      ? null
                      : _selectMeasurementSystem,
                ),

                const _SettingsDivider(),

                _SettingsTile(
                  icon: LucideIcons.slidersHorizontal,
                  title: 'Tracking Preferences',
                  subtitle: _isLoadingTrackingPreferences
                      ? 'Loading preferences...'
                      : _trackingSummary(),
                  isLoading: _isLoadingTrackingPreferences,
                  onTap: _isLoadingTrackingPreferences
                      ? null
                      : _openTrackingPreferences,
                ),

                const _SettingsDivider(),

                _SettingsTile(
                  icon: LucideIcons.eye,
                  title: 'Display Preferences',
                  subtitle: _isLoadingDisplayPreferences
                      ? 'Loading preferences...'
                      : _displaySummary(),
                  isLoading: _isLoadingDisplayPreferences,
                  onTap: _isLoadingDisplayPreferences
                      ? null
                      : _openDisplayPreferences,
                ),

                const _SettingsDivider(),

                _SettingsSwitchTile(
                  icon: LucideIcons.partyPopper,
                  title: 'Celebrations',
                  subtitle: 'Celebrate weight goals and dose-count milestones.',
                  value: _celebrationsEnabled,
                  isLoading: _isLoadingCelebrations || _isSavingCelebrations,
                  onChanged: _isLoadingCelebrations || _isSavingCelebrations
                      ? null
                      : _setCelebrationsEnabled,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SettingsSectionHeader(
              title: 'Notifications',
              subtitle: 'Reminders, alerts, and scheduling options.',
            ),

            const SizedBox(height: AppSpacing.sm),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: LucideIcons.bell,
                  title: 'Notification Settings',
                  subtitle: 'Protocol reminders and missed-dose follow-ups.',
                  onTap: _openNotificationSettings,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SettingsSectionHeader(
              title: 'Data & Privacy',
              subtitle: 'Manage and protect your MODOSE data.',
            ),

            const SizedBox(height: AppSpacing.sm),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: LucideIcons.shieldCheck,
                  title: 'Privacy',
                  subtitle: 'Review how MODOSE stores and uses your data.',
                  onTap: _openPrivacy,
                ),

                const _SettingsDivider(),

                _SettingsSwitchTile(
                  icon: LucideIcons.chartNoAxesColumnIncreasing,
                  title: 'Anonymous Usage Analytics',
                  subtitle:
                      'Share anonymous feature usage to help improve MODOSE. '
                      'Medication names, doses, weights, notes, symptoms, and '
                      'photos are never included.',
                  value: _anonymousAnalyticsEnabled,
                  isLoading:
                      _isLoadingAnonymousAnalytics ||
                      _isSavingAnonymousAnalytics,
                  onChanged:
                      _isLoadingAnonymousAnalytics ||
                          _isSavingAnonymousAnalytics
                      ? null
                      : _setAnonymousAnalyticsEnabled,
                ),

                const _SettingsDivider(),

                _SettingsTile(
                  icon: LucideIcons.trash2,
                  title: 'Reset App Data',
                  subtitle: _isResettingAppData
                      ? 'Resetting MODOSE...'
                      : 'Erase all locally stored MODOSE data.',
                  onTap: _isResettingAppData ? null : _resetAppData,
                  isLoading: _isResettingAppData,
                  destructive: true,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            const _SettingsSectionHeader(
              title: 'App',
              subtitle: 'Legal and application information.',
            ),

            const SizedBox(height: AppSpacing.sm),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: LucideIcons.fileText,
                  title: 'Terms of Use',
                  subtitle: 'Review MODOSE terms and conditions.',
                  onTap: _openTermsOfUse,
                ),

                const _SettingsDivider(),

                _SettingsTile(
                  icon: LucideIcons.info,
                  title: 'About MODOSE',
                  subtitle: 'Version, licenses, and application information.',
                  onTap: _openAboutMODOSE,
                ),
              ],
            ),

            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.lg),

              const _SettingsSectionHeader(
                title: 'Developer',
                subtitle:
                    'Debug tools. This section is hidden in release builds.',
              ),

              const SizedBox(height: AppSpacing.sm),

              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: LucideIcons.bellRing,
                    title: 'Test Notification',
                    subtitle: 'Send a local test notification.',
                    onTap: _testNotification,
                  ),

                  const _SettingsDivider(),

                  _SettingsTile(
                    icon: LucideIcons.refreshCcw,
                    title: 'Reset Onboarding',
                    subtitle: 'Allow the onboarding flow to run again.',
                    onTap: _resetOnboarding,
                  ),

                  const _SettingsDivider(),

                  _SettingsTile(
                    icon: LucideIcons.package,
                    title: 'Reset MODOSE Supply Beta Notice',
                    subtitle:
                        'Allow the MODOSE Supply beta notice to appear again.',
                    onTap: _resetMODOSESupplyBeta,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.hasPremium, required this.onTap});

  final bool hasPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    const premiumGold = Color(0xFFE3AA22);
    const premiumGoldDark = Color(0xFFB77A00);

    final accent = hasPremium ? premiumGold : colors.primary;

    final cardStart = hasPremium
        ? Color.alphaBlend(
            premiumGold.withValues(
              alpha: brightness == Brightness.dark ? 0.20 : 0.15,
            ),
            colors.surface,
          )
        : Color.alphaBlend(
            colors.primary.withValues(
              alpha: brightness == Brightness.dark ? 0.26 : 0.12,
            ),
            colors.surface,
          );

    final cardEnd = hasPremium
        ? Color.alphaBlend(
            premiumGold.withValues(
              alpha: brightness == Brightness.dark ? 0.08 : 0.05,
            ),
            colors.surface,
          )
        : Color.alphaBlend(
            colors.primary.withValues(
              alpha: brightness == Brightness.dark ? 0.10 : 0.05,
            ),
            colors.surface,
          );

    final activeGreen = Colors.green.shade500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardStart, cardEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: accent.withValues(alpha: hasPremium ? 0.72 : 0.55),
              width: hasPremium ? 1.5 : 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: hasPremium ? 0.12 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      hasPremium ? premiumGold : colors.primary,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/branding/modose_premium_mark.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODOSE PREMIUM',
                      style: TextStyle(
                        fontSize: AppTypography.micro,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: hasPremium ? premiumGoldDark : colors.primary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasPremium
                                ? 'Premium Active'
                                : 'Upgrade to MODOSE Premium',
                            style: const TextStyle(
                              fontSize: AppTypography.title,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ),

                        if (hasPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: activeGreen.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: activeGreen.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: activeGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                    color: activeGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      hasPremium
                          ? 'All premium features unlocked.'
                          : 'Get access to advanced tracking, analytics, MODOSE Supply™, and more.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Icon(
                Icons.chevron_right_rounded,
                color: hasPremium ? premiumGoldDark : colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.75,
            color: colors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colors.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Material(
      color: baseColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.60)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 64);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      leading: _SettingsIcon(icon: icon, destructive: destructive),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: destructive ? colors.error : colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: colors.onSurfaceVariant,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : onTap == null
          ? null
          : const Icon(Icons.chevron_right),
      onTap: isLoading ? null : onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      leading: _SettingsIcon(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: colors.onSurfaceVariant,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(value: value, onChanged: onChanged),
      onTap: isLoading || onChanged == null ? null : () => onChanged!(!value),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.destructive = false});

  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final foreground = destructive ? colors.error : colors.primary;

    final background = destructive
        ? colors.error.withValues(alpha: 0.08)
        : colors.primary.withValues(alpha: 0.08);

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 21, color: foreground),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      onTap: onTap,
      leading: _SettingsIcon(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: colors.onSurfaceVariant,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: selected
            ? Icon(
                Icons.check_circle,
                key: ValueKey(title),
                color: colors.primary,
              )
            : Icon(
                Icons.circle_outlined,
                key: ValueKey('$title-unselected'),
                color: colors.outline,
              ),
      ),
    );
  }
}

class _MeasurementOption extends StatelessWidget {
  const _MeasurementOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.60),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              if (selected) Icon(Icons.check_circle, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

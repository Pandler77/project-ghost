import 'package:flutter/material.dart';

import '../models/notification_preferences.dart';
import '../models/profile.dart';
import '../services/app_data_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    required this.dataService,
    super.key,
  });

  final AppDataService dataService;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final ProfileService _profileService = ProfileService();

  NotificationPreferences _preferences =
      const NotificationPreferences();

  List<Profile> _profiles = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object>([
      _settingsService.getNotificationPreferences(),
      _profileService.getProfiles(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _preferences = results[0] as NotificationPreferences;
      _profiles = results[1] as List<Profile>;
      _isLoading = false;
    });
  }

  Future<void> _synchronizeAllProfiles() async {
    final schedules = <ProfileNotificationSchedule>[];

    for (final profile in _profiles) {
      final protocols =
          await widget.dataService.getProtocolsForProfile(profile.id);

      schedules.add(
        ProfileNotificationSchedule(
          profileId: profile.id,
          profileName: profile.name,
          protocols: protocols,
        ),
      );
    }

    await NotificationService.instance.synchronizeAllProfileReminders(
      schedules,
    );
  }

  Future<void> _savePreferences(
    NotificationPreferences preferences,
  ) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _preferences = preferences;
    });

    try {
      await _settingsService.saveNotificationPreferences(preferences);

      await _synchronizeAllProfiles();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    final granted =
        await NotificationService.instance.requestPermissions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Notification permission granted.'
              : 'Notification permission was not granted.',
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.instance.showTestNotification();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send test notification: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  60,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            ArcticIcons.notifications_active_outlined,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ArcticDose Notifications',
                                style: TextStyle(
                                  fontSize: AppTypography.title,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Global, per-profile, and custom protocol notification controls.',
                                style: TextStyle(
                                  fontSize: AppTypography.caption,
                                  height: 1.35,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _NotificationCard(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Notifications',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Master switch for ArcticDose notifications.',
                        ),
                        value: _preferences.notificationsEnabled,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                _savePreferences(
                                  _preferences.copyWith(
                                    notificationsEnabled: value,
                                  ),
                                );
                              },
                      ),

                      const Divider(height: 1),

                      SwitchListTile(
                        title: const Text(
                          'Protocol Reminders',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Allow reminders configured inside individual protocols.',
                        ),
                        value:
                            _preferences.protocolRemindersEnabled,
                        onChanged:
                            !_preferences.notificationsEnabled || _isSaving
                            ? null
                            : (value) {
                                _savePreferences(
                                  _preferences.copyWith(
                                    protocolRemindersEnabled: value,
                                  ),
                                );
                              },
                      ),

                      const Divider(height: 1),

                      SwitchListTile(
                        title: const Text(
                          'Missed-Dose Follow-Ups',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Allow follow-up alerts when a scheduled dose is not marked taken.',
                        ),
                        value:
                            _preferences.missedDoseFollowUpsEnabled,
                        onChanged:
                            !_preferences.notificationsEnabled ||
                                !_preferences.protocolRemindersEnabled ||
                                _isSaving
                            ? null
                            : (value) {
                                _savePreferences(
                                  _preferences.copyWith(
                                    missedDoseFollowUpsEnabled: value,
                                  ),
                                );
                              },
                      ),

                      const Divider(height: 1),

                      SwitchListTile(
                        title: const Text(
                          'Custom Notification Text',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Allow protocols to use a custom notification title and message.',
                        ),
                        value: _preferences.customNotificationTextEnabled,
                        onChanged:
                            !_preferences.notificationsEnabled || _isSaving
                            ? null
                            : (value) {
                                _savePreferences(
                                  _preferences.copyWith(
                                    customNotificationTextEnabled: value,
                                  ),
                                );
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'PROFILES',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.75,
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _NotificationCard(
                    children: [
                      for (var index = 0; index < _profiles.length; index++) ...[
                        SwitchListTile(
                          title: Text(
                            _profiles[index].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            _profiles[index].type.label,
                          ),
                          value: _preferences.notificationsEnabledForProfile(
                            _profiles[index].id,
                          ),
                          onChanged:
                              !_preferences.notificationsEnabled || _isSaving
                              ? null
                              : (value) {
                                  final disabled = Set<String>.from(
                                    _preferences.disabledProfileIds,
                                  );

                                  if (value) {
                                    disabled.remove(_profiles[index].id);
                                  } else {
                                    disabled.add(_profiles[index].id);
                                  }

                                  _savePreferences(
                                    _preferences.copyWith(
                                      disabledProfileIds: disabled,
                                    ),
                                  );
                                },
                        ),
                        if (index < _profiles.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'DEVICE',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.75,
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _NotificationCard(
                    children: [
                      ListTile(
                        leading: Icon(
                          ArcticIcons.security_outlined,
                          color: colors.primary,
                        ),
                        title: const Text(
                          'Notification Permission',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Ask the device to allow ArcticDose notifications.',
                        ),
                        trailing:
                            const Icon(Icons.chevron_right_rounded),
                        onTap: _requestPermissions,
                      ),

                      const Divider(height: 1),

                      ListTile(
                        leading: Icon(
                          ArcticIcons.notifications_active_outlined,
                          color: colors.primary,
                        ),
                        title: const Text(
                          'Send Test Notification',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Verify notifications are working on this device.',
                        ),
                        trailing:
                            const Icon(Icons.chevron_right_rounded),
                        onTap: _sendTestNotification,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).cardTheme.color ??
                          colors.surface,
                      borderRadius:
                          BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(
                          alpha: 0.60,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          ArcticIcons.info_outline,
                          size: AppIcon.sm,
                          color: colors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Turning global reminders off does not erase the reminder settings saved inside each protocol. Turning them back on restores scheduling from those protocol settings.',
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              height: 1.4,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardTheme.color ??
            colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(children: children),
    );
  }
}

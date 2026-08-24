import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_theme_mode.dart';
import '../models/display_preferences.dart';
import '../models/home_layout.dart';
import '../models/home_section.dart';
import '../models/measurement_system.dart';
import '../models/milestone_achievement.dart';
import '../models/notification_preferences.dart';
import '../models/tracking_preferences.dart';

class SettingsService {
  static const String _themeModeKey = 'theme_mode';
  static const String _homeLayoutKey = 'home_layout';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  static const String _trackWeightKey = 'track_weight';
  static const String _trackPhotosKey = 'track_photos';
  static const String _trackNotesKey = 'track_notes';

  static const String _weightFrequencyKey = 'weight_frequency';
  static const String _photoFrequencyKey = 'photo_frequency';

  static const String _displayPreferencesKey = 'display_preferences';
  static const String _notificationPreferencesKey = 'notification_preferences';

  static const String _ghostSupplyBetaDismissedKey =
      'ghost_supply_beta_dismissed';

  static const String _activeProfileIdKey = 'active_profile_id';

  static const String _measurementSystemKey = 'measurement_system';

  static const String _celebrationsEnabledKey = 'celebrations_enabled';
  static const String _awardedMilestonesKey = 'awarded_milestones';
  static const String _pendingMilestonesKey = 'pending_milestones';

  static const String _anonymousAnalyticsEnabledKey =
      'anonymous_analytics_enabled';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  // ------------------------
  // Theme
  // ------------------------

  Future<AppThemeMode> getThemeMode() async {
    final savedValue = await _preferences.getString(_themeModeKey);

    return switch (savedValue) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> saveThemeMode(AppThemeMode themeMode) async {
    await _preferences.setString(_themeModeKey, themeMode.name);
  }

  // ------------------------
  // Home layout
  // ------------------------

  Future<HomeLayout> getHomeLayout() async {
    final savedValues = await _preferences.getStringList(_homeLayoutKey);

    if (savedValues == null || savedValues.isEmpty) {
      return HomeLayout.defaultLayout;
    }

    final sections = savedValues
        .map(HomeSectionDetails.fromStorageValue)
        .whereType<HomeSection>()
        .toList();

    if (sections.isEmpty) {
      return HomeLayout.defaultLayout;
    }

    return HomeLayout(visibleSections: sections);
  }

  Future<void> saveHomeLayout(HomeLayout layout) async {
    final values = layout.visibleSections
        .map((section) => section.storageValue)
        .toList();

    await _preferences.setStringList(_homeLayoutKey, values);
  }

  Future<void> resetHomeLayout() async {
    await _preferences.remove(_homeLayoutKey);
  }

  // ------------------------
  // Onboarding
  // ------------------------

  Future<bool> getOnboardingComplete() async {
    return await _preferences.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> saveOnboardingComplete(bool isComplete) async {
    await _preferences.setBool(_onboardingCompleteKey, isComplete);
  }

  Future<void> resetOnboarding() async {
    await _preferences.remove(_onboardingCompleteKey);
  }

  // ------------------------
  // Tracking preferences
  // ------------------------

  Future<TrackingPreferences> getTrackingPreferences() async {
    final trackWeight =
        await _preferences.getBool(_trackWeightKey) ??
        TrackingPreferences.defaults.trackWeight;

    final trackPhotos =
        await _preferences.getBool(_trackPhotosKey) ??
        TrackingPreferences.defaults.trackPhotos;

    final trackNotes =
        await _preferences.getBool(_trackNotesKey) ??
        TrackingPreferences.defaults.trackNotes;

    final savedWeightFrequency = await _preferences.getString(
      _weightFrequencyKey,
    );

    final savedPhotoFrequency = await _preferences.getString(
      _photoFrequencyKey,
    );

    return TrackingPreferences(
      trackWeight: trackWeight,
      trackPhotos: trackPhotos,
      trackNotes: trackNotes,
      weightFrequency: _frequencyFromName(
        savedWeightFrequency,
        fallback: TrackingPreferences.defaults.weightFrequency,
      ),
      photoFrequency: _frequencyFromName(
        savedPhotoFrequency,
        fallback: TrackingPreferences.defaults.photoFrequency,
      ),
    );
  }

  Future<void> saveTrackingPreferences(TrackingPreferences preferences) async {
    await Future.wait([
      _preferences.setBool(_trackWeightKey, preferences.trackWeight),
      _preferences.setBool(_trackPhotosKey, preferences.trackPhotos),
      _preferences.setBool(_trackNotesKey, preferences.trackNotes),
      _preferences.setString(
        _weightFrequencyKey,
        preferences.weightFrequency.name,
      ),
      _preferences.setString(
        _photoFrequencyKey,
        preferences.photoFrequency.name,
      ),
    ]);
  }

  TrackingFrequency _frequencyFromName(
    String? value, {
    required TrackingFrequency fallback,
  }) {
    for (final frequency in TrackingFrequency.values) {
      if (frequency.name == value) {
        return frequency;
      }
    }

    return fallback;
  }

  // ------------------------
  // Display preferences
  // ------------------------

  Future<DisplayPreferences> getDisplayPreferences() async {
    final savedValue = await _preferences.getString(_displayPreferencesKey);

    if (savedValue == null || savedValue.trim().isEmpty) {
      return const DisplayPreferences();
    }

    try {
      final decoded = jsonDecode(savedValue);

      if (decoded is! Map<String, dynamic>) {
        return const DisplayPreferences();
      }

      return DisplayPreferences.fromMap(Map<String, Object?>.from(decoded));
    } catch (_) {
      return const DisplayPreferences();
    }
  }

  Future<void> saveDisplayPreferences(
    DisplayPreferences displayPreferences,
  ) async {
    final encoded = jsonEncode(displayPreferences.toMap());

    await _preferences.setString(_displayPreferencesKey, encoded);
  }

  Future<void> resetDisplayPreferences() async {
    await _preferences.remove(_displayPreferencesKey);
  }

  // ------------------------
  // Notification preferences
  // ------------------------

  Future<NotificationPreferences> getNotificationPreferences() async {
    final savedValue = await _preferences.getString(
      _notificationPreferencesKey,
    );

    if (savedValue == null || savedValue.trim().isEmpty) {
      return const NotificationPreferences(
        notificationsEnabled: true,
        protocolRemindersEnabled: true,
        missedDoseFollowUpsEnabled: true,
        customNotificationTextEnabled: true,
      );
    }

    try {
      final decoded = jsonDecode(savedValue);

      if (decoded is! Map<String, dynamic>) {
        return const NotificationPreferences(
          notificationsEnabled: true,
          protocolRemindersEnabled: true,
          missedDoseFollowUpsEnabled: true,
          customNotificationTextEnabled: true,
        );
      }

      return NotificationPreferences.fromMap(
        Map<String, Object?>.from(decoded),
      );
    } catch (_) {
      return const NotificationPreferences(
        notificationsEnabled: true,
        protocolRemindersEnabled: true,
        missedDoseFollowUpsEnabled: true,
        customNotificationTextEnabled: true,
      );
    }
  }

  Future<void> saveNotificationPreferences(
    NotificationPreferences notificationPreferences,
  ) async {
    final encoded = jsonEncode(notificationPreferences.toMap());

    await _preferences.setString(_notificationPreferencesKey, encoded);
  }

  Future<void> resetNotificationPreferences() async {
    await _preferences.remove(_notificationPreferencesKey);
  }

  // ------------------------
  // Milestones & celebrations
  // ------------------------

  Future<bool> getCelebrationsEnabled() async {
    return await _preferences.getBool(_celebrationsEnabledKey) ?? true;
  }

  Future<void> saveCelebrationsEnabled(bool enabled) async {
    await _preferences.setBool(_celebrationsEnabledKey, enabled);
  }

  Future<Set<String>> getAwardedMilestoneIds(String profileId) async {
    final all = await _readAwardedMilestones();
    final values = all[profileId];

    if (values is! List) {
      return <String>{};
    }

    return values.whereType<String>().toSet();
  }

  Future<void> addAwardedMilestoneIds(
    String profileId,
    Set<String> milestoneIds,
  ) async {
    if (milestoneIds.isEmpty) {
      return;
    }

    final all = await _readAwardedMilestones();

    final existing = <String>{
      ...((all[profileId] as List?)?.whereType<String>() ?? const <String>[]),
      ...milestoneIds,
    }.toList()..sort();

    all[profileId] = existing;

    await _preferences.setString(_awardedMilestonesKey, jsonEncode(all));
  }

  Future<void> enqueueMilestone(MilestoneAchievement achievement) async {
    final pending = await _readPendingMilestones();

    final duplicate = pending.any(
      (item) =>
          item.profileId == achievement.profileId && item.id == achievement.id,
    );

    if (duplicate) {
      return;
    }

    pending.add(achievement);

    await _preferences.setString(
      _pendingMilestonesKey,
      jsonEncode(pending.map((item) => item.toMap()).toList()),
    );
  }

  Future<MilestoneAchievement?> takePendingMilestone(String profileId) async {
    final pending = await _readPendingMilestones();

    final index = pending.indexWhere((item) => item.profileId == profileId);

    if (index == -1) {
      return null;
    }

    final achievement = pending.removeAt(index);

    await _preferences.setString(
      _pendingMilestonesKey,
      jsonEncode(pending.map((item) => item.toMap()).toList()),
    );

    return achievement;
  }

  Future<Map<String, dynamic>> _readAwardedMilestones() async {
    final saved = await _preferences.getString(_awardedMilestonesKey);

    if (saved == null || saved.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(saved);

      if (decoded is! Map<String, dynamic>) {
        return <String, dynamic>{};
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<List<MilestoneAchievement>> _readPendingMilestones() async {
    final saved = await _preferences.getString(_pendingMilestonesKey);

    if (saved == null || saved.trim().isEmpty) {
      return <MilestoneAchievement>[];
    }

    try {
      final decoded = jsonDecode(saved);

      if (decoded is! List) {
        return <MilestoneAchievement>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                MilestoneAchievement.fromMap(Map<String, Object?>.from(item)),
          )
          .toList();
    } catch (_) {
      return <MilestoneAchievement>[];
    }
  }

  // ------------------------
  // Anonymous product analytics
  // ------------------------

  Future<bool> getAnonymousAnalyticsEnabled() async {
    return await _preferences.getBool(_anonymousAnalyticsEnabledKey) ?? true;
  }

  Future<void> saveAnonymousAnalyticsEnabled(bool enabled) async {
    await _preferences.setBool(_anonymousAnalyticsEnabledKey, enabled);
  }

  Future<void> resetAnonymousAnalyticsEnabled() async {
    await _preferences.remove(_anonymousAnalyticsEnabledKey);
  }

  // ------------------------
  // Measurement system
  // ------------------------

  Future<MeasurementSystem> getMeasurementSystem() async {
    final savedValue = await _preferences.getString(_measurementSystemKey);

    return switch (savedValue) {
      'metric' => MeasurementSystem.metric,
      'imperial' => MeasurementSystem.imperial,
      _ => MeasurementSystem.imperial,
    };
  }

  Future<void> saveMeasurementSystem(
    MeasurementSystem measurementSystem,
  ) async {
    await _preferences.setString(_measurementSystemKey, measurementSystem.name);
  }

  Future<void> resetMeasurementSystem() async {
    await _preferences.remove(_measurementSystemKey);
  }

  // ------------------------
  // Active profile
  // ------------------------

  Future<String?> getActiveProfileId() async {
    return _preferences.getString(_activeProfileIdKey);
  }

  Future<void> saveActiveProfileId(String profileId) async {
    await _preferences.setString(_activeProfileIdKey, profileId);
  }

  Future<void> clearActiveProfileId() async {
    await _preferences.remove(_activeProfileIdKey);
  }

  // ------------------------
  // Ghost Supply Beta
  // ------------------------

  Future<bool> getGhostSupplyBetaDismissed() async {
    return await _preferences.getBool(_ghostSupplyBetaDismissedKey) ?? false;
  }

  Future<void> saveGhostSupplyBetaDismissed(bool isDismissed) async {
    await _preferences.setBool(_ghostSupplyBetaDismissedKey, isDismissed);
  }

  Future<void> resetGhostSupplyBetaDismissed() async {
    await _preferences.remove(_ghostSupplyBetaDismissedKey);
  }

  // ------------------------
  // Full local reset
  // ------------------------

  Future<void> resetForFreshStart() async {
    await Future.wait([
      _preferences.remove(_themeModeKey),
      _preferences.remove(_homeLayoutKey),
      _preferences.remove(_onboardingCompleteKey),
      _preferences.remove(_trackWeightKey),
      _preferences.remove(_trackPhotosKey),
      _preferences.remove(_trackNotesKey),
      _preferences.remove(_weightFrequencyKey),
      _preferences.remove(_photoFrequencyKey),
      _preferences.remove(_displayPreferencesKey),
      _preferences.remove(_notificationPreferencesKey),
      _preferences.remove(_ghostSupplyBetaDismissedKey),
      _preferences.remove(_activeProfileIdKey),
      _preferences.remove(_measurementSystemKey),
      _preferences.remove(_celebrationsEnabledKey),
      _preferences.remove(_awardedMilestonesKey),
      _preferences.remove(_pendingMilestonesKey),
    ]);
  }
}

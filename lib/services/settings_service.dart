import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_theme_mode.dart';
import '../models/display_preferences.dart';
import '../models/home_layout.dart';
import '../models/home_section.dart';
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

  static const String _ghostSupplyBetaDismissedKey =
      'ghost_supply_beta_dismissed';

  static const String _activeProfileIdKey = 'active_profile_id';

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
}

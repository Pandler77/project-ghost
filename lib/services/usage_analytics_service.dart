import 'package:aptabase_flutter/aptabase_flutter.dart';

import 'settings_service.dart';

enum UsageAnalyticsEvent {
  appOpened('app_opened'),
  analyticsEnabled('analytics_enabled'),
  profileCreated('profile_created'),
  profileSwitched('profile_switched'),
  protocolCreated('protocol_created'),
  protocolEdited('protocol_edited'),
  doseTaken('dose_taken'),
  doseSkipped('dose_skipped'),
  doseUndone('dose_undone'),
  calendarOpened('calendar_opened'),
  supplyOpened('supply_opened'),
  inventoryItemCreated('inventory_item_created'),
  weightLogged('weight_logged'),
  weightHistoryOpened('weight_history_opened'),
  photoSessionCreated('photo_session_created'),
  symptomLogged('symptom_logged'),
  calculatorOpened('calculator_opened'),
  premiumScreenViewed('premium_screen_viewed');

  const UsageAnalyticsEvent(this.eventName);

  final String eventName;
}

class UsageAnalyticsService {
  UsageAnalyticsService._();

  static final UsageAnalyticsService instance = UsageAnalyticsService._();

  static const String _appKey = String.fromEnvironment(
    'APTABASE_APP_KEY',
    defaultValue: '',
  );

  final SettingsService _settingsService = SettingsService();

  bool _initialized = false;
  bool _enabled = false;

  bool get isConfigured => _appKey.trim().isNotEmpty;
  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    _enabled = await _settingsService.getAnonymousAnalyticsEnabled();

    if (!_enabled || !isConfigured) {
      return;
    }

    await _initializeSdk();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _settingsService.saveAnonymousAnalyticsEnabled(enabled);

    if (!_enabled || !isConfigured) {
      return;
    }

    await _initializeSdk();
    track(UsageAnalyticsEvent.analyticsEnabled);
  }

  Future<void> track(
    UsageAnalyticsEvent event, {
    Map<String, Object>? properties,
  }) async {
    if (!_enabled || !isConfigured) {
      return;
    }

    await _initializeSdk();

    final safeProperties = _sanitizeProperties(properties);

    Aptabase.instance.trackEvent(
      event.eventName,
      safeProperties.isEmpty ? null : safeProperties,
    );
  }

  Future<void> _initializeSdk() async {
    if (_initialized) {
      return;
    }

    await Aptabase.init(_appKey);
    _initialized = true;
  }

  Map<String, dynamic> _sanitizeProperties(Map<String, Object>? properties) {
    if (properties == null || properties.isEmpty) {
      return const <String, dynamic>{};
    }

    final safe = <String, dynamic>{};

    for (final entry in properties.entries) {
      final value = entry.value;

      if (value is String || value is num) {
        safe[entry.key] = value;
      }
    }

    return safe;
  }
}

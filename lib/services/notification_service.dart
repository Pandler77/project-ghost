import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_preferences.dart';
import '../models/protocol.dart';
import '../models/schedule_override.dart';
import 'reminder_schedule_service.dart';
import 'settings_service.dart';

class ProfileNotificationSchedule {
  const ProfileNotificationSchedule({
    required this.profileId,
    required this.profileName,
    required this.protocols,
    this.overrides = const [],
  });

  final String profileId;
  final String profileName;
  final List<Protocol> protocols;
  final List<ScheduleOverride> overrides;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'protocol_reminders';
  static const String _channelName = 'Protocol Reminders';

  // iOS only keeps a limited number of pending local notifications.
  // Keep a small rolling window per protocol and cap the global queue.
  static const int _occurrenceLimitPerProtocol = 4;
  static const int _maxPendingProtocolNotifications = 60;

  static const ReminderScheduleService _reminderScheduleService =
      ReminderScheduleService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final SettingsService _settingsService = SettingsService();

  final ValueNotifier<String?> protocolNavigation = ValueNotifier<String?>(
    null,
  );

  String? get pendingProtocolId => protocolNavigation.value;

  Future<void> initialize() async {
    await _initializeTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationPressed,
    );

    await _createAndroidChannel();
    await _loadLaunchNotification();
  }

  Future<void> _initializeTimezone() async {
    tz_data.initializeTimeZones();
    final deviceTimezone = await FlutterTimezone.getLocalTimezone();

    try {
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));
    } on tz.LocationNotFoundException {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _loadLaunchNotification() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp != true) {
      return;
    }

    _handlePayload(launchDetails?.notificationResponse?.payload);
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications for scheduled protocol reminders.',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      1,
      'MODOSE',
      'Notifications are working.',
      _notificationDetails,
    );
  }

  Future<void> scheduleProtocolReminders(
    Protocol protocol, {
    required String profileId,
    required String profileName,
    DateTime? from,
    List<ScheduleOverride> overrides = const [],
  }) async {
    await cancelProtocolReminders(protocol.id, profileId: profileId);

    final preferences = await _settingsService.getNotificationPreferences();

    if (!_canScheduleProfile(preferences, profileId: profileId) ||
        !protocol.reminderEnabled) {
      return;
    }

    final reminders = _reminderScheduleService.upcomingReminders(
      protocol,
      from: from,
      occurrenceLimit: _occurrenceLimitPerProtocol,
      overrides: overrides,
    );

    for (final reminder in reminders) {
      if (reminder.isFollowUp && !preferences.missedDoseFollowUpsEnabled) {
        continue;
      }

      await _scheduleReminder(
        _ProfileReminder(
          profileId: profileId,
          profileName: profileName,
          protocol: protocol,
          reminder: reminder,
        ),
        preferences: preferences,
      );
    }
  }

  Future<void> synchronizeAllProfileReminders(
    List<ProfileNotificationSchedule> profileSchedules, {
    DateTime? from,
  }) async {
    await _cancelAllProtocolReminders();

    final preferences = await _settingsService.getNotificationPreferences();

    if (!preferences.notificationsEnabled ||
        !preferences.protocolRemindersEnabled) {
      return;
    }

    final candidates = <_ProfileReminder>[];

    for (final profileSchedule in profileSchedules) {
      if (!preferences.notificationsEnabledForProfile(
        profileSchedule.profileId,
      )) {
        continue;
      }

      for (final protocol in profileSchedule.protocols) {
        if (!protocol.reminderEnabled) {
          continue;
        }

        final reminders = _reminderScheduleService.upcomingReminders(
          protocol,
          from: from,
          occurrenceLimit: _occurrenceLimitPerProtocol,
          overrides: profileSchedule.overrides,
        );

        for (final reminder in reminders) {
          if (reminder.isFollowUp && !preferences.missedDoseFollowUpsEnabled) {
            continue;
          }

          candidates.add(
            _ProfileReminder(
              profileId: profileSchedule.profileId,
              profileName: profileSchedule.profileName,
              protocol: protocol,
              reminder: reminder,
            ),
          );
        }
      }
    }

    candidates.sort(
      (first, second) => first.reminder.notificationTime.compareTo(
        second.reminder.notificationTime,
      ),
    );

    final limited = candidates.take(_maxPendingProtocolNotifications);

    for (final candidate in limited) {
      await _scheduleReminder(candidate, preferences: preferences);
    }
  }

  Future<void> synchronizeProtocolReminders(
    List<Protocol> protocols, {
    required String profileId,
    required String profileName,
    DateTime? from,
    List<ScheduleOverride> overrides = const [],
  }) async {
    await cancelProfileReminders(profileId);

    final preferences = await _settingsService.getNotificationPreferences();

    if (!_canScheduleProfile(preferences, profileId: profileId)) {
      return;
    }

    for (final protocol in protocols) {
      await scheduleProtocolReminders(
        protocol,
        profileId: profileId,
        profileName: profileName,
        from: from,
        overrides: overrides.where((item) => item.protocolId == protocol.id).toList(),
      );
    }
  }

  Future<void> rescheduleAllProtocols(
    List<Protocol> protocols, {
    required String profileId,
    required String profileName,
    DateTime? from,
    List<ScheduleOverride> overrides = const [],
  }) {
    return synchronizeProtocolReminders(
      protocols,
      profileId: profileId,
      profileName: profileName,
      from: from,
      overrides: overrides,
    );
  }

  Future<void> _scheduleReminder(
    _ProfileReminder item, {
    required NotificationPreferences preferences,
  }) async {
    final currentTime = tz.TZDateTime.now(tz.local);

    var notificationTime = tz.TZDateTime(
      tz.local,
      item.reminder.notificationTime.year,
      item.reminder.notificationTime.month,
      item.reminder.notificationTime.day,
      item.reminder.notificationTime.hour,
      item.reminder.notificationTime.minute,
      item.reminder.notificationTime.second,
    );

    // The old implementation silently dropped an "At time" reminder if the
    // protocol was saved a few seconds after the selected minute started.
    // Fire it immediately instead. This is the exact shape that can produce a
    // follow-up with no primary reminder.
    if (!notificationTime.isAfter(currentTime)) {
      if (item.reminder.isPrimary &&
          _isSameMinute(item.reminder.notificationTime, currentTime)) {
        notificationTime = currentTime.add(const Duration(seconds: 2));
      } else {
        return;
      }
    }

    await _plugin.zonedSchedule(
      _notificationIdFor(item),
      _titleFor(item, preferences),
      _bodyFor(item, preferences),
      notificationTime,
      _notificationDetails,
      payload: _payloadFor(item),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  bool _canScheduleProfile(
    NotificationPreferences preferences, {
    required String profileId,
  }) {
    return preferences.notificationsEnabled &&
        preferences.protocolRemindersEnabled &&
        preferences.notificationsEnabledForProfile(profileId);
  }

  Future<void> _cancelAllProtocolReminders() async {
    final pending = await _plugin.pendingNotificationRequests();

    for (final request in pending) {
      final payload = request.payload;

      if (payload != null &&
          (payload.startsWith('ghost:profile:') ||
              payload.startsWith('ghost:protocol:'))) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> cancelProfileReminders(String profileId) async {
    final pending = await _plugin.pendingNotificationRequests();

    final prefix = 'ghost:profile:$profileId|';

    for (final request in pending) {
      final payload = request.payload;

      if (payload != null && payload.startsWith(prefix)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> cancelProtocolReminders(
    String protocolId, {
    required String profileId,
  }) async {
    final pending = await _plugin.pendingNotificationRequests();

    final profilePrefix = 'ghost:profile:$profileId|';
    final protocolPart = '|protocol:$protocolId|';

    for (final request in pending) {
      final payload = request.payload;

      if (payload == null) {
        continue;
      }

      final matchesNewPayload =
          payload.startsWith(profilePrefix) && payload.contains(protocolPart);

      // Also clear protocol-only payloads left over from pre-2.0 scheduling.
      final matchesLegacyPayload = payload.startsWith(
        'ghost:protocol:$protocolId|',
      );

      if (matchesNewPayload || matchesLegacyPayload) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> cancelFollowUpReminder({
    required String profileId,
    required String protocolId,
    required DateTime scheduledDoseTime,
  }) async {
    // First cancel the deterministic ID directly. This avoids depending on
    // pending-notification payload enumeration for the normal case.
    final directId = _stablePositiveHash(
      '$profileId|'
      '$protocolId|'
      '${scheduledDoseTime.millisecondsSinceEpoch}|'
      'followUp',
    );

    await _plugin.cancel(directId);

    final pending = await _plugin.pendingNotificationRequests();

    final profilePrefix = 'ghost:profile:$profileId|';
    final protocolPart = '|protocol:$protocolId|';
    final exactOccurrence = scheduledDoseTime.millisecondsSinceEpoch;

    for (final request in pending) {
      final payload = request.payload;

      if (payload == null || !payload.contains('|kind:followUp')) {
        continue;
      }

      final matchesNewProfile =
          payload.startsWith(profilePrefix) && payload.contains(protocolPart);

      final matchesLegacyProtocol = payload.startsWith(
        'ghost:protocol:$protocolId|',
      );

      if (!matchesNewProfile && !matchesLegacyProtocol) {
        continue;
      }

      final occurrenceMillis = _occurrenceMillisFromPayload(payload);

      if (occurrenceMillis == null) {
        continue;
      }

      final exactMatch = occurrenceMillis == exactOccurrence;

      final payloadScheduledTime = DateTime.fromMillisecondsSinceEpoch(
        occurrenceMillis,
      );

      final sameScheduledMinute = _isSameMinute(
        payloadScheduledTime,
        scheduledDoseTime,
      );

      if (exactMatch || sameScheduledMinute) {
        await _plugin.cancel(request.id);
      }
    }
  }

  int? _occurrenceMillisFromPayload(String payload) {
    const marker = '|occurrence:';

    final startIndex = payload.indexOf(marker);

    if (startIndex == -1) {
      return null;
    }

    final valueStart = startIndex + marker.length;
    final valueEnd = payload.indexOf('|', valueStart);

    if (valueEnd == -1) {
      return null;
    }

    return int.tryParse(payload.substring(valueStart, valueEnd));
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  void clearPendingNavigation() {
    protocolNavigation.value = null;
  }

  String _titleFor(_ProfileReminder item, NotificationPreferences preferences) {
    return item.reminder.isPrimary
        ? 'MODOSE'
        : 'MODOSE - Forgot something?';
  }

  String _bodyFor(_ProfileReminder item, NotificationPreferences preferences) {
    if (item.reminder.isPrimary) {
      final customBody = item.protocol.customReminderBody?.trim();

      return preferences.customNotificationTextEnabled &&
              customBody != null &&
              customBody.isNotEmpty
          ? customBody
          : "It's time for your protocol";
    }

    final customFollowUpBody = item.protocol.customFollowUpBody?.trim();

    return preferences.customNotificationTextEnabled &&
            customFollowUpBody != null &&
            customFollowUpBody.isNotEmpty
        ? customFollowUpBody
        : "You haven't logged your protocol today.";
  }

  String _payloadFor(_ProfileReminder item) {
    return 'ghost:profile:${item.profileId}|'
        'protocol:${item.reminder.protocolId}|'
        'occurrence:${item.reminder.scheduledDoseTime.millisecondsSinceEpoch}|'
        'kind:${item.reminder.kind.name}';
  }

  int _notificationIdFor(_ProfileReminder item) {
    final value =
        '${item.profileId}|'
        '${item.reminder.protocolId}|'
        '${item.reminder.scheduledDoseTime.millisecondsSinceEpoch}|'
        '${item.reminder.kind.name}';

    return _stablePositiveHash(value);
  }

  int _stablePositiveHash(String value) {
    var hash = 0x811C9DC5;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    return hash;
  }

  bool _isSameMinute(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute;
  }

  void _onNotificationPressed(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  void _handlePayload(String? payload) {
    final protocolId = _protocolIdFromPayload(payload);

    if (protocolId != null) {
      protocolNavigation.value = protocolId;
    }
  }

  String? _protocolIdFromPayload(String? payload) {
    if (payload == null) {
      return null;
    }

    if (payload.startsWith('ghost:profile:')) {
      const protocolMarker = '|protocol:';
      final protocolIndex = payload.indexOf(protocolMarker);

      if (protocolIndex == -1) {
        return null;
      }

      final start = protocolIndex + protocolMarker.length;
      final end = payload.indexOf('|', start);

      if (end == -1) {
        return null;
      }

      final protocolId = payload.substring(start, end);

      return protocolId.isEmpty ? null : protocolId;
    }

    const legacyPrefix = 'ghost:protocol:';

    if (!payload.startsWith(legacyPrefix)) {
      return null;
    }

    final separatorIndex = payload.indexOf('|');

    if (separatorIndex == -1) {
      return null;
    }

    final protocolId = payload.substring(legacyPrefix.length, separatorIndex);

    return protocolId.isEmpty ? null : protocolId;
  }

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifications for scheduled protocol reminders.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}

class _ProfileReminder {
  const _ProfileReminder({
    required this.profileId,
    required this.profileName,
    required this.protocol,
    required this.reminder,
  });

  final String profileId;
  final String profileName;
  final Protocol protocol;
  final ScheduledReminder reminder;
}

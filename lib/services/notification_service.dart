import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/protocol.dart';
import 'reminder_schedule_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'protocol_reminders';
  static const String _channelName = 'Protocol Reminders';
  static const int _occurrenceLimit = 10;

  static const ReminderScheduleService _reminderScheduleService =
      ReminderScheduleService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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
      'Project Ghost',
      'Notifications are working.',
      _notificationDetails,
    );
  }

  Future<void> scheduleProtocolReminders(
    Protocol protocol, {
    DateTime? from,
  }) async {
    await cancelProtocolReminders(protocol.id);

    if (!protocol.reminderEnabled) {
      return;
    }

    final reminders = _reminderScheduleService.upcomingReminders(
      protocol,
      from: from,
      occurrenceLimit: _occurrenceLimit,
    );

    final currentTime = tz.TZDateTime.now(tz.local);

    for (final reminder in reminders) {
      final notificationTime = tz.TZDateTime(
        tz.local,
        reminder.notificationTime.year,
        reminder.notificationTime.month,
        reminder.notificationTime.day,
        reminder.notificationTime.hour,
        reminder.notificationTime.minute,
        reminder.notificationTime.second,
      );

      if (!notificationTime.isAfter(currentTime)) {
        continue;
      }

      await _plugin.zonedSchedule(
        _notificationIdFor(reminder),
        _titleFor(reminder),
        _bodyFor(reminder),
        notificationTime,
        _notificationDetails,
        payload: _payloadFor(reminder),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> synchronizeProtocolReminders(
    List<Protocol> protocols, {
    DateTime? from,
  }) async {
    await _cancelAllProtocolReminders();

    for (final protocol in protocols) {
      await scheduleProtocolReminders(protocol, from: from);
    }
  }

  Future<void> rescheduleAllProtocols(
    List<Protocol> protocols, {
    DateTime? from,
  }) {
    return synchronizeProtocolReminders(protocols, from: from);
  }

  Future<void> _cancelAllProtocolReminders() async {
    final pending = await _plugin.pendingNotificationRequests();

    for (final request in pending) {
      final payload = request.payload;
      if (payload != null && payload.startsWith('ghost:protocol:')) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> cancelProtocolReminders(String protocolId) async {
    final pending = await _plugin.pendingNotificationRequests();
    final payloadPrefix = 'ghost:protocol:$protocolId|';

    for (final request in pending) {
      final payload = request.payload;
      if (payload != null && payload.startsWith(payloadPrefix)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> cancelFollowUpReminder({
    required String protocolId,
    required DateTime scheduledDoseTime,
  }) async {
    final pending = await _plugin.pendingNotificationRequests();
    final payloadPrefix = 'ghost:protocol:$protocolId|';
    final occurrence = scheduledDoseTime.millisecondsSinceEpoch.toString();

    for (final request in pending) {
      final payload = request.payload;
      if (payload == null) {
        continue;
      }

      final matchesProtocol = payload.startsWith(payloadPrefix);
      final matchesOccurrence = payload.contains('|occurrence:$occurrence|');
      final isFollowUp = payload.contains('|kind:followUp');

      if (matchesProtocol && matchesOccurrence && isFollowUp) {
        await _plugin.cancel(request.id);
      }
    }
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

  String _titleFor(ScheduledReminder reminder) {
    return reminder.kind == ReminderKind.primary
        ? '${reminder.protocolName} reminder'
        : '${reminder.protocolName} follow-up';
  }

  String _bodyFor(ScheduledReminder reminder) {
    return reminder.kind == ReminderKind.primary
        ? 'Your scheduled dose is ${reminder.dose}.'
        : 'This dose has not been marked as taken.';
  }

  String _payloadFor(ScheduledReminder reminder) {
    return 'ghost:protocol:${reminder.protocolId}|'
        'occurrence:${reminder.scheduledDoseTime.millisecondsSinceEpoch}|'
        'kind:${reminder.kind.name}';
  }

  int _notificationIdFor(ScheduledReminder reminder) {
    final value =
        '${reminder.protocolId}|'
        '${reminder.scheduledDoseTime.millisecondsSinceEpoch}|'
        '${reminder.kind.name}';

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
    const prefix = 'ghost:protocol:';

    if (payload == null || !payload.startsWith(prefix)) {
      return null;
    }

    final separatorIndex = payload.indexOf('|');
    if (separatorIndex == -1) {
      return null;
    }

    final protocolId = payload.substring(prefix.length, separatorIndex);
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

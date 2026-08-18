class NotificationPreferences {
  const NotificationPreferences({
    this.notificationsEnabled = true,
    this.protocolRemindersEnabled = true,
    this.missedDoseFollowUpsEnabled = true,
    this.customNotificationTextEnabled = false,
    this.disabledProfileIds = const <String>{},
  });

  final bool notificationsEnabled;
  final bool protocolRemindersEnabled;
  final bool missedDoseFollowUpsEnabled;
  final bool customNotificationTextEnabled;
  final Set<String> disabledProfileIds;

  bool notificationsEnabledForProfile(String profileId) {
    return !disabledProfileIds.contains(profileId);
  }

  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    bool? protocolRemindersEnabled,
    bool? missedDoseFollowUpsEnabled,
    bool? customNotificationTextEnabled,
    Set<String>? disabledProfileIds,
  }) {
    return NotificationPreferences(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      protocolRemindersEnabled:
          protocolRemindersEnabled ?? this.protocolRemindersEnabled,
      missedDoseFollowUpsEnabled:
          missedDoseFollowUpsEnabled ?? this.missedDoseFollowUpsEnabled,
      customNotificationTextEnabled:
          customNotificationTextEnabled ?? this.customNotificationTextEnabled,
      disabledProfileIds:
          disabledProfileIds ?? this.disabledProfileIds,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'protocolRemindersEnabled': protocolRemindersEnabled,
      'missedDoseFollowUpsEnabled': missedDoseFollowUpsEnabled,
      'customNotificationTextEnabled': customNotificationTextEnabled,
      'disabledProfileIds': disabledProfileIds.toList()..sort(),
    };
  }

  factory NotificationPreferences.fromMap(Map<String, Object?> map) {
    final rawDisabledProfiles = map['disabledProfileIds'];

    final disabledProfiles = rawDisabledProfiles is List
        ? rawDisabledProfiles.whereType<String>().toSet()
        : <String>{};

    return NotificationPreferences(
      notificationsEnabled:
          map['notificationsEnabled'] as bool? ?? true,
      protocolRemindersEnabled:
          map['protocolRemindersEnabled'] as bool? ?? true,
      missedDoseFollowUpsEnabled:
          map['missedDoseFollowUpsEnabled'] as bool? ?? true,
      customNotificationTextEnabled:
          map['customNotificationTextEnabled'] as bool? ?? false,
      disabledProfileIds: disabledProfiles,
    );
  }
}

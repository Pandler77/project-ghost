class NotificationPreferences {
  const NotificationPreferences({
    this.notificationsEnabled = true,
    this.protocolRemindersEnabled = true,
    this.missedDoseFollowUpsEnabled = true,
  });

  final bool notificationsEnabled;
  final bool protocolRemindersEnabled;
  final bool missedDoseFollowUpsEnabled;

  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    bool? protocolRemindersEnabled,
    bool? missedDoseFollowUpsEnabled,
  }) {
    return NotificationPreferences(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      protocolRemindersEnabled:
          protocolRemindersEnabled ?? this.protocolRemindersEnabled,
      missedDoseFollowUpsEnabled:
          missedDoseFollowUpsEnabled ?? this.missedDoseFollowUpsEnabled,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'protocolRemindersEnabled': protocolRemindersEnabled,
      'missedDoseFollowUpsEnabled': missedDoseFollowUpsEnabled,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, Object?> map) {
    return NotificationPreferences(
      notificationsEnabled:
          map['notificationsEnabled'] as bool? ?? true,
      protocolRemindersEnabled:
          map['protocolRemindersEnabled'] as bool? ?? true,
      missedDoseFollowUpsEnabled:
          map['missedDoseFollowUpsEnabled'] as bool? ?? true,
    );
  }
}

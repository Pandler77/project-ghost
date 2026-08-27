enum ScheduleOverrideType {
  moveOccurrence,
  suppressOccurrence,
  extraOccurrence,
}

class ScheduleOverride {
  const ScheduleOverride({
    required this.id,
    required this.protocolId,
    required this.type,
    required this.createdAt,
    this.originalScheduledFor,
    this.overrideScheduledFor,
  });

  final String id;
  final String protocolId;
  final ScheduleOverrideType type;
  final DateTime createdAt;

  /// The occurrence produced by the protocol's normal recurring schedule.
  /// Null for an extra one-off occurrence.
  final DateTime? originalScheduledFor;

  /// Destination for moveOccurrence, or scheduled time for extraOccurrence.
  /// Null for suppressOccurrence.
  final DateTime? overrideScheduledFor;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'protocol_id': protocolId,
      'override_type': type.name,
      'original_scheduled_for': originalScheduledFor?.toIso8601String(),
      'override_scheduled_for': overrideScheduledFor?.toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory ScheduleOverride.fromMap(Map<String, Object?> map) {
    return ScheduleOverride(
      id: map['id'] as String,
      protocolId: map['protocol_id'] as String,
      type: ScheduleOverrideType.values.byName(map['override_type'] as String),
      originalScheduledFor: _parseDate(map['original_scheduled_for']),
      overrideScheduledFor: _parseDate(map['override_scheduled_for']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}

class ScheduledProtocolOccurrence {
  const ScheduledProtocolOccurrence({
    required this.protocolId,
    required this.scheduledFor,
    required this.isOverride,
    this.originalScheduledFor,
  });

  final String protocolId;
  final DateTime scheduledFor;
  final bool isOverride;
  final DateTime? originalScheduledFor;
}

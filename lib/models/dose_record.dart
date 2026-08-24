enum DoseRecordStatus { taken, skipped, missed }

class DoseRecord {
  const DoseRecord({
    required this.id,
    required this.protocolId,
    required this.scheduledFor,
    required this.scheduledAmount,
    required this.status,
    this.completedAt,
    this.actualAmount,
    this.protocolNameSnapshot,
    this.protocolTypeSnapshot,
    this.protocolColorValueSnapshot,
    this.advancedDoseJsonSnapshot,
  });

  final String id;
  final String protocolId;
  final DateTime scheduledFor;
  final DateTime? completedAt;
  final String scheduledAmount;
  final String? actualAmount;
  final DoseRecordStatus status;

  /// Immutable presentation/context captured when the record is saved.
  /// These are nullable so records created before database v38 remain valid.
  final String? protocolNameSnapshot;
  final String? protocolTypeSnapshot;
  final int? protocolColorValueSnapshot;
  final String? advancedDoseJsonSnapshot;

  DoseRecord copyWithSnapshot({
    String? protocolNameSnapshot,
    String? protocolTypeSnapshot,
    int? protocolColorValueSnapshot,
    String? advancedDoseJsonSnapshot,
  }) {
    return DoseRecord(
      id: id,
      protocolId: protocolId,
      scheduledFor: scheduledFor,
      completedAt: completedAt,
      scheduledAmount: scheduledAmount,
      actualAmount: actualAmount,
      status: status,
      protocolNameSnapshot:
          protocolNameSnapshot ?? this.protocolNameSnapshot,
      protocolTypeSnapshot:
          protocolTypeSnapshot ?? this.protocolTypeSnapshot,
      protocolColorValueSnapshot:
          protocolColorValueSnapshot ?? this.protocolColorValueSnapshot,
      advancedDoseJsonSnapshot:
          advancedDoseJsonSnapshot ?? this.advancedDoseJsonSnapshot,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'protocol_id': protocolId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'scheduled_amount': scheduledAmount,
      'actual_amount': actualAmount,
      'status': status.name,
      'protocol_name_snapshot': protocolNameSnapshot,
      'protocol_type_snapshot': protocolTypeSnapshot,
      'protocol_color_value_snapshot': protocolColorValueSnapshot,
      'advanced_dose_json_snapshot': advancedDoseJsonSnapshot,
    };
  }

  factory DoseRecord.fromMap(Map<String, Object?> map) {
    return DoseRecord(
      id: map['id'] as String,
      protocolId: map['protocol_id'] as String,
      scheduledFor: DateTime.parse(map['scheduled_for'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      scheduledAmount: map['scheduled_amount'] as String,
      actualAmount: map['actual_amount'] as String?,
      status: DoseRecordStatus.values.byName(map['status'] as String),
      protocolNameSnapshot: map['protocol_name_snapshot'] as String?,
      protocolTypeSnapshot: map['protocol_type_snapshot'] as String?,
      protocolColorValueSnapshot:
          (map['protocol_color_value_snapshot'] as num?)?.toInt(),
      advancedDoseJsonSnapshot:
          map['advanced_dose_json_snapshot'] as String?,
    );
  }
}

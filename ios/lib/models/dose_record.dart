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
  });

  final String id;
  final String protocolId;
  final DateTime scheduledFor;
  final DateTime? completedAt;
  final String scheduledAmount;
  final String? actualAmount;
  final DoseRecordStatus status;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'protocol_id': protocolId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'scheduled_amount': scheduledAmount,
      'actual_amount': actualAmount,
      'status': status.name,
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
    );
  }
}

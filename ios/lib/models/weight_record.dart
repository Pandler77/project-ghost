class WeightRecord {
  const WeightRecord({
    required this.id,
    required this.weight,
    required this.recordedAt,
  });

  final String id;
  final double weight;
  final DateTime recordedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'weight': weight,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  factory WeightRecord.fromMap(Map<String, Object?> map) {
    return WeightRecord(
      id: map['id'] as String,
      weight: (map['weight'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }
}

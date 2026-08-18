class SymptomEntry {
  const SymptomEntry({
    required this.id,
    required this.profileId,
    required this.symptomName,
    required this.severity,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String profileId;
  final String symptomName;
  final int severity;
  final String? notes;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SymptomEntry copyWith({
    String? id,
    String? profileId,
    String? symptomName,
    int? severity,
    String? notes,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SymptomEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      symptomName: symptomName ?? this.symptomName,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'symptom_name': symptomName,
      'severity': severity,
      'notes': notes,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SymptomEntry.fromMap(Map<String, Object?> map) {
    return SymptomEntry(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      symptomName: map['symptom_name'] as String,
      severity: map['severity'] as int,
      notes: map['notes'] as String?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

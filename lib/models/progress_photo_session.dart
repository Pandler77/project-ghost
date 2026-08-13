class ProgressPhotoSession {
  ProgressPhotoSession({
    String? id,
    required this.profileId,
    required this.recordedAt,
    this.weight,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  static const Object _unset = Object();

  final String id;
  final String profileId;

  final DateTime recordedAt;

  final double? weight;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  ProgressPhotoSession copyWith({
    String? id,
    String? profileId,
    DateTime? recordedAt,
    Object? weight = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressPhotoSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      recordedAt: recordedAt ?? this.recordedAt,
      weight: identical(weight, _unset) ? this.weight : weight as double?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'recorded_at': recordedAt.toIso8601String(),
      'weight': weight,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProgressPhotoSession.fromMap(Map<String, Object?> map) {
    return ProgressPhotoSession(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      weight: (map['weight'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

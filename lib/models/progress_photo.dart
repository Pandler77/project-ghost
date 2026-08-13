enum ProgressPhotoType { front, side, back, custom }

extension ProgressPhotoTypeDetails on ProgressPhotoType {
  String get label {
    return switch (this) {
      ProgressPhotoType.front => 'Front',
      ProgressPhotoType.side => 'Side',
      ProgressPhotoType.back => 'Back',
      ProgressPhotoType.custom => 'Custom',
    };
  }

  String get storageValue {
    return switch (this) {
      ProgressPhotoType.front => 'front',
      ProgressPhotoType.side => 'side',
      ProgressPhotoType.back => 'back',
      ProgressPhotoType.custom => 'custom',
    };
  }

  static ProgressPhotoType fromStorageValue(String? value) {
    return switch (value) {
      'front' => ProgressPhotoType.front,
      'side' => ProgressPhotoType.side,
      'back' => ProgressPhotoType.back,
      'custom' => ProgressPhotoType.custom,
      _ => ProgressPhotoType.custom,
    };
  }
}

class ProgressPhoto {
  ProgressPhoto({
    String? id,
    required this.profileId,
    required this.sessionId,
    required this.imagePath,
    required this.type,
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
  final String sessionId;
  final String imagePath;
  final ProgressPhotoType type;
  final DateTime recordedAt;
  final double? weight;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProgressPhoto copyWith({
    String? id,
    String? profileId,
    String? sessionId,
    String? imagePath,
    ProgressPhotoType? type,
    DateTime? recordedAt,
    Object? weight = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      sessionId: sessionId ?? this.sessionId,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
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
      'session_id': sessionId,
      'image_path': imagePath,
      'type': type.storageValue,
      'recorded_at': recordedAt.toIso8601String(),
      'weight': weight,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProgressPhoto.fromMap(Map<String, Object?> map) {
    return ProgressPhoto(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      sessionId: map['session_id'] as String,
      imagePath: map['image_path'] as String,
      type: ProgressPhotoTypeDetails.fromStorageValue(map['type'] as String?),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      weight: (map['weight'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

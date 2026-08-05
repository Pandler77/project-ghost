enum ProfileType { self, familyMember, child, pet, other }

extension ProfileTypeDetails on ProfileType {
  String get label {
    return switch (this) {
      ProfileType.self => 'Me',
      ProfileType.familyMember => 'Family member',
      ProfileType.child => 'Child',
      ProfileType.pet => 'Pet',
      ProfileType.other => 'Other',
    };
  }

  String get storageValue {
    return switch (this) {
      ProfileType.self => 'self',
      ProfileType.familyMember => 'family_member',
      ProfileType.child => 'child',
      ProfileType.pet => 'pet',
      ProfileType.other => 'other',
    };
  }

  static ProfileType fromStorageValue(String? value) {
    return switch (value) {
      'self' => ProfileType.self,
      'family_member' => ProfileType.familyMember,
      'child' => ProfileType.child,
      'pet' => ProfileType.pet,
      'other' => ProfileType.other,
      _ => ProfileType.self,
    };
  }
}

class Profile {
  Profile({
    String? id,
    required this.name,
    required this.type,
    this.iconCodePoint,
    this.colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  static const Object _unset = Object();

  final String id;
  final String name;
  final ProfileType type;
  final int? iconCodePoint;
  final int? colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile copyWith({
    String? id,
    String? name,
    ProfileType? type,
    Object? iconCodePoint = _unset,
    Object? colorValue = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: identical(iconCodePoint, _unset)
          ? this.iconCodePoint
          : iconCodePoint as int?,
      colorValue: identical(colorValue, _unset)
          ? this.colorValue
          : colorValue as int?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.storageValue,
      'icon_code_point': iconCodePoint,
      'color_value': colorValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, Object?> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ProfileTypeDetails.fromStorageValue(map['type'] as String?),
      iconCodePoint: (map['icon_code_point'] as num?)?.toInt(),
      colorValue: (map['color_value'] as num?)?.toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

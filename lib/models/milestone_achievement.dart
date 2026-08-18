enum MilestoneKind {
  weightLoss,
  goalWeight,
  doseCount,
}

class MilestoneAchievement {
  const MilestoneAchievement({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.title,
    required this.message,
    required this.achievedAt,
  });

  final String id;
  final String profileId;
  final MilestoneKind kind;
  final String title;
  final String message;
  final DateTime achievedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'kind': kind.name,
      'title': title,
      'message': message,
      'achievedAt': achievedAt.toIso8601String(),
    };
  }

  factory MilestoneAchievement.fromMap(Map<String, Object?> map) {
    return MilestoneAchievement(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      kind: MilestoneKind.values.byName(map['kind'] as String),
      title: map['title'] as String,
      message: map['message'] as String,
      achievedAt: DateTime.parse(map['achievedAt'] as String),
    );
  }
}

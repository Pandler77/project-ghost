enum TrackingFrequency { daily, weekly, monthly }

class TrackingPreferences {
  const TrackingPreferences({
    required this.trackWeight,
    required this.trackPhotos,
    required this.trackNotes,
    required this.weightFrequency,
    required this.photoFrequency,
  });

  final bool trackWeight;
  final bool trackPhotos;
  final bool trackNotes;
  final TrackingFrequency weightFrequency;
  final TrackingFrequency photoFrequency;

  static const defaults = TrackingPreferences(
    trackWeight: false,
    trackPhotos: false,
    trackNotes: false,
    weightFrequency: TrackingFrequency.weekly,
    photoFrequency: TrackingFrequency.monthly,
  );

  TrackingPreferences copyWith({
    bool? trackWeight,
    bool? trackPhotos,
    bool? trackNotes,
    TrackingFrequency? weightFrequency,
    TrackingFrequency? photoFrequency,
  }) {
    return TrackingPreferences(
      trackWeight: trackWeight ?? this.trackWeight,
      trackPhotos: trackPhotos ?? this.trackPhotos,
      trackNotes: trackNotes ?? this.trackNotes,
      weightFrequency: weightFrequency ?? this.weightFrequency,
      photoFrequency: photoFrequency ?? this.photoFrequency,
    );
  }
}

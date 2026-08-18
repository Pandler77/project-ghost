class DisplayPreferences {
  const DisplayPreferences({
    this.showGreeting = true,
    this.showProgressBar = true,
    this.showCompletedDoses = true,
    this.showUpcoming = true,
    this.showWeight = true,
    this.showRecentActivity = true,
    this.showCycleStatus = true,
    this.showCycleEndDate = true,
    this.showCycleRemainingDays = true,
    this.showCycleResumeDate = true,
    this.showProtocolColors = true,
    this.compactMode = false,
  });

  final bool showGreeting;
  final bool showProgressBar;
  final bool showCompletedDoses;
  final bool showUpcoming;
  final bool showWeight;
  final bool showRecentActivity;

  final bool showCycleStatus;
  final bool showCycleEndDate;
  final bool showCycleRemainingDays;
  final bool showCycleResumeDate;

  final bool showProtocolColors;
  final bool compactMode;

  DisplayPreferences copyWith({
    bool? showGreeting,
    bool? showProgressBar,
    bool? showCompletedDoses,
    bool? showUpcoming,
    bool? showWeight,
    bool? showRecentActivity,
    bool? showCycleStatus,
    bool? showCycleEndDate,
    bool? showCycleRemainingDays,
    bool? showCycleResumeDate,
    bool? showProtocolColors,
    bool? compactMode,
  }) {
    return DisplayPreferences(
      showGreeting: showGreeting ?? this.showGreeting,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      showCompletedDoses: showCompletedDoses ?? this.showCompletedDoses,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      showWeight: showWeight ?? this.showWeight,
      showRecentActivity: showRecentActivity ?? this.showRecentActivity,
      showCycleStatus: showCycleStatus ?? this.showCycleStatus,
      showCycleEndDate: showCycleEndDate ?? this.showCycleEndDate,
      showCycleRemainingDays:
          showCycleRemainingDays ?? this.showCycleRemainingDays,
      showCycleResumeDate: showCycleResumeDate ?? this.showCycleResumeDate,
      showProtocolColors: showProtocolColors ?? this.showProtocolColors,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'showGreeting': showGreeting,
      'showProgressBar': showProgressBar,
      'showCompletedDoses': showCompletedDoses,
      'showUpcoming': showUpcoming,
      'showWeight': showWeight,
      'showRecentActivity': showRecentActivity,
      'showCycleStatus': showCycleStatus,
      'showCycleEndDate': showCycleEndDate,
      'showCycleRemainingDays': showCycleRemainingDays,
      'showCycleResumeDate': showCycleResumeDate,
      'showProtocolColors': showProtocolColors,
      'compactMode': compactMode,
    };
  }

  factory DisplayPreferences.fromMap(Map<String, Object?> map) {
    return DisplayPreferences(
      showGreeting: map['showGreeting'] as bool? ?? true,
      showProgressBar: map['showProgressBar'] as bool? ?? true,
      showCompletedDoses: map['showCompletedDoses'] as bool? ?? true,
      showUpcoming: map['showUpcoming'] as bool? ?? true,
      showWeight: map['showWeight'] as bool? ?? true,
      showRecentActivity: map['showRecentActivity'] as bool? ?? true,
      showCycleStatus: map['showCycleStatus'] as bool? ?? true,
      showCycleEndDate: map['showCycleEndDate'] as bool? ?? true,
      showCycleRemainingDays: map['showCycleRemainingDays'] as bool? ?? true,
      showCycleResumeDate: map['showCycleResumeDate'] as bool? ?? true,
      showProtocolColors: map['showProtocolColors'] as bool? ?? true,
      compactMode: map['compactMode'] as bool? ?? false,
    );
  }
}

class CycleStatus {
  const CycleStatus({
    required this.isCycled,
    required this.isActive,
    required this.isBeforeStart,
    required this.currentCycleNumber,
    required this.dayInCurrentPhase,
    required this.totalDaysInCurrentPhase,
    required this.daysRemainingInCurrentPhase,
    required this.nextTransitionDate,
    required this.phaseLabel,
  });

  final bool isCycled;
  final bool isActive;
  final bool isBeforeStart;

  final int currentCycleNumber;
  final int dayInCurrentPhase;
  final int totalDaysInCurrentPhase;
  final int daysRemainingInCurrentPhase;

  final DateTime? nextTransitionDate;
  final String phaseLabel;
}

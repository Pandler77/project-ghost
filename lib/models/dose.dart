class Dose {
  Dose({
    required this.protocolId,
    required this.protocolName,
    required this.amount,
    required this.scheduledFor,
    required this.protocolColorValue,
    this.completedAt,
    this.cyclePrimaryLabel,
    this.cycleSecondaryLabel,
  });

  final String protocolId;
  final String protocolName;
  final String amount;
  final DateTime scheduledFor;
  final int protocolColorValue;

  final String? cyclePrimaryLabel;
  final String? cycleSecondaryLabel;

  DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  bool get hasCycleStatus {
    return cyclePrimaryLabel != null && cyclePrimaryLabel!.trim().isNotEmpty;
  }
}

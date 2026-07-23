class Dose {
  Dose({
    required this.protocolId,
    required this.protocolName,
    required this.amount,
    required this.scheduledFor,
    this.completedAt,
  });

  final String protocolId;
  final String protocolName;
  final String amount;
  final DateTime scheduledFor;

  DateTime? completedAt;

  bool get isCompleted => completedAt != null;
}
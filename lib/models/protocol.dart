class Protocol {
  Protocol({
    required this.name,
    required this.dose,
    required this.time,
    this.isTaken = false,
    this.completedAt,
  });

    final String name;
    final String dose;
    final String time;

    DateTime? completedAt;

    bool get isTaken => completedAt != null;
}
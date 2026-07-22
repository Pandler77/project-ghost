class Protocol {
  Protocol({
    required this.name,
    required this.dose,
    required this.time,
    this.isTaken = false,
  });

    final String name;
    final String dose;
    final String time;

    bool isTaken;
}
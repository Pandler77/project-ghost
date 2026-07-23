import 'protocol_schedule.dart';

class Protocol {
  Protocol({
    required this.name,
    required this.dose,
    required this.schedule,
    this.completedAt,
  });

    final String name;
    final String dose;
    final ProtocolSchedule schedule;

    DateTime? completedAt;

    bool get isTaken => completedAt != null;
}
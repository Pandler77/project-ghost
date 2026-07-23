import 'protocol_schedule.dart';

class Protocol {
  Protocol({
    required this.id,
    required this.name,
    required this.dose,
    required this.schedule,
  });

  final String id;
  final String name;
  final String dose;
  final ProtocolSchedule schedule;
}
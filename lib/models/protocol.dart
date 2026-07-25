import 'protocol_schedule.dart';
import 'protocol_status.dart';

class Protocol {
  Protocol({
    String? id,
    required this.name,
    required this.dose,
    required this.schedule,
    this.status = ProtocolStatus.active,
  }) : id = id ?? name;

  final String id;
  final String name;
  final String dose;
  final ProtocolSchedule schedule;

  ProtocolStatus status;
}

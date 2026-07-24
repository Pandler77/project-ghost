import '../models/protocol.dart';
import '../models/protocol_schedule.dart';

class ProtocolService {
  List<Protocol> getAllProtocols() {
    return [
      Protocol(
        id: 'reta-001',
        name: 'Retatrutide',
        dose: '3 mg',
        schedule: ProtocolSchedule.daily(
          startDate: DateTime(2026, 7, 22),
          hour: 22,
          minute: 0,
        ),
      ),

      Protocol(
        id: 'gluta1',
        name: 'Glutathione',
        dose: '100 mg',
        schedule: ProtocolSchedule.daily(
          startDate: DateTime(2026, 7, 22),
          hour: 11,
          minute: 0,
        ),
      ),

      Protocol(
        id: 'ghk-001',
        name: 'GHK-Cu',
        dose: '2 mg',
        schedule: ProtocolSchedule.daily(
          startDate: DateTime(2026, 7, 22),
          hour: 11,
          minute: 0,
        ),
      ),
    ];
  }
}

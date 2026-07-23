import '../models/protocol.dart';
import '../models/protocol_schedule.dart';

class ProtocolService {
  List<Protocol> getAllProtocols() {
    return [
      Protocol(
        name: 'Retatrutide',
        dose: '3 mg',
        schedule: const ProtocolSchedule.everyXDays(
          intervalDays: 6,
          hour: 22,
          minute: 0,
        ),
      ),
      Protocol(
        name: 'GHK-Cu',
        dose: '2 mg',
        schedule: const ProtocolSchedule.daily(
          hour: 22,
          minute: 5,
        ),
      ),
    ];
  }
}
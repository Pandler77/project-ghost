import '../models/dose.dart';
import '../models/protocol.dart';
import '../models/schedule_type.dart';

class DoseService {
  List<Dose> getTodaysDoses(List<Protocol> protocols) {
    final now = DateTime.now();

    return protocols
        .where(_isDoseToday)
        .map((protocol) {
          return Dose(
            protocolId: protocol.id,
            protocolName: protocol.name,
            amount: protocol.dose,
            scheduledFor: DateTime(
              now.year,
              now.month,
              now.day,
              protocol.schedule.hour,
              protocol.schedule.minute,
            ),
          );
        })
        .toList();
  }

  bool _isDoseToday(Protocol protocol) {
    final today = DateTime.now();

    final startDate = DateTime(
      protocol.schedule.startDate.year,
      protocol.schedule.startDate.month,
      protocol.schedule.startDate.day,
    );

    final currentDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final daysBetween = currentDate.difference(startDate).inDays;

    switch (protocol.schedule.type) {
      case ScheduleType.daily:
        return daysBetween >= 0;

      case ScheduleType.everyXDays:
        return daysBetween >= 0 &&
            daysBetween % protocol.schedule.intervalDays! == 0;
    }
  }
}
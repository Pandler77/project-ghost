import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../models/schedule_type.dart';
import 'cycle_service.dart';

class ProtocolScheduleService {
  const ProtocolScheduleService();

  static const CycleService _cycleService = CycleService();

  bool isScheduledOnDate(Protocol protocol, DateTime date) {
    if (protocol.status != ProtocolStatus.active) {
      return false;
    }

    if (!_cycleService.isProtocolActive(protocol, date)) {
      return false;
    }

    final schedule = protocol.schedule;

    final startDay = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );

    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay.isBefore(startDay)) {
      return false;
    }

    switch (schedule.type) {
      case ScheduleType.daily:
        return true;

      case ScheduleType.weekly:
        return selectedDay.weekday == schedule.weekday;

      case ScheduleType.everyXDays:
        final intervalDays = schedule.intervalDays;

        if (intervalDays == null || intervalDays <= 0) {
          return false;
        }

        final daysSinceStart = selectedDay.difference(startDay).inDays;

        return daysSinceStart % intervalDays == 0;

      case ScheduleType.specificDays:
        return schedule.specificWeekdays.contains(selectedDay.weekday);

      case ScheduleType.monthly:
        final configuredDay = schedule.monthlyDay;

        if (configuredDay == null) {
          return false;
        }

        final lastDayOfMonth = DateTime(
          selectedDay.year,
          selectedDay.month + 1,
          0,
        ).day;

        final safeDay = configuredDay > lastDayOfMonth
            ? lastDayOfMonth
            : configuredDay;

        return selectedDay.day == safeDay;
    }
  }

  List<Protocol> protocolsForDate(List<Protocol> protocols, DateTime date) {
    final scheduled = protocols
        .where((protocol) => isScheduledOnDate(protocol, date))
        .toList();

    scheduled.sort((first, second) {
      final firstMinutes = first.schedule.hour * 60 + first.schedule.minute;

      final secondMinutes = second.schedule.hour * 60 + second.schedule.minute;

      return firstMinutes.compareTo(secondMinutes);
    });

    return scheduled;
  }

  DateTime scheduledDateTime(Protocol protocol, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      protocol.schedule.hour,
      protocol.schedule.minute,
    );
  }
}

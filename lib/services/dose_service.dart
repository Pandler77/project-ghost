import '../models/dose.dart';
import '../models/protocol.dart';
import '../models/schedule_type.dart';

class DoseService {
  List<Dose> getTodaysDoses(List<Protocol> protocols) {
    final now = DateTime.now();

    return protocols.where(_isDoseToday).map((protocol) {
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
    }).toList();
  }

  Dose? getNextDose(List<Protocol> protocols) {
    if (protocols.isEmpty) {
      return null;
    }

    final upcomingDoses = protocols.map(_createNextDose).toList()
      ..sort(
        (first, second) => first.scheduledFor.compareTo(second.scheduledFor),
      );

    return upcomingDoses.first;
  }

  Dose _createNextDose(Protocol protocol) {
    final now = DateTime.now();

    final startDate = DateTime(
      protocol.schedule.startDate.year,
      protocol.schedule.startDate.month,
      protocol.schedule.startDate.day,
      protocol.schedule.hour,
      protocol.schedule.minute,
    );

    DateTime nextScheduledDate;

    switch (protocol.schedule.type) {
      case ScheduleType.daily:
        final todayScheduled = DateTime(
          now.year,
          now.month,
          now.day,
          protocol.schedule.hour,
          protocol.schedule.minute,
        );

        if (now.isBefore(startDate)) {
          nextScheduledDate = startDate;
        } else if (now.isBefore(todayScheduled)) {
          nextScheduledDate = todayScheduled;
        } else {
          nextScheduledDate = todayScheduled.add(const Duration(days: 1));
        }

      case ScheduleType.everyXDays:
        final intervalDays = protocol.schedule.intervalDays!;

        if (now.isBefore(startDate)) {
          nextScheduledDate = startDate;
          break;
        }

        final startDay = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );

        final today = DateTime(now.year, now.month, now.day);

        final daysSinceStart = today.difference(startDay).inDays;
        final remainder = daysSinceStart % intervalDays;

        var daysUntilNext = remainder == 0 ? 0 : intervalDays - remainder;

        nextScheduledDate = DateTime(
          today.year,
          today.month,
          today.day + daysUntilNext,
          protocol.schedule.hour,
          protocol.schedule.minute,
        );

        if (!nextScheduledDate.isAfter(now)) {
          daysUntilNext += intervalDays;

          nextScheduledDate = DateTime(
            today.year,
            today.month,
            today.day + daysUntilNext,
            protocol.schedule.hour,
            protocol.schedule.minute,
          );
        }
    }

    return Dose(
      protocolId: protocol.id,
      protocolName: protocol.name,
      amount: protocol.dose,
      scheduledFor: nextScheduledDate,
    );
  }

  bool _isDoseToday(Protocol protocol) {
    final today = DateTime.now();

    final startDate = DateTime(
      protocol.schedule.startDate.year,
      protocol.schedule.startDate.month,
      protocol.schedule.startDate.day,
    );

    final currentDate = DateTime(today.year, today.month, today.day);

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

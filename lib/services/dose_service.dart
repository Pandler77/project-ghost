import '../models/dose.dart';
import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../models/schedule_type.dart';

class DoseService {
  List<Dose> getTodaysDoses(List<Protocol> protocols) {
    final now = DateTime.now();

    return protocols
        .where(
          (protocol) =>
              protocol.status == ProtocolStatus.active &&
              _isDoseToday(protocol, now),
        )
        .map(
          (protocol) => Dose(
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
          ),
        )
        .toList();
  }

  Dose? getNextDose(List<Protocol> protocols) {
    final activeProtocols = protocols
        .where((protocol) => protocol.status == ProtocolStatus.active)
        .toList();

    if (activeProtocols.isEmpty) {
      return null;
    }

    final upcomingDoses = activeProtocols.map(_createNextDose).toList()
      ..sort(
        (first, second) => first.scheduledFor.compareTo(second.scheduledFor),
      );

    return upcomingDoses.first;
  }

  Dose _createNextDose(Protocol protocol) {
    final now = DateTime.now();
    final schedule = protocol.schedule;

    final startDateTime = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
      schedule.hour,
      schedule.minute,
    );

    if (now.isBefore(startDateTime)) {
      return _doseFrom(protocol, startDateTime);
    }

    switch (schedule.type) {
      case ScheduleType.daily:
        final today = DateTime(
          now.year,
          now.month,
          now.day,
          schedule.hour,
          schedule.minute,
        );

        return _doseFrom(
          protocol,
          today.isAfter(now) ? today : today.add(const Duration(days: 1)),
        );

      case ScheduleType.weekly:
        return _doseFrom(
          protocol,
          _nextWeeklyDate(
            now: now,
            weekday: schedule.weekday!,
            hour: schedule.hour,
            minute: schedule.minute,
          ),
        );

      case ScheduleType.everyXDays:
        return _doseFrom(
          protocol,
          _nextIntervalDate(
            now: now,
            startDate: schedule.startDate,
            intervalDays: schedule.intervalDays!,
            hour: schedule.hour,
            minute: schedule.minute,
          ),
        );

      case ScheduleType.specificDays:
        return _doseFrom(
          protocol,
          _nextSpecificWeekdayDate(
            now: now,
            weekdays: schedule.specificWeekdays,
            hour: schedule.hour,
            minute: schedule.minute,
          ),
        );

      case ScheduleType.monthly:
        return _doseFrom(
          protocol,
          _nextMonthlyDate(
            now: now,
            day: schedule.monthlyDay!,
            hour: schedule.hour,
            minute: schedule.minute,
          ),
        );
    }
  }

  bool _isDoseToday(Protocol protocol, DateTime now) {
    final schedule = protocol.schedule;

    final startDay = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );

    final today = DateTime(now.year, now.month, now.day);

    if (today.isBefore(startDay)) {
      return false;
    }

    switch (schedule.type) {
      case ScheduleType.daily:
        return true;

      case ScheduleType.weekly:
        return today.weekday == schedule.weekday;

      case ScheduleType.everyXDays:
        final daysBetween = today.difference(startDay).inDays;

        return daysBetween % schedule.intervalDays! == 0;

      case ScheduleType.specificDays:
        return schedule.specificWeekdays.contains(today.weekday);

      case ScheduleType.monthly:
        return today.day == schedule.monthlyDay;
    }
  }

  Dose _doseFrom(Protocol protocol, DateTime scheduledFor) {
    return Dose(
      protocolId: protocol.id,
      protocolName: protocol.name,
      amount: protocol.dose,
      scheduledFor: scheduledFor,
    );
  }

  DateTime _nextWeeklyDate({
    required DateTime now,
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final daysAhead = (weekday - now.weekday + 7) % 7;

    var candidate = DateTime(
      now.year,
      now.month,
      now.day + daysAhead,
      hour,
      minute,
    );

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }

    return candidate;
  }

  DateTime _nextIntervalDate({
    required DateTime now,
    required DateTime startDate,
    required int intervalDays,
    required int hour,
    required int minute,
  }) {
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);

    final today = DateTime(now.year, now.month, now.day);

    final daysSinceStart = today.difference(startDay).inDays;

    final remainder = daysSinceStart % intervalDays;

    var daysAhead = remainder == 0 ? 0 : intervalDays - remainder;

    var candidate = DateTime(
      today.year,
      today.month,
      today.day + daysAhead,
      hour,
      minute,
    );

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(Duration(days: intervalDays));
    }

    return candidate;
  }

  DateTime _nextSpecificWeekdayDate({
    required DateTime now,
    required Set<int> weekdays,
    required int hour,
    required int minute,
  }) {
    for (var offset = 0; offset < 14; offset++) {
      final candidateDay = now.add(Duration(days: offset));

      if (!weekdays.contains(candidateDay.weekday)) {
        continue;
      }

      final candidate = DateTime(
        candidateDay.year,
        candidateDay.month,
        candidateDay.day,
        hour,
        minute,
      );

      if (candidate.isAfter(now)) {
        return candidate;
      }
    }

    throw StateError('No valid specific weekday found.');
  }

  DateTime _nextMonthlyDate({
    required DateTime now,
    required int day,
    required int hour,
    required int minute,
  }) {
    DateTime buildCandidate(int year, int month) {
      final lastDay = DateTime(year, month + 1, 0).day;

      final safeDay = day > lastDay ? lastDay : day;

      return DateTime(year, month, safeDay, hour, minute);
    }

    var candidate = buildCandidate(now.year, now.month);

    if (!candidate.isAfter(now)) {
      candidate = buildCandidate(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
      );
    }

    return candidate;
  }
}

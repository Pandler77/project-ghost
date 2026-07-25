import 'schedule_type.dart';

class ProtocolSchedule {
  const ProtocolSchedule({
    required this.type,
    required this.startDate,
    required this.hour,
    required this.minute,
    this.intervalDays,
    this.weekday,
    this.specificWeekdays = const {},
    this.monthlyDay,
  });

  factory ProtocolSchedule.daily({
    required DateTime startDate,
    required int hour,
    required int minute,
  }) {
    return ProtocolSchedule(
      type: ScheduleType.daily,
      startDate: startDate,
      hour: hour,
      minute: minute,
    );
  }

  factory ProtocolSchedule.weekly({
    required DateTime startDate,
    required int hour,
    required int minute,
    required int weekday,
  }) {
    return ProtocolSchedule(
      type: ScheduleType.weekly,
      startDate: startDate,
      hour: hour,
      minute: minute,
      weekday: weekday,
    );
  }

  factory ProtocolSchedule.everyXDays({
    required DateTime startDate,
    required int hour,
    required int minute,
    required int intervalDays,
  }) {
    return ProtocolSchedule(
      type: ScheduleType.everyXDays,
      startDate: startDate,
      hour: hour,
      minute: minute,
      intervalDays: intervalDays,
    );
  }

  factory ProtocolSchedule.specificDays({
    required DateTime startDate,
    required int hour,
    required int minute,
    required Set<int> weekdays,
  }) {
    return ProtocolSchedule(
      type: ScheduleType.specificDays,
      startDate: startDate,
      hour: hour,
      minute: minute,
      specificWeekdays: weekdays,
    );
  }

  factory ProtocolSchedule.monthly({
    required DateTime startDate,
    required int hour,
    required int minute,
    required int day,
  }) {
    return ProtocolSchedule(
      type: ScheduleType.monthly,
      startDate: startDate,
      hour: hour,
      minute: minute,
      monthlyDay: day,
    );
  }

  final ScheduleType type;
  final DateTime startDate;
  final int hour;
  final int minute;

  final int? intervalDays;
  final int? weekday;
  final Set<int> specificWeekdays;
  final int? monthlyDay;
}

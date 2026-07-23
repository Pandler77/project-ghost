import 'schedule_type.dart';

class ProtocolSchedule {
  const ProtocolSchedule._({
    required this.type,
    required this.startDate,
    required this.hour,
    required this.minute,
    this.intervalDays,
  })  : assert(hour >= 0 && hour <= 23),
        assert(minute >= 0 && minute <= 59),
        assert(intervalDays == null || intervalDays > 0);

  const ProtocolSchedule.daily({
    required DateTime startDate,
    required int hour,
    required int minute,
  }) : this._(
          type: ScheduleType.daily,
          startDate: startDate,
          hour: hour,
          minute: minute,
        );

  const ProtocolSchedule.everyXDays({
    required DateTime startDate,
    required int intervalDays,
    required int hour,
    required int minute,
  }) : this._(
          type: ScheduleType.everyXDays,
          startDate: startDate,
          intervalDays: intervalDays,
          hour: hour,
          minute: minute,
        );

  final ScheduleType type;
  final DateTime startDate;
  final int hour;
  final int minute;
  final int? intervalDays;
}
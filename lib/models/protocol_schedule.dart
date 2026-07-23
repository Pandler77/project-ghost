import 'schedule_type.dart';

class ProtocolSchedule {
  const ProtocolSchedule._({
    required this.type,
    required this.hour,
    required this.minute,
    this.intervalDays,
  })  : assert(hour >= 0 && hour <= 23),
        assert(minute >= 0 && minute <= 59),
        assert(intervalDays == null || intervalDays > 0);

  const ProtocolSchedule.daily({
    required int hour,
    required int minute,
  }) : this._(
          type: ScheduleType.daily,
          hour: hour,
          minute: minute,
        );

  const ProtocolSchedule.everyXDays({
    required int intervalDays,
    required int hour,
    required int minute,
  }) : this._(
          type: ScheduleType.everyXDays,
          intervalDays: intervalDays,
          hour: hour,
          minute: minute,
        );

  final ScheduleType type;
  final int hour;
  final int minute;
  final int? intervalDays;
}
import 'protocol_schedule.dart';
import 'protocol_status.dart';
import 'schedule_type.dart';

class Protocol {
  Protocol({
    String? id,
    required this.name,
    required this.dose,
    required this.schedule,
    this.status = ProtocolStatus.active,
    this.colorValue = defaultColorValue,
  }) : id = id ?? name;

  static const int defaultColorValue = 0xFF6750A4;

  final String id;
  final String name;
  final String dose;
  final ProtocolSchedule schedule;

  ProtocolStatus status;
  int colorValue;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'status': status.name,
      'color_value': colorValue,
      'schedule_type': schedule.type.name,
      'start_date': schedule.startDate.toIso8601String(),
      'hour': schedule.hour,
      'minute': schedule.minute,
      'interval_days': schedule.intervalDays,
      'weekday': schedule.weekday,
      'specific_weekdays': schedule.specificWeekdays.isEmpty
          ? null
          : (schedule.specificWeekdays.toList()..sort()).join(','),
      'monthly_day': schedule.monthlyDay,
    };
  }

  factory Protocol.fromMap(Map<String, Object?> map) {
    final scheduleType = ScheduleType.values.byName(
      map['schedule_type'] as String,
    );

    final startDate = DateTime.parse(map['start_date'] as String);

    final hour = map['hour'] as int;
    final minute = map['minute'] as int;

    final schedule = switch (scheduleType) {
      ScheduleType.daily => ProtocolSchedule.daily(
        startDate: startDate,
        hour: hour,
        minute: minute,
      ),
      ScheduleType.weekly => ProtocolSchedule.weekly(
        startDate: startDate,
        hour: hour,
        minute: minute,
        weekday: map['weekday'] as int,
      ),
      ScheduleType.everyXDays => ProtocolSchedule.everyXDays(
        startDate: startDate,
        hour: hour,
        minute: minute,
        intervalDays: map['interval_days'] as int,
      ),
      ScheduleType.specificDays => ProtocolSchedule.specificDays(
        startDate: startDate,
        hour: hour,
        minute: minute,
        weekdays: _parseSpecificWeekdays(map['specific_weekdays'] as String?),
      ),
      ScheduleType.monthly => ProtocolSchedule.monthly(
        startDate: startDate,
        hour: hour,
        minute: minute,
        day: map['monthly_day'] as int,
      ),
    };

    return Protocol(
      id: map['id'] as String,
      name: map['name'] as String,
      dose: map['dose'] as String,
      status: ProtocolStatus.values.byName(map['status'] as String),
      colorValue: (map['color_value'] as int?) ?? defaultColorValue,
      schedule: schedule,
    );
  }

  static Set<int> _parseSpecificWeekdays(String? value) {
    if (value == null || value.trim().isEmpty) {
      return {};
    }

    return value.split(',').map((day) => int.parse(day)).toSet();
  }
}

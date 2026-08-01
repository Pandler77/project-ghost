import 'cycle_unit.dart';
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
    this.useCycle = false,
    this.cycleStartDate,
    this.cycleOnDuration = 1,
    this.cycleOnUnit = CycleUnit.weeks,
    this.cycleOffDuration = 0,
    this.cycleOffUnit = CycleUnit.weeks,
    this.repeatCycle = false,
  }) : id = id ?? name;

  static const int defaultColorValue = 0xFF6750A4;

  static const Object _unset = Object();

  final String id;
  final String name;
  final String dose;
  final ProtocolSchedule schedule;

  ProtocolStatus status;
  int colorValue;

  final bool useCycle;
  final DateTime? cycleStartDate;
  final int cycleOnDuration;
  final CycleUnit cycleOnUnit;
  final int cycleOffDuration;
  final CycleUnit cycleOffUnit;
  final bool repeatCycle;

  Protocol copyWith({
    String? id,
    String? name,
    String? dose,
    ProtocolSchedule? schedule,
    ProtocolStatus? status,
    int? colorValue,
    bool? useCycle,
    Object? cycleStartDate = _unset,
    int? cycleOnDuration,
    CycleUnit? cycleOnUnit,
    int? cycleOffDuration,
    CycleUnit? cycleOffUnit,
    bool? repeatCycle,
  }) {
    return Protocol(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      schedule: schedule ?? this.schedule,
      status: status ?? this.status,
      colorValue: colorValue ?? this.colorValue,
      useCycle: useCycle ?? this.useCycle,
      cycleStartDate: identical(cycleStartDate, _unset)
          ? this.cycleStartDate
          : cycleStartDate as DateTime?,
      cycleOnDuration: cycleOnDuration ?? this.cycleOnDuration,
      cycleOnUnit: cycleOnUnit ?? this.cycleOnUnit,
      cycleOffDuration: cycleOffDuration ?? this.cycleOffDuration,
      cycleOffUnit: cycleOffUnit ?? this.cycleOffUnit,
      repeatCycle: repeatCycle ?? this.repeatCycle,
    );
  }

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

      // Cycle settings
      'use_cycle': useCycle ? 1 : 0,
      'cycle_start_date': cycleStartDate?.toIso8601String(),
      'cycle_on_duration': cycleOnDuration,
      'cycle_on_unit': cycleOnUnit.storageValue,
      'cycle_off_duration': cycleOffDuration,
      'cycle_off_unit': cycleOffUnit.storageValue,
      'repeat_cycle': repeatCycle ? 1 : 0,
    };
  }

  factory Protocol.fromMap(Map<String, Object?> map) {
    final scheduleType = ScheduleType.values.byName(
      map['schedule_type'] as String,
    );

    final startDate = DateTime.parse(map['start_date'] as String);

    final hour = (map['hour'] as num).toInt();
    final minute = (map['minute'] as num).toInt();

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
        weekday: (map['weekday'] as num).toInt(),
      ),
      ScheduleType.everyXDays => ProtocolSchedule.everyXDays(
        startDate: startDate,
        hour: hour,
        minute: minute,
        intervalDays: (map['interval_days'] as num).toInt(),
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
        day: (map['monthly_day'] as num).toInt(),
      ),
    };

    final storedCycleStartDate = map['cycle_start_date'] as String?;

    return Protocol(
      id: map['id'] as String,
      name: map['name'] as String,
      dose: map['dose'] as String,
      status: ProtocolStatus.values.byName(map['status'] as String),
      colorValue: (map['color_value'] as num?)?.toInt() ?? defaultColorValue,
      schedule: schedule,
      useCycle: (map['use_cycle'] as num?)?.toInt() == 1,
      cycleStartDate: storedCycleStartDate == null
          ? null
          : DateTime.parse(storedCycleStartDate),
      cycleOnDuration: (map['cycle_on_duration'] as num?)?.toInt() ?? 1,
      cycleOnUnit: CycleUnitDetails.fromStorageValue(
        map['cycle_on_unit'] as String?,
        fallback: CycleUnit.weeks,
      ),
      cycleOffDuration: (map['cycle_off_duration'] as num?)?.toInt() ?? 0,
      cycleOffUnit: CycleUnitDetails.fromStorageValue(
        map['cycle_off_unit'] as String?,
        fallback: CycleUnit.weeks,
      ),
      repeatCycle: (map['repeat_cycle'] as num?)?.toInt() == 1,
    );
  }

  static Set<int> _parseSpecificWeekdays(String? value) {
    if (value == null || value.trim().isEmpty) {
      return {};
    }

    return value.split(',').map((day) => int.parse(day)).toSet();
  }
}

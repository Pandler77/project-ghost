import 'cycle_unit.dart';
import 'dose_details.dart';
import 'dose_unit.dart';
import 'injection_site.dart';
import 'protocol_schedule.dart';
import 'protocol_status.dart';
import 'protocol_type.dart';
import 'rotation_mode.dart';
import 'schedule_type.dart';
import 'protocol_category.dart';

class Protocol {
  Protocol({
    String? id,
    required this.name,
    this.type = ProtocolType.injection,
    String? dose,
    double? doseAmount,
    DoseUnit? doseUnit,
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
    this.rotationEnabled = false,
    this.rotationMode = RotationMode.sequential,
    Set<InjectionSite>? enabledInjectionSites,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 0,
    this.missedDoseReminderEnabled = false,
    this.missedDoseReminderMinutesAfter = 60,
    this.customReminderTitle,
    this.customReminderBody,
    this.customFollowUpTitle,
    this.customFollowUpBody,
    this.category = ProtocolCategory.custom,
    this.doseDetails,
  }) : assert(
         dose != null || doseAmount != null,
         'Either dose or doseAmount must be provided.',
       ),
       id = id ?? name,
       doseAmount = doseAmount ?? _parseDoseAmount(dose),
       doseUnit = doseUnit ?? _parseDoseUnit(dose),
       enabledInjectionSites = Set.unmodifiable(
         enabledInjectionSites ?? const <InjectionSite>{},
       );

  static const int defaultColorValue = 0xFF6750A4;
  static const Object _unset = Object();

  final String id;
  final String name;
  final ProtocolType type;
  final double doseAmount;
  final DoseUnit doseUnit;
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

  final bool rotationEnabled;
  final RotationMode rotationMode;
  final Set<InjectionSite> enabledInjectionSites;

  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final bool missedDoseReminderEnabled;
  final int missedDoseReminderMinutesAfter;

  /// Custom text for the primary scheduled reminder only.
  final String? customReminderTitle;
  final String? customReminderBody;

  /// Custom text for the missed-dose follow-up only.
  /// When null/blank, NotificationService uses the standard MODOSE follow-up.
  final String? customFollowUpTitle;
  final String? customFollowUpBody;

  final ProtocolCategory category;
  final DoseDetails? doseDetails;

  bool get isInjection => type == ProtocolType.injection;
  bool get hasAdvancedDoseDetails => doseDetails != null;

  String get dose => '${_formatAmount(doseAmount)} ${doseUnit.label}';

  String? get drawUnitsDisplay {
    final details = doseDetails;

    if (details == null || !details.showDrawUnitsOnCards) {
      return null;
    }

    final units = details.drawUnits(
      scheduledDoseAmount: doseAmount,
      scheduledDoseUnit: doseUnit,
    );

    if (units == null) {
      return null;
    }

    return 'Draw ${_formatAmount(units)} units';
  }

  Protocol copyWith({
    String? id,
    String? name,
    ProtocolType? type,
    ProtocolCategory? category,
    String? dose,
    double? doseAmount,
    DoseUnit? doseUnit,
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
    bool? rotationEnabled,
    RotationMode? rotationMode,
    Set<InjectionSite>? enabledInjectionSites,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    bool? missedDoseReminderEnabled,
    int? missedDoseReminderMinutesAfter,
    Object? customReminderTitle = _unset,
    Object? customReminderBody = _unset,
    Object? customFollowUpTitle = _unset,
    Object? customFollowUpBody = _unset,
    Object? doseDetails = _unset,
  }) {
    final parsedLegacyAmount = dose == null ? null : _parseDoseAmount(dose);
    final parsedLegacyUnit = dose == null ? null : _parseDoseUnit(dose);

    return Protocol(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      doseAmount: doseAmount ?? parsedLegacyAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? parsedLegacyUnit ?? this.doseUnit,
      doseDetails: identical(doseDetails, _unset)
          ? this.doseDetails
          : doseDetails as DoseDetails?,
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
      rotationEnabled: rotationEnabled ?? this.rotationEnabled,
      rotationMode: rotationMode ?? this.rotationMode,
      enabledInjectionSites:
          enabledInjectionSites ?? this.enabledInjectionSites,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      missedDoseReminderEnabled:
          missedDoseReminderEnabled ?? this.missedDoseReminderEnabled,
      missedDoseReminderMinutesAfter:
          missedDoseReminderMinutesAfter ?? this.missedDoseReminderMinutesAfter,
      customReminderTitle: identical(customReminderTitle, _unset)
          ? this.customReminderTitle
          : customReminderTitle as String?,
      customReminderBody: identical(customReminderBody, _unset)
          ? this.customReminderBody
          : customReminderBody as String?,
      customFollowUpTitle: identical(customFollowUpTitle, _unset)
          ? this.customFollowUpTitle
          : customFollowUpTitle as String?,
      customFollowUpBody: identical(customFollowUpBody, _unset)
          ? this.customFollowUpBody
          : customFollowUpBody as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'protocol_type': type.storageValue,
      'protocol_category': category.storageValue,
      'dose': dose,
      'dose_amount': doseAmount,
      'dose_unit': doseUnit.storageValue,
      'advanced_dose_json': doseDetails?.toJson(),
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
      'use_cycle': useCycle ? 1 : 0,
      'cycle_start_date': cycleStartDate?.toIso8601String(),
      'cycle_on_duration': cycleOnDuration,
      'cycle_on_unit': cycleOnUnit.storageValue,
      'cycle_off_duration': cycleOffDuration,
      'cycle_off_unit': cycleOffUnit.storageValue,
      'repeat_cycle': repeatCycle ? 1 : 0,
      'rotation_enabled': rotationEnabled ? 1 : 0,
      'rotation_mode': rotationMode.storageValue,
      'enabled_injection_sites': _encodeInjectionSites(enabledInjectionSites),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_minutes_before': reminderMinutesBefore,
      'missed_dose_reminder_enabled': missedDoseReminderEnabled ? 1 : 0,
      'missed_dose_reminder_minutes_after': missedDoseReminderMinutesAfter,
      'custom_reminder_title': customReminderTitle,
      'custom_reminder_body': customReminderBody,
      'custom_follow_up_title': customFollowUpTitle,
      'custom_follow_up_body': customFollowUpBody,
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
    final storedDoseAmount = (map['dose_amount'] as num?)?.toDouble();
    final storedDoseUnit = map['dose_unit'] as String?;
    final legacyDose = map['dose'] as String?;

    return Protocol(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ProtocolTypeDetails.fromStorageValue(
        map['protocol_type'] as String?,
      ),
      category: ProtocolCategoryDetails.fromStorageValue(
        map['protocol_category'] as String?,
      ),
      doseAmount: storedDoseAmount ?? _parseDoseAmount(legacyDose),
      doseUnit: storedDoseUnit == null
          ? _parseDoseUnit(legacyDose)
          : DoseUnitDetails.fromStorageValue(storedDoseUnit),
      doseDetails: DoseDetails.fromJson(map['advanced_dose_json'] as String?),
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
      rotationEnabled: (map['rotation_enabled'] as num?)?.toInt() == 1,
      rotationMode: RotationModeDetails.fromStorageValue(
        map['rotation_mode'] as String?,
      ),
      enabledInjectionSites: _decodeInjectionSites(
        map['enabled_injection_sites'] as String?,
      ),
      reminderEnabled: (map['reminder_enabled'] as num?)?.toInt() == 1,
      reminderMinutesBefore:
          (map['reminder_minutes_before'] as num?)?.toInt() ?? 0,
      missedDoseReminderEnabled:
          (map['missed_dose_reminder_enabled'] as num?)?.toInt() == 1,
      missedDoseReminderMinutesAfter:
          (map['missed_dose_reminder_minutes_after'] as num?)?.toInt() ?? 60,
      customReminderTitle: map['custom_reminder_title'] as String?,
      customReminderBody: map['custom_reminder_body'] as String?,
      customFollowUpTitle: map['custom_follow_up_title'] as String?,
      customFollowUpBody: map['custom_follow_up_body'] as String?,
    );
  }

  static double _parseDoseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 0;

    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
    return double.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static DoseUnit _parseDoseUnit(String? value) {
    if (value == null || value.trim().isEmpty) return DoseUnit.mg;

    final unitText = value.replaceAll(RegExp(r'[\d.\s]'), '');
    return DoseUnitDetails.fromStorageValue(unitText);
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static Set<int> _parseSpecificWeekdays(String? value) {
    if (value == null || value.trim().isEmpty) return {};

    return value.split(',').map((day) => int.parse(day)).toSet();
  }

  static String _encodeInjectionSites(Set<InjectionSite> sites) {
    final values = sites.map((site) => site.storageValue).toList()..sort();
    return values.join(',');
  }

  static Set<InjectionSite> _decodeInjectionSites(String? value) {
    if (value == null || value.trim().isEmpty) return {};

    return value
        .split(',')
        .map((item) => InjectionSiteDetails.fromStorageValue(item.trim()))
        .whereType<InjectionSite>()
        .toSet();
  }
}

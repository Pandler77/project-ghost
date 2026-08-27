import '../models/protocol.dart';
import '../models/schedule_override.dart';
import 'protocol_schedule_service.dart';

enum ReminderKind { primary, followUp }

class ScheduledReminder {
  const ScheduledReminder({
    required this.protocolId,
    required this.protocolName,
    required this.dose,
    required this.kind,
    required this.scheduledDoseTime,
    required this.notificationTime,
  });

  final String protocolId;
  final String protocolName;
  final String dose;
  final ReminderKind kind;

  final DateTime scheduledDoseTime;
  final DateTime notificationTime;

  bool get isPrimary => kind == ReminderKind.primary;
  bool get isFollowUp => kind == ReminderKind.followUp;
}

class ReminderScheduleService {
  const ReminderScheduleService();

  static const ProtocolScheduleService _scheduleService =
      ProtocolScheduleService();

  List<ScheduledReminder> upcomingReminders(
    Protocol protocol, {
    DateTime? from,
    int occurrenceLimit = 30,
    int searchLimitDays = 730,
    List<ScheduleOverride> overrides = const [],
  }) {
    final searchFrom = from ?? DateTime.now();

    if (!protocol.reminderEnabled) {
      return [];
    }

    if (occurrenceLimit <= 0 || searchLimitDays < 0) {
      return [];
    }

    final reminders = <ScheduledReminder>[];

    final firstSearchDay = DateTime(
      searchFrom.year,
      searchFrom.month,
      searchFrom.day,
    ).subtract(const Duration(days: 1));

    var scheduledOccurrenceCount = 0;

    for (var dayOffset = 0; dayOffset <= searchLimitDays + 1; dayOffset++) {
      final candidateDay = firstSearchDay.add(Duration(days: dayOffset));

      final occurrences = _scheduleService.occurrencesForDate(
        [protocol],
        candidateDay,
        overrides: overrides,
      );

      for (final occurrence in occurrences) {
        final scheduledDoseTime = occurrence.scheduledFor;

        final occurrenceReminders = remindersForOccurrence(
          protocol,
          scheduledDoseTime: scheduledDoseTime,
        );

        final upcomingForOccurrence = occurrenceReminders.where((reminder) {
          if (reminder.notificationTime.isAfter(searchFrom)) {
            return true;
          }

          return reminder.isPrimary &&
              _isSameMinute(reminder.notificationTime, searchFrom);
        }).toList();

        reminders.addAll(upcomingForOccurrence);

        if (scheduledDoseTime.isAfter(searchFrom) ||
            _isSameMinute(scheduledDoseTime, searchFrom)) {
          scheduledOccurrenceCount++;
        }

        if (scheduledOccurrenceCount >= occurrenceLimit) {
          break;
        }
      }

      if (scheduledOccurrenceCount >= occurrenceLimit) {
        break;
      }
    }

    reminders.sort(
      (first, second) =>
          first.notificationTime.compareTo(second.notificationTime),
    );

    return reminders;
  }

  List<ScheduledReminder> remindersForOccurrence(
    Protocol protocol, {
    required DateTime scheduledDoseTime,
  }) {
    if (!protocol.reminderEnabled) {
      return [];
    }

    final reminders = <ScheduledReminder>[];

    final primaryTime = scheduledDoseTime.subtract(
      Duration(minutes: protocol.reminderMinutesBefore),
    );

    reminders.add(
      ScheduledReminder(
        protocolId: protocol.id,
        protocolName: protocol.name,
        dose: protocol.dose,
        kind: ReminderKind.primary,
        scheduledDoseTime: scheduledDoseTime,
        notificationTime: primaryTime,
      ),
    );

    if (protocol.missedDoseReminderEnabled) {
      final followUpTime = scheduledDoseTime.add(
        Duration(minutes: protocol.missedDoseReminderMinutesAfter),
      );

      reminders.add(
        ScheduledReminder(
          protocolId: protocol.id,
          protocolName: protocol.name,
          dose: protocol.dose,
          kind: ReminderKind.followUp,
          scheduledDoseTime: scheduledDoseTime,
          notificationTime: followUpTime,
        ),
      );
    }

    reminders.sort(
      (first, second) =>
          first.notificationTime.compareTo(second.notificationTime),
    );

    return reminders;
  }

  ScheduledReminder? nextReminder(
    Protocol protocol, {
    DateTime? after,
    int searchLimitDays = 730,
    List<ScheduleOverride> overrides = const [],
  }) {
    final reminders = upcomingReminders(
      protocol,
      from: after,
      occurrenceLimit: 1,
      searchLimitDays: searchLimitDays,
      overrides: overrides,
    );

    if (reminders.isEmpty) {
      return null;
    }

    return reminders.first;
  }

  List<ScheduledReminder> upcomingRemindersForProtocols(
    List<Protocol> protocols, {
    DateTime? from,
    int occurrenceLimitPerProtocol = 30,
    int searchLimitDays = 730,
    List<ScheduleOverride> overrides = const [],
  }) {
    final reminders = <ScheduledReminder>[];

    for (final protocol in protocols) {
      reminders.addAll(
        upcomingReminders(
          protocol,
          from: from,
          occurrenceLimit: occurrenceLimitPerProtocol,
          searchLimitDays: searchLimitDays,
          overrides: overrides,
        ),
      );
    }

    reminders.sort(
      (first, second) =>
          first.notificationTime.compareTo(second.notificationTime),
    );

    return reminders;
  }

  bool _isSameMinute(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute;
  }
}

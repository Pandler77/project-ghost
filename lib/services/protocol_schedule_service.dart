import '../models/protocol.dart';
import '../models/schedule_override.dart';
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

  List<ScheduledProtocolOccurrence> occurrencesForDate(
    List<Protocol> protocols,
    DateTime date, {
    List<ScheduleOverride> overrides = const [],
  }) {
    final selectedDay = DateTime(date.year, date.month, date.day);
    final protocolById = <String, Protocol>{
      for (final protocol in protocols) protocol.id: protocol,
    };

    final overrideByOriginal = <String, ScheduleOverride>{};

    for (final override in overrides) {
      final original = override.originalScheduledFor;

      if (original == null) {
        continue;
      }

      overrideByOriginal[_occurrenceKey(override.protocolId, original)] =
          override;
    }

    final occurrences = <ScheduledProtocolOccurrence>[];

    for (final protocol in protocols) {
      if (!isScheduledOnDate(protocol, selectedDay)) {
        continue;
      }

      final original = scheduledDateTime(protocol, selectedDay);
      final override = overrideByOriginal[_occurrenceKey(protocol.id, original)];

      if (override == null) {
        occurrences.add(
          ScheduledProtocolOccurrence(
            protocolId: protocol.id,
            scheduledFor: original,
            isOverride: false,
          ),
        );
        continue;
      }

      if (override.type == ScheduleOverrideType.suppressOccurrence ||
          override.type == ScheduleOverrideType.moveOccurrence) {
        continue;
      }

      occurrences.add(
        ScheduledProtocolOccurrence(
          protocolId: protocol.id,
          scheduledFor: original,
          isOverride: false,
        ),
      );
    }

    for (final override in overrides) {
      final overrideTime = override.overrideScheduledFor;

      if (overrideTime == null || !_sameDay(overrideTime, selectedDay)) {
        continue;
      }

      final protocol = protocolById[override.protocolId];

      if (protocol == null || protocol.status != ProtocolStatus.active) {
        continue;
      }

      if (override.type == ScheduleOverrideType.moveOccurrence) {
        occurrences.add(
          ScheduledProtocolOccurrence(
            protocolId: protocol.id,
            scheduledFor: overrideTime,
            isOverride: true,
            originalScheduledFor: override.originalScheduledFor,
          ),
        );
      } else if (override.type == ScheduleOverrideType.extraOccurrence) {
        occurrences.add(
          ScheduledProtocolOccurrence(
            protocolId: protocol.id,
            scheduledFor: overrideTime,
            isOverride: true,
          ),
        );
      }
    }

    final unique = <String, ScheduledProtocolOccurrence>{};

    for (final occurrence in occurrences) {
      unique[_occurrenceKey(
        occurrence.protocolId,
        occurrence.scheduledFor,
      )] = occurrence;
    }

    final result = unique.values.toList()
      ..sort((first, second) => first.scheduledFor.compareTo(second.scheduledFor));

    return result;
  }

  DateTime? nextScheduledDateWithOverrides(
    Protocol protocol, {
    required DateTime after,
    List<ScheduleOverride> overrides = const [],
    int searchLimitDays = 730,
  }) {
    if (protocol.status != ProtocolStatus.active || searchLimitDays < 0) {
      return null;
    }

    final firstDay = DateTime(after.year, after.month, after.day);

    for (var dayOffset = 0; dayOffset <= searchLimitDays; dayOffset++) {
      final candidateDay = firstDay.add(Duration(days: dayOffset));
      final occurrences = occurrencesForDate(
        [protocol],
        candidateDay,
        overrides: overrides,
      );

      for (final occurrence in occurrences) {
        if (occurrence.scheduledFor.isAfter(after)) {
          return occurrence.scheduledFor;
        }
      }
    }

    return null;
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _occurrenceKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|${scheduledFor.toIso8601String()}';
  }

  DateTime? nextScheduledDate(
    Protocol protocol, {
    required DateTime after,
    int searchLimitDays = 730,
  }) {
    if (protocol.status != ProtocolStatus.active) {
      return null;
    }

    if (searchLimitDays < 0) {
      return null;
    }

    final firstDay = DateTime(after.year, after.month, after.day);

    for (var dayOffset = 0; dayOffset <= searchLimitDays; dayOffset++) {
      final candidateDay = firstDay.add(Duration(days: dayOffset));

      if (!isScheduledOnDate(protocol, candidateDay)) {
        continue;
      }

      final candidateDateTime = scheduledDateTime(protocol, candidateDay);

      if (candidateDateTime.isAfter(after)) {
        return candidateDateTime;
      }
    }

    return null;
  }

  DateTime? scheduledDateForToday(Protocol protocol, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    if (!isScheduledOnDate(protocol, currentTime)) {
      return null;
    }

    return scheduledDateTime(protocol, currentTime);
  }
}

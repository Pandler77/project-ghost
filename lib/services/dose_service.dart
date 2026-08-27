import '../models/dose.dart';
import '../models/protocol.dart';
import '../models/schedule_override.dart';
import '../services/cycle_status_formatter.dart';
import '../services/cycle_status_service.dart';
import '../services/protocol_schedule_service.dart';

class DoseService {
  static const ProtocolScheduleService _scheduleService =
      ProtocolScheduleService();

  static const CycleStatusService _cycleStatusService = CycleStatusService();

  static const CycleStatusFormatter _cycleStatusFormatter =
      CycleStatusFormatter();

  List<Dose> getTodaysDoses(
    List<Protocol> protocols, {
    DateTime? now,
    List<ScheduleOverride> overrides = const [],
  }) {
    final currentTime = now ?? DateTime.now();

    final occurrences = _scheduleService.occurrencesForDate(
      protocols,
      currentTime,
      overrides: overrides,
    );

    final protocolById = <String, Protocol>{
      for (final protocol in protocols) protocol.id: protocol,
    };

    return occurrences
        .map((occurrence) {
          final protocol = protocolById[occurrence.protocolId];

          if (protocol == null) {
            return null;
          }

          return _doseFrom(protocol, occurrence.scheduledFor);
        })
        .whereType<Dose>()
        .toList();
  }

  Dose? getNextDose(
    List<Protocol> protocols, {
    DateTime? after,
    List<ScheduleOverride> overrides = const [],
  }) {
    final searchFrom = after ?? DateTime.now();
    final upcomingDoses = <Dose>[];

    for (final protocol in protocols) {
      final scheduledFor = _scheduleService.nextScheduledDateWithOverrides(
        protocol,
        after: searchFrom,
        overrides: overrides,
      );

      if (scheduledFor == null) {
        continue;
      }

      upcomingDoses.add(_doseFrom(protocol, scheduledFor));
    }

    if (upcomingDoses.isEmpty) {
      return null;
    }

    upcomingDoses.sort(
      (first, second) => first.scheduledFor.compareTo(second.scheduledFor),
    );

    return upcomingDoses.first;
  }

  Dose _doseFrom(Protocol protocol, DateTime scheduledFor) {
    final cycleStatus = _cycleStatusService.statusForDate(
      protocol,
      scheduledFor,
    );

    final shouldShowCycleStatus = cycleStatus.isCycled;

    return Dose(
      protocolId: protocol.id,
      protocolName: protocol.name,
      amount: protocol.dose,
      scheduledFor: scheduledFor,
      protocolColorValue: protocol.colorValue,
      cycleStatus: shouldShowCycleStatus ? cycleStatus : null,
      cyclePrimaryLabel: shouldShowCycleStatus
          ? _cycleStatusFormatter.primaryLabel(cycleStatus)
          : null,
      cycleSecondaryLabel: shouldShowCycleStatus
          ? _cycleStatusFormatter.secondaryLabel(cycleStatus)
          : null,
    );
  }
}

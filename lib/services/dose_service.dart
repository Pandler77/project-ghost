import '../models/dose.dart';
import '../models/protocol.dart';
import '../services/cycle_status_formatter.dart';
import '../services/cycle_status_service.dart';
import '../services/protocol_schedule_service.dart';

class DoseService {
  static const ProtocolScheduleService _scheduleService =
      ProtocolScheduleService();

  static const CycleStatusService _cycleStatusService = CycleStatusService();

  static const CycleStatusFormatter _cycleStatusFormatter =
      CycleStatusFormatter();

  List<Dose> getTodaysDoses(List<Protocol> protocols, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    final scheduledProtocols = _scheduleService.protocolsForDate(
      protocols,
      currentTime,
    );

    return scheduledProtocols
        .map(
          (protocol) => _doseFrom(
            protocol,
            _scheduleService.scheduledDateTime(protocol, currentTime),
          ),
        )
        .toList();
  }

  Dose? getNextDose(List<Protocol> protocols, {DateTime? after}) {
    final searchFrom = after ?? DateTime.now();
    final upcomingDoses = <Dose>[];

    for (final protocol in protocols) {
      final scheduledFor = _scheduleService.nextScheduledDate(
        protocol,
        after: searchFrom,
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
      cyclePrimaryLabel: shouldShowCycleStatus
          ? _cycleStatusFormatter.primaryLabel(cycleStatus)
          : null,
      cycleSecondaryLabel: shouldShowCycleStatus
          ? _cycleStatusFormatter.secondaryLabel(cycleStatus)
          : null,
    );
  }
}

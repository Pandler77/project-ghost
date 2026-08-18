import '../models/dose_record.dart';
import '../models/protocol.dart';
import 'app_data_service.dart';
import 'protocol_schedule_service.dart';

class MissedDoseReconciliationService {
  const MissedDoseReconciliationService({
    this._scheduleService = const ProtocolScheduleService(),
  });

  final ProtocolScheduleService _scheduleService;

  Future<int> reconcile({
    required AppDataService dataService,
    required List<Protocol> protocols,
    DateTime? now,
    int lookbackDays = 730,
  }) async {
    final currentTime = now ?? DateTime.now();

    if (lookbackDays <= 0) {
      return 0;
    }

    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    final existingRecords = await dataService.getAllDoseRecords();

    // Today's unresolved dose stays actionable until midnight.
    for (final record in existingRecords) {
      if (record.status != DoseRecordStatus.missed ||
          record.completedAt != null) {
        continue;
      }

      final scheduledDay = DateTime(
        record.scheduledFor.year,
        record.scheduledFor.month,
        record.scheduledFor.day,
      );

      if (scheduledDay == today) {
        await dataService.deleteDoseRecord(
          protocolId: record.protocolId,
          scheduledFor: record.scheduledFor,
        );
      }
    }

    final refreshedRecords = await dataService.getAllDoseRecords();

    final existingKeys = <String>{
      for (final record in refreshedRecords)
        _recordKey(record.protocolId, record.scheduledFor),
    };

    final globalLookbackStart = today.subtract(Duration(days: lookbackDays));

    var createdCount = 0;

    for (final protocol in protocols) {
      // New protocols use a microsecond timestamp as their ID. That gives us
      // a reliable "ArcticDose started tracking this protocol" boundary even when
      // the schedule itself began months earlier.
      final trackingStart = _trackingStartDate(
        protocol,
        fallback: globalLookbackStart,
      );

      final protocolStart = DateTime(
        protocol.schedule.startDate.year,
        protocol.schedule.startDate.month,
        protocol.schedule.startDate.day,
      );

      var startDate = protocolStart.isAfter(globalLookbackStart)
          ? protocolStart
          : globalLookbackStart;

      if (trackingStart.isAfter(startDate)) {
        startDate = trackingStart;
      }

      // Never create a missed record for the same calendar day the protocol
      // was first added to ArcticDose. Tracking becomes authoritative after that.
      if (!startDate.isBefore(today)) {
        continue;
      }

      for (
        var date = startDate;
        date.isBefore(today);
        date = date.add(const Duration(days: 1))
      ) {
        if (!_scheduleService.isScheduledOnDate(protocol, date)) {
          continue;
        }

        final scheduledFor = _scheduleService.scheduledDateTime(protocol, date);

        final key = _recordKey(protocol.id, scheduledFor);

        if (existingKeys.contains(key)) {
          continue;
        }

        final record = DoseRecord(
          id: '${protocol.id}_${scheduledFor.microsecondsSinceEpoch}',
          protocolId: protocol.id,
          scheduledFor: scheduledFor,
          scheduledAmount: protocol.dose,
          status: DoseRecordStatus.missed,
        );

        await dataService.saveDoseRecord(record);

        existingKeys.add(key);
        createdCount++;
      }
    }

    return createdCount;
  }

  DateTime _trackingStartDate(Protocol protocol, {required DateTime fallback}) {
    final rawId = int.tryParse(protocol.id);

    if (rawId == null) {
      return fallback;
    }

    try {
      final createdAt = DateTime.fromMicrosecondsSinceEpoch(rawId);

      // Reject IDs that happen to be numeric but are not plausible timestamps.
      if (createdAt.year < 2020 || createdAt.year > 2100) {
        return fallback;
      }

      return DateTime(createdAt.year, createdAt.month, createdAt.day);
    } catch (_) {
      return fallback;
    }
  }

  String _recordKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|${scheduledFor.toIso8601String()}';
  }
}

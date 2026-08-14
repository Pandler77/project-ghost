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

    // Under Ghost's day-based behavior, a dose remains actionable for the
    // entire scheduled calendar day. Remove stale system-generated "missed"
    // records for today that may have been created by older app versions.
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

    final startDate = today.subtract(Duration(days: lookbackDays));

    var createdCount = 0;

    // Only dates before today can become historical misses. Today's dose
    // stays actionable until local midnight, regardless of scheduled time.
    for (
      var date = startDate;
      date.isBefore(today);
      date = date.add(const Duration(days: 1))
    ) {
      for (final protocol in protocols) {
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

  String _recordKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|${scheduledFor.toIso8601String()}';
  }
}

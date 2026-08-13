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

    final existingRecords = await dataService.getAllDoseRecords();

    final existingKeys = <String>{
      for (final record in existingRecords)
        _recordKey(record.protocolId, record.scheduledFor),
    };

    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    final startDate = today.subtract(Duration(days: lookbackDays));

    var createdCount = 0;

    for (
      var date = startDate;
      !date.isAfter(today);
      date = date.add(const Duration(days: 1))
    ) {
      for (final protocol in protocols) {
        if (!_scheduleService.isScheduledOnDate(protocol, date)) {
          continue;
        }

        final scheduledFor = _scheduleService.scheduledDateTime(protocol, date);

        // Today only becomes missed after the exact scheduled time passes.
        if (!scheduledFor.isBefore(currentTime)) {
          continue;
        }

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

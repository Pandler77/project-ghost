import 'dose_record.dart';
import 'protocol.dart';

class CalendarDaySummary {
  const CalendarDaySummary({
    required this.date,
    required this.protocols,
    required this.records,
  });

  final DateTime date;

  final List<Protocol> protocols;

  final List<DoseRecord> records;

  int get scheduledCount => protocols.length;

  int get completedCount =>
      records.where((r) => r.status == DoseRecordStatus.taken).length;

  int get missedCount =>
      records.where((r) => r.status == DoseRecordStatus.missed).length;

  double get completionRatio {
    if (scheduledCount == 0) {
      return 0;
    }

    return completedCount / scheduledCount;
  }

  bool get isFullyCompleted =>
      scheduledCount > 0 && completedCount == scheduledCount;

  bool get hasCompletion => completedCount > 0;
}

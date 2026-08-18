import 'dose_record.dart';
import 'protocol.dart';

class DailyProtocolItem {
  const DailyProtocolItem({
    required this.protocol,
    required this.scheduledFor,
    required this.record,
  });

  final Protocol protocol;
  final DateTime scheduledFor;
  final DoseRecord? record;

  bool get isTaken => record?.status == DoseRecordStatus.taken;

  String get displayedAmount => record?.actualAmount ?? protocol.dose;
}

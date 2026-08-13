import 'cycle_status.dart';
import 'dose_record.dart';

class Dose {
  Dose({
    required this.protocolId,
    required this.protocolName,
    required this.amount,
    required this.scheduledFor,
    required this.protocolColorValue,
    this.status,
    this.completedAt,
    this.cycleStatus,
    this.cyclePrimaryLabel,
    this.cycleSecondaryLabel,
    this.injectionSiteLabel,
  });

  final String protocolId;
  final String protocolName;
  final String amount;
  final DateTime scheduledFor;
  final int protocolColorValue;

  /// Structured cycle data used by UI display preferences.
  final CycleStatus? cycleStatus;

  /// Legacy formatted values kept for compatibility with any other widgets
  /// that still consume the existing Dose API.
  final String? cyclePrimaryLabel;
  final String? cycleSecondaryLabel;

  DoseRecordStatus? status;
  String? injectionSiteLabel;
  DateTime? completedAt;

  bool get isCompleted => status == DoseRecordStatus.taken;

  bool get isSkipped => status == DoseRecordStatus.skipped;

  bool get isResolved =>
      status == DoseRecordStatus.taken ||
      status == DoseRecordStatus.skipped ||
      status == DoseRecordStatus.missed;

  bool get hasCycleStatus {
    return cycleStatus?.isCycled == true ||
        (cyclePrimaryLabel != null && cyclePrimaryLabel!.trim().isNotEmpty);
  }

  bool get hasInjectionSite {
    return injectionSiteLabel != null && injectionSiteLabel!.trim().isNotEmpty;
  }
}

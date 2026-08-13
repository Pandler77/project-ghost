import '../models/dose.dart';
import '../models/dose_record.dart';
import '../models/injection_log.dart';
import '../models/inventory_batch.dart';
import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../models/take_dose_result.dart';
import 'app_data_service.dart';

class InventoryRolloverCheck {
  const InventoryRolloverCheck({
    required this.item,
    required this.availableBatches,
    required this.doseAmount,
    required this.requiresNewContainer,
  });

  final InventoryItem item;
  final List<InventoryBatch> availableBatches;
  final double doseAmount;
  final bool requiresNewContainer;

  bool get hasInventoryOptions => availableBatches.isNotEmpty;

  bool get hasMultipleBatches => availableBatches.length > 1;
}

class DoseCompletionService {
  DoseCompletionService(this._dataService);

  final AppDataService _dataService;

  Future<InventoryRolloverCheck?> checkInventoryRollover({
    required Protocol protocol,
    required TakeDoseResult result,
  }) async {
    if (!_dataService.hasPremium) {
      return null;
    }

    final item = await _dataService.getInventoryItemForProtocol(protocol.id);

    if (item == null) {
      return null;
    }

    final doseAmount = result.actualDoseAmount;

    if (doseAmount <= 0) {
      return null;
    }

    if (item.currentAmount >= doseAmount) {
      return InventoryRolloverCheck(
        item: item,
        availableBatches: const [],
        doseAmount: doseAmount,
        requiresNewContainer: false,
      );
    }

    final batches = await _dataService.getInventoryBatchesForItem(item.id);

    final availableBatches = batches
        .where((batch) => batch.quantity > 0)
        .toList(growable: false);

    return InventoryRolloverCheck(
      item: item,
      availableBatches: availableBatches,
      doseAmount: doseAmount,
      requiresNewContainer: true,
    );
  }

  Future<Protocol?> completeDose({
    required Dose dose,
    required Protocol protocol,
    required TakeDoseResult result,
    String? preferredInventoryBatchId,
  }) async {
    final completedAt = DateTime.now();

    final record = DoseRecord(
      id:
          '${dose.protocolId}-'
          '${dose.scheduledFor.microsecondsSinceEpoch}',
      protocolId: dose.protocolId,
      scheduledFor: dose.scheduledFor,
      scheduledAmount: dose.amount,
      actualAmount: result.formattedDose,
      completedAt: completedAt,
      status: DoseRecordStatus.taken,
    );

    await _dataService.saveDoseRecord(
      record,
      preferredInventoryBatchId: preferredInventoryBatchId,
    );

    if (result.injectionSite != null) {
      final log = InjectionLog(
        protocolId: protocol.id,
        doseRecordId: record.id,
        site: result.injectionSite!,
        loggedAt: completedAt,
      );

      await _dataService.saveInjectionLog(log);
    }

    if (!result.shouldUpdateFutureDoses) {
      return null;
    }

    final updatedProtocol = protocol.copyWith(
      doseAmount: result.actualDoseAmount,
      doseUnit: result.actualDoseUnit,
    );

    await _dataService.updateProtocol(updatedProtocol);

    return updatedProtocol;
  }
}

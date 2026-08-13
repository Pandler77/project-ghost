import '../models/inventory_batch.dart';
import '../models/inventory_item.dart';

class InventoryDeductionResult {
  const InventoryDeductionResult({
    required this.item,
    required this.batches,
    required this.amountRequested,
    required this.amountDeducted,
    required this.vialsOpened,
    required this.hadEnoughStock,
  });

  final InventoryItem item;
  final List<InventoryBatch> batches;
  final double amountRequested;
  final double amountDeducted;
  final int vialsOpened;
  final bool hadEnoughStock;
}

class InventoryService {
  const InventoryService();

  InventoryDeductionResult deductDose({
    required InventoryItem item,
    required List<InventoryBatch> batches,
    required double doseAmount,
    String? preferredBatchId,
    DateTime? completedAt,
  }) {
    if (doseAmount <= 0) {
      return InventoryDeductionResult(
        item: item,
        batches: List<InventoryBatch>.from(batches),
        amountRequested: doseAmount,
        amountDeducted: 0,
        vialsOpened: 0,
        hadEnoughStock: true,
      );
    }

    final unopenedAmount = batches.fold<double>(
      0,
      (total, batch) => batch.quantity <= 0 ? total : total + batch.totalAmount,
    );

    if (item.currentAmount + unopenedAmount < doseAmount) {
      return InventoryDeductionResult(
        item: item,
        batches: List<InventoryBatch>.from(batches),
        amountRequested: doseAmount,
        amountDeducted: 0,
        vialsOpened: 0,
        hadEnoughStock: false,
      );
    }

    final workingBatches = List<InventoryBatch>.from(batches);

    var amountRemainingToDeduct = doseAmount;
    var currentAmount = item.currentAmount;
    var currentVialSize = item.vialSize;
    var currentUnit = item.unit;
    var openedAt = item.currentContainerOpenedAt;
    var currentContainerBatchId = item.currentContainerBatchId;
    var vialsOpened = 0;
    var preferredBatchStillRequired = preferredBatchId != null;

    while (amountRemainingToDeduct > 0) {
      if (currentAmount <= 0) {
        int batchIndex;

        if (preferredBatchStillRequired) {
          batchIndex = workingBatches.indexWhere(
            (batch) => batch.id == preferredBatchId && batch.quantity > 0,
          );

          if (batchIndex == -1) {
            return InventoryDeductionResult(
              item: item,
              batches: List<InventoryBatch>.from(batches),
              amountRequested: doseAmount,
              amountDeducted: 0,
              vialsOpened: 0,
              hadEnoughStock: false,
            );
          }

          preferredBatchStillRequired = false;
        } else {
          batchIndex = workingBatches.indexWhere((batch) => batch.quantity > 0);
        }

        if (batchIndex == -1) {
          return InventoryDeductionResult(
            item: item,
            batches: List<InventoryBatch>.from(batches),
            amountRequested: doseAmount,
            amountDeducted: 0,
            vialsOpened: 0,
            hadEnoughStock: false,
          );
        }

        final batch = workingBatches[batchIndex];

        currentVialSize = batch.containerSize;
        currentUnit = batch.unit;
        currentAmount = batch.containerSize;
        currentContainerBatchId = batch.id;
        openedAt = completedAt ?? DateTime.now();
        vialsOpened++;

        workingBatches[batchIndex] = batch.copyWith(
          quantity: (batch.quantity - 1).clamp(0, batch.quantity),
          updatedAt: DateTime.now(),
        );
      }

      final amountFromCurrentVial = amountRemainingToDeduct <= currentAmount
          ? amountRemainingToDeduct
          : currentAmount;

      currentAmount -= amountFromCurrentVial;
      amountRemainingToDeduct -= amountFromCurrentVial;
    }

    currentAmount = _normalizeAmount(currentAmount);

    if (currentAmount <= 0) {
      openedAt = null;
      currentContainerBatchId = null;
    }

    final updatedItem = item.copyWith(
      vialSize: currentVialSize,
      currentAmount: currentAmount,
      unit: currentUnit,
      currentContainerOpenedAt: openedAt,
      currentContainerBatchId: currentContainerBatchId,
      updatedAt: DateTime.now(),
    );

    return InventoryDeductionResult(
      item: updatedItem,
      batches: workingBatches,
      amountRequested: doseAmount,
      amountDeducted: doseAmount,
      vialsOpened: vialsOpened,
      hadEnoughStock: true,
    );
  }

  double dosesRemaining({
    required double totalRemaining,
    required double doseAmount,
  }) {
    if (doseAmount <= 0) {
      return 0;
    }

    return totalRemaining / doseAmount;
  }

  int wholeDosesRemaining({
    required double totalRemaining,
    required double doseAmount,
  }) {
    return dosesRemaining(
      totalRemaining: totalRemaining,
      doseAmount: doseAmount,
    ).floor();
  }

  bool shouldReorder({
    required int unopenedContainerCount,
    required int lowStockThreshold,
  }) {
    return unopenedContainerCount <= lowStockThreshold;
  }

  double _normalizeAmount(double value) {
    if (value.abs() < 0.000001) {
      return 0;
    }

    return double.parse(value.toStringAsFixed(6));
  }
}

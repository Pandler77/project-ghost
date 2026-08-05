import '../models/inventory_item.dart';

class InventoryDeductionResult {
  const InventoryDeductionResult({
    required this.item,
    required this.amountRequested,
    required this.amountDeducted,
    required this.vialsOpened,
    required this.hadEnoughStock,
  });

  final InventoryItem item;
  final double amountRequested;
  final double amountDeducted;
  final int vialsOpened;
  final bool hadEnoughStock;
}

class InventoryService {
  const InventoryService();

  InventoryDeductionResult deductDose({
    required InventoryItem item,
    required double doseAmount,
    DateTime? completedAt,
  }) {
    if (doseAmount <= 0) {
      return InventoryDeductionResult(
        item: item,
        amountRequested: doseAmount,
        amountDeducted: 0,
        vialsOpened: 0,
        hadEnoughStock: true,
      );
    }

    if (item.vialSize <= 0) {
      return InventoryDeductionResult(
        item: item,
        amountRequested: doseAmount,
        amountDeducted: 0,
        vialsOpened: 0,
        hadEnoughStock: false,
      );
    }

    if (item.totalRemaining < doseAmount) {
      return InventoryDeductionResult(
        item: item,
        amountRequested: doseAmount,
        amountDeducted: 0,
        vialsOpened: 0,
        hadEnoughStock: false,
      );
    }

    var amountRemainingToDeduct = doseAmount;
    var currentAmount = item.currentAmount;
    var unopenedQuantity = item.unopenedQuantity;
    var openedAt = item.currentContainerOpenedAt;
    var vialsOpened = 0;

    while (amountRemainingToDeduct > 0) {
      if (currentAmount <= 0) {
        if (unopenedQuantity <= 0) {
          return InventoryDeductionResult(
            item: item,
            amountRequested: doseAmount,
            amountDeducted: 0,
            vialsOpened: 0,
            hadEnoughStock: false,
          );
        }

        currentAmount = item.vialSize;
        unopenedQuantity--;
        vialsOpened++;

        openedAt = completedAt ?? DateTime.now();
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
    }

    final updatedItem = item.copyWith(
      currentAmount: currentAmount,
      unopenedQuantity: unopenedQuantity,
      currentContainerOpenedAt: openedAt,
      updatedAt: DateTime.now(),
    );

    return InventoryDeductionResult(
      item: updatedItem,
      amountRequested: doseAmount,
      amountDeducted: doseAmount,
      vialsOpened: vialsOpened,
      hadEnoughStock: true,
    );
  }

  double dosesRemaining({
    required InventoryItem item,
    required double doseAmount,
  }) {
    if (doseAmount <= 0) {
      return 0;
    }

    return item.totalRemaining / doseAmount;
  }

  int wholeDosesRemaining({
    required InventoryItem item,
    required double doseAmount,
  }) {
    return dosesRemaining(item: item, doseAmount: doseAmount).floor();
  }

  bool shouldReorder(InventoryItem item) {
    return item.unopenedQuantity <= item.lowStockThreshold;
  }

  double _normalizeAmount(double value) {
    if (value.abs() < 0.000001) {
      return 0;
    }

    return double.parse(value.toStringAsFixed(6));
  }
}

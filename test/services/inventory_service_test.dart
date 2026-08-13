import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/inventory_batch.dart';
import 'package:project_ghost/models/inventory_item.dart';
import 'package:project_ghost/services/inventory_service.dart';

void main() {
  const service = InventoryService();

  InventoryItem createItem({
    double vialSize = 10,
    double currentAmount = 10,
    String? currentContainerBatchId,
  }) {
    return InventoryItem(
      id: 'inventory-1',
      protocolId: 'protocol-1',
      vialSize: vialSize,
      currentAmount: currentAmount,
      unit: 'mg',
      currentContainerBatchId: currentContainerBatchId,
    );
  }

  InventoryBatch createBatch({
    required String id,
    double containerSize = 10,
    int quantity = 1,
  }) {
    return InventoryBatch(
      id: id,
      inventoryItemId: 'inventory-1',
      name: '$id batch',
      containerSize: containerSize,
      unit: 'mg',
      quantity: quantity,
    );
  }

  group('InventoryService', () {
    test('deducts dose from current vial', () {
      final result = service.deductDose(
        item: createItem(
          currentAmount: 8,
          currentContainerBatchId: 'batch-current',
        ),
        batches: const [],
        doseAmount: 3,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 5);
      expect(result.item.currentContainerBatchId, 'batch-current');
      expect(result.batches, isEmpty);
      expect(result.vialsOpened, 0);
    });

    test('opens next vial when current vial is empty', () {
      final result = service.deductDose(
        item: createItem(currentAmount: 0),
        batches: [createBatch(id: 'batch-1', quantity: 2)],
        doseAmount: 3,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 7);
      expect(result.item.vialSize, 10);
      expect(result.item.currentContainerBatchId, 'batch-1');
      expect(result.vialsOpened, 1);
      expect(result.batches.first.quantity, 1);
    });

    test('uses remaining amount then opens next vial', () {
      final result = service.deductDose(
        item: createItem(
          currentAmount: 2,
          currentContainerBatchId: 'old-batch',
        ),
        batches: [createBatch(id: 'batch-1', quantity: 2)],
        doseAmount: 3,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 9);
      expect(result.item.currentContainerBatchId, 'batch-1');
      expect(result.vialsOpened, 1);
      expect(result.batches.first.quantity, 1);
    });

    test('can span multiple unopened vials', () {
      final result = service.deductDose(
        item: createItem(
          vialSize: 10,
          currentAmount: 2,
          currentContainerBatchId: 'old-batch',
        ),
        batches: [createBatch(id: 'batch-1', quantity: 3)],
        doseAmount: 25,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 7);
      expect(result.item.currentContainerBatchId, 'batch-1');
      expect(result.vialsOpened, 3);
      expect(result.batches.length, 1);
      expect(result.batches.first.quantity, 0);
    });

    test('does not change inventory when stock is insufficient', () {
      final item = createItem(currentAmount: 2);
      final batches = [createBatch(id: 'batch-1', quantity: 1)];

      final result = service.deductDose(
        item: item,
        batches: batches,
        doseAmount: 15,
      );

      expect(result.hadEnoughStock, isFalse);
      expect(result.amountDeducted, 0);
      expect(result.item.currentAmount, 2);
      expect(result.batches.first.quantity, 1);
    });

    test('supports mixed vial sizes and retains source batch', () {
      final result = service.deductDose(
        item: createItem(
          vialSize: 50,
          currentAmount: 2,
          currentContainerBatchId: 'old-batch',
        ),
        batches: [
          createBatch(id: 'batch-50', containerSize: 50, quantity: 1),
          createBatch(id: 'batch-100', containerSize: 100, quantity: 2),
        ],
        doseAmount: 3,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.vialSize, 50);
      expect(result.item.currentAmount, 49);
      expect(result.item.currentContainerBatchId, 'batch-50');
      expect(result.vialsOpened, 1);

      final fiftyBatch = result.batches.firstWhere(
        (batch) => batch.id == 'batch-50',
      );
      final hundredBatch = result.batches.firstWhere(
        (batch) => batch.id == 'batch-100',
      );

      expect(fiftyBatch.quantity, 0);
      expect(hundredBatch.quantity, 2);
    });

    test('calculates whole doses remaining', () {
      final doses = service.wholeDosesRemaining(
        totalRemaining: 24,
        doseAmount: 3,
      );
      expect(doses, 8);
    });
  });
}

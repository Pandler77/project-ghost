import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/inventory_item.dart';
import 'package:project_ghost/services/inventory_service.dart';

void main() {
  const service = InventoryService();

  InventoryItem createItem({
    double vialSize = 10,
    double currentAmount = 10,
    int unopenedQuantity = 0,
  }) {
    return InventoryItem(
      id: 'inventory-1',
      protocolId: 'protocol-1',
      vialSize: vialSize,
      currentAmount: currentAmount,
      unit: 'mg',
      unopenedQuantity: unopenedQuantity,
    );
  }

  group('InventoryService', () {
    test('deducts dose from current vial', () {
      final result = service.deductDose(
        item: createItem(currentAmount: 8),
        doseAmount: 3,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 5);
      expect(result.item.unopenedQuantity, 0);
      expect(result.vialsOpened, 0);
    });

    test('opens next vial when current vial is empty', () {
      final result = service.deductDose(
        item: createItem(currentAmount: 0, unopenedQuantity: 2),
        doseAmount: 3,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 7);
      expect(result.item.unopenedQuantity, 1);
      expect(result.vialsOpened, 1);
    });

    test('uses remaining amount then opens next vial', () {
      final result = service.deductDose(
        item: createItem(currentAmount: 2, unopenedQuantity: 2),
        doseAmount: 3,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 9);
      expect(result.item.unopenedQuantity, 1);
      expect(result.vialsOpened, 1);
    });

    test('can span multiple unopened vials', () {
      final result = service.deductDose(
        item: createItem(vialSize: 10, currentAmount: 2, unopenedQuantity: 3),
        doseAmount: 25,
      );

      expect(result.hadEnoughStock, isTrue);
      expect(result.item.currentAmount, 7);
      expect(result.item.unopenedQuantity, 0);
      expect(result.vialsOpened, 3);
    });

    test('does not change inventory when stock is insufficient', () {
      final item = createItem(currentAmount: 2, unopenedQuantity: 1);

      final result = service.deductDose(item: item, doseAmount: 15);

      expect(result.hadEnoughStock, isFalse);
      expect(result.amountDeducted, 0);
      expect(result.item.currentAmount, 2);
      expect(result.item.unopenedQuantity, 1);
    });

    test('calculates whole doses remaining', () {
      final doses = service.wholeDosesRemaining(
        item: createItem(currentAmount: 6, unopenedQuantity: 2),
        doseAmount: 3,
      );

      expect(doses, 8);
    });
  });
}

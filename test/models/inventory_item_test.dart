import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/inventory_item.dart';

void main() {
  group('InventoryItem', () {
    test('calculates total remaining', () {
      final item = InventoryItem(
        id: 'inventory-1',
        protocolId: 'protocol-1',
        vialSize: 10,
        currentAmount: 6,
        unit: 'mg',
        unopenedQuantity: 2,
      );

      expect(item.totalRemaining, 26);
    });

    test('calculates current vial progress', () {
      final item = InventoryItem(
        id: 'inventory-1',
        protocolId: 'protocol-1',
        vialSize: 10,
        currentAmount: 6,
        unit: 'mg',
      );

      expect(item.currentVialProgress, 0.6);
    });

    test('clamps current vial progress', () {
      final item = InventoryItem(
        id: 'inventory-1',
        protocolId: 'protocol-1',
        vialSize: 10,
        currentAmount: 14,
        unit: 'mg',
      );

      expect(item.currentVialProgress, 1);
    });

    test('detects low stock', () {
      final item = InventoryItem(
        id: 'inventory-1',
        protocolId: 'protocol-1',
        vialSize: 10,
        currentAmount: 3,
        unit: 'mg',
        unopenedQuantity: 1,
        lowStockThreshold: 1,
      );

      expect(item.isLowStock, isTrue);
    });

    test('serializes and restores correctly', () {
      final createdAt = DateTime(2026, 8, 2, 10);
      final updatedAt = DateTime(2026, 8, 2, 12);

      final item = InventoryItem(
        id: 'inventory-1',
        protocolId: 'protocol-1',
        vialSize: 10,
        currentAmount: 6,
        unit: 'mg',
        unopenedQuantity: 2,
        lowStockThreshold: 1,
        shippingDays: 14,
        vendor: 'Test Vendor',
        batch: 'RT-0826A',
        notes: 'Stored refrigerated',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = InventoryItem.fromMap(item.toMap());

      expect(restored.id, item.id);
      expect(restored.protocolId, item.protocolId);
      expect(restored.vialSize, item.vialSize);
      expect(restored.currentAmount, item.currentAmount);
      expect(restored.unit, item.unit);
      expect(restored.unopenedQuantity, item.unopenedQuantity);
      expect(restored.vendor, item.vendor);
      expect(restored.batch, item.batch);
      expect(restored.notes, item.notes);
      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
    });

    test('copyWith can clear optional fields', () {
      final item = InventoryItem(
        id: 'inventory-1',
        protocolId: 'protocol-1',
        vialSize: 10,
        currentAmount: 6,
        unit: 'mg',
        vendor: 'Test Vendor',
        batch: 'RT-0826A',
      );

      final updated = item.copyWith(vendor: null, batch: null);

      expect(updated.vendor, isNull);
      expect(updated.batch, isNull);
    });
  });
}

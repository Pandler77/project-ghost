enum InventoryEventType {
  created,
  doseDeducted,
  doseRestored,
  vialOpened,
  stockAdded,
  manualAdjustment,
  archived,
}

extension InventoryEventTypeDetails on InventoryEventType {
  String get storageValue {
    return switch (this) {
      InventoryEventType.created => 'created',
      InventoryEventType.doseDeducted => 'dose_deducted',
      InventoryEventType.doseRestored => 'dose_restored',
      InventoryEventType.vialOpened => 'vial_opened',
      InventoryEventType.stockAdded => 'stock_added',
      InventoryEventType.manualAdjustment => 'manual_adjustment',
      InventoryEventType.archived => 'archived',
    };
  }

  String get label {
    return switch (this) {
      InventoryEventType.created => 'Inventory created',
      InventoryEventType.doseDeducted => 'Dose deducted',
      InventoryEventType.doseRestored => 'Dose restored',
      InventoryEventType.vialOpened => 'New vial opened',
      InventoryEventType.stockAdded => 'Stock added',
      InventoryEventType.manualAdjustment => 'Inventory adjusted',
      InventoryEventType.archived => 'Inventory archived',
    };
  }

  static InventoryEventType fromStorageValue(String value) {
    return switch (value) {
      'created' => InventoryEventType.created,
      'dose_deducted' => InventoryEventType.doseDeducted,
      'dose_restored' => InventoryEventType.doseRestored,
      'vial_opened' => InventoryEventType.vialOpened,
      'stock_added' => InventoryEventType.stockAdded,
      'manual_adjustment' => InventoryEventType.manualAdjustment,
      'archived' => InventoryEventType.archived,
      _ => throw FormatException('Unknown inventory event type: $value'),
    };
  }
}

class InventoryEvent {
  InventoryEvent({
    String? id,
    required this.inventoryItemId,
    required this.protocolId,
    required this.type,
    required this.amountChanged,
    required this.amountAfter,
    required this.unopenedQuantityAfter,
    this.notes,
    DateTime? occurredAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       occurredAt = occurredAt ?? DateTime.now();

  final String id;
  final String inventoryItemId;
  final String protocolId;
  final InventoryEventType type;

  final double amountChanged;
  final double amountAfter;
  final int unopenedQuantityAfter;

  final String? notes;
  final DateTime occurredAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'protocol_id': protocolId,
      'type': type.storageValue,
      'amount_changed': amountChanged,
      'amount_after': amountAfter,
      'unopened_quantity_after': unopenedQuantityAfter,
      'notes': notes,
      'occurred_at': occurredAt.toIso8601String(),
    };
  }

  factory InventoryEvent.fromMap(Map<String, Object?> map) {
    return InventoryEvent(
      id: map['id'] as String,
      inventoryItemId: map['inventory_item_id'] as String,
      protocolId: map['protocol_id'] as String,
      type: InventoryEventTypeDetails.fromStorageValue(map['type'] as String),
      amountChanged: (map['amount_changed'] as num).toDouble(),
      amountAfter: (map['amount_after'] as num).toDouble(),
      unopenedQuantityAfter: (map['unopened_quantity_after'] as num).toInt(),
      notes: map['notes'] as String?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
    );
  }
}

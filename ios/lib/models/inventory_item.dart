class InventoryItem {
  InventoryItem({
    String? id,
    required this.protocolId,
    this.displayName,
    required this.vialSize,
    required this.currentAmount,
    required this.unit,
    this.containerType = 'Container',
    this.unopenedQuantity = 0,
    this.lowStockThreshold = 1,
    this.shippingDays = 14,
    this.currentContainerOpenedAt,
    this.currentContainerBatchId,
    this.reconstitutionVolumeMl,
    this.expirationDate,
    this.storageInstructions,
    this.purchaseDate,
    this.cost,
    this.vendor,
    this.batch,
    this.notes,
    double? supplyCapacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       supplyCapacity =
           supplyCapacity ?? (currentAmount + (vialSize * unopenedQuantity)),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  static const Object _unset = Object();

  final String id;
  final String protocolId;

  /// Optional user-facing name for this supply.
  ///
  /// Example:
  /// BlooGoo
  /// Reta
  /// Night Meds
  ///
  /// If null/blank, the UI should fall back to the linked protocol name.
  final String? displayName;

  final double vialSize;
  final double currentAmount;
  final String unit;
  final String containerType;

  final int unopenedQuantity;
  final int lowStockThreshold;
  final int shippingDays;

  final DateTime? currentContainerOpenedAt;
  final String? currentContainerBatchId;

  final double? reconstitutionVolumeMl;
  final DateTime? expirationDate;
  final String? storageInstructions;
  final DateTime? purchaseDate;
  final double? cost;

  final String? vendor;
  final String? batch;
  final String? notes;

  /// Total amount this inventory has ever contained.
  /// Used for supply forecasting progress.
  final double supplyCapacity;

  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalRemaining {
    return currentAmount + (vialSize * unopenedQuantity);
  }

  double get currentVialProgress {
    if (vialSize <= 0) {
      return 0;
    }

    return (currentAmount / vialSize).clamp(0.0, 1.0);
  }

  double get totalSupplyProgress {
    if (supplyCapacity <= 0) {
      return 0;
    }

    return (totalRemaining / supplyCapacity).clamp(0.0, 1.0);
  }

  bool get hasOpenVial {
    return currentAmount > 0;
  }

  bool get isLowStock {
    return unopenedQuantity <= lowStockThreshold;
  }

  double? get concentration {
    final volume = reconstitutionVolumeMl;

    if (volume == null || volume <= 0) {
      return null;
    }

    return vialSize / volume;
  }

  InventoryItem copyWith({
    String? id,
    String? protocolId,
    Object? displayName = _unset,
    double? vialSize,
    double? currentAmount,
    String? unit,
    String? containerType,
    int? unopenedQuantity,
    int? lowStockThreshold,
    int? shippingDays,
    double? supplyCapacity,
    Object? currentContainerOpenedAt = _unset,
    Object? currentContainerBatchId = _unset,
    Object? reconstitutionVolumeMl = _unset,
    Object? expirationDate = _unset,
    Object? storageInstructions = _unset,
    Object? purchaseDate = _unset,
    Object? cost = _unset,
    Object? vendor = _unset,
    Object? batch = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      protocolId: protocolId ?? this.protocolId,
      displayName: identical(displayName, _unset)
          ? this.displayName
          : displayName as String?,
      vialSize: vialSize ?? this.vialSize,
      currentAmount: currentAmount ?? this.currentAmount,
      unit: unit ?? this.unit,
      containerType: containerType ?? this.containerType,
      unopenedQuantity: unopenedQuantity ?? this.unopenedQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      shippingDays: shippingDays ?? this.shippingDays,
      supplyCapacity: supplyCapacity ?? this.supplyCapacity,
      currentContainerOpenedAt: identical(currentContainerOpenedAt, _unset)
          ? this.currentContainerOpenedAt
          : currentContainerOpenedAt as DateTime?,
      currentContainerBatchId: identical(currentContainerBatchId, _unset)
          ? this.currentContainerBatchId
          : currentContainerBatchId as String?,
      reconstitutionVolumeMl: identical(reconstitutionVolumeMl, _unset)
          ? this.reconstitutionVolumeMl
          : reconstitutionVolumeMl as double?,
      expirationDate: identical(expirationDate, _unset)
          ? this.expirationDate
          : expirationDate as DateTime?,
      storageInstructions: identical(storageInstructions, _unset)
          ? this.storageInstructions
          : storageInstructions as String?,
      purchaseDate: identical(purchaseDate, _unset)
          ? this.purchaseDate
          : purchaseDate as DateTime?,
      cost: identical(cost, _unset) ? this.cost : cost as double?,
      vendor: identical(vendor, _unset) ? this.vendor : vendor as String?,
      batch: identical(batch, _unset) ? this.batch : batch as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'protocol_id': protocolId,
      'display_name': displayName,
      'vial_size': vialSize,
      'current_amount': currentAmount,
      'unit': unit,
      'container_type': containerType,
      'unopened_quantity': unopenedQuantity,
      'low_stock_threshold': lowStockThreshold,
      'shipping_days': shippingDays,
      'current_container_opened_at': currentContainerOpenedAt
          ?.toIso8601String(),
      'current_container_batch_id': currentContainerBatchId,
      'reconstitution_volume_ml': reconstitutionVolumeMl,
      'expiration_date': expirationDate?.toIso8601String(),
      'storage_instructions': storageInstructions,
      'purchase_date': purchaseDate?.toIso8601String(),
      'cost': cost,
      'vendor': vendor,
      'batch': batch,
      'notes': notes,
      'supply_capacity': supplyCapacity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, Object?> map) {
    return InventoryItem(
      id: map['id'] as String,
      protocolId: map['protocol_id'] as String,
      displayName: map['display_name'] as String?,
      vialSize: (map['vial_size'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      unit: map['unit'] as String,
      containerType: map['container_type'] as String? ?? 'Container',
      unopenedQuantity: (map['unopened_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toInt() ?? 1,
      shippingDays: (map['shipping_days'] as num?)?.toInt() ?? 14,
      currentContainerOpenedAt: map['current_container_opened_at'] == null
          ? null
          : DateTime.parse(map['current_container_opened_at'] as String),
      currentContainerBatchId: map['current_container_batch_id'] as String?,
      reconstitutionVolumeMl: (map['reconstitution_volume_ml'] as num?)
          ?.toDouble(),
      expirationDate: map['expiration_date'] == null
          ? null
          : DateTime.parse(map['expiration_date'] as String),
      storageInstructions: map['storage_instructions'] as String?,
      purchaseDate: map['purchase_date'] == null
          ? null
          : DateTime.parse(map['purchase_date'] as String),
      cost: (map['cost'] as num?)?.toDouble(),
      vendor: map['vendor'] as String?,
      batch: map['batch'] as String?,
      notes: map['notes'] as String?,
      supplyCapacity: (map['supply_capacity'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

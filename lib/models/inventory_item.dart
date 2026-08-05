class InventoryItem {
  InventoryItem({
    String? id,
    required this.protocolId,
    required this.vialSize,
    required this.currentAmount,
    required this.unit,
    this.containerType = 'Container',
    this.unopenedQuantity = 0,
    this.lowStockThreshold = 1,
    this.shippingDays = 14,
    this.currentContainerOpenedAt,
    this.vendor,
    this.batch,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  static const Object _unset = Object();

  final String id;
  final String protocolId;

  final double vialSize;
  final double currentAmount;
  final String unit;
  final String containerType;

  final int unopenedQuantity;
  final int lowStockThreshold;
  final int shippingDays;

  final DateTime? currentContainerOpenedAt;

  final String? vendor;
  final String? batch;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalRemaining {
    return currentAmount + (vialSize * unopenedQuantity);
  }

  double get currentVialProgress {
    if (vialSize <= 0) {
      return 0;
    }

    return (currentAmount / vialSize).clamp(0, 1);
  }

  bool get hasOpenVial {
    return currentAmount > 0;
  }

  bool get isLowStock {
    return unopenedQuantity <= lowStockThreshold;
  }

  InventoryItem copyWith({
    String? id,
    String? protocolId,
    double? vialSize,
    double? currentAmount,
    String? unit,
    String? containerType,
    int? unopenedQuantity,
    int? lowStockThreshold,
    int? shippingDays,
    Object? currentContainerOpenedAt = _unset,
    Object? vendor = _unset,
    Object? batch = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      protocolId: protocolId ?? this.protocolId,
      vialSize: vialSize ?? this.vialSize,
      currentAmount: currentAmount ?? this.currentAmount,
      unit: unit ?? this.unit,
      containerType: containerType ?? this.containerType,
      unopenedQuantity: unopenedQuantity ?? this.unopenedQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      shippingDays: shippingDays ?? this.shippingDays,
      currentContainerOpenedAt: identical(currentContainerOpenedAt, _unset)
          ? this.currentContainerOpenedAt
          : currentContainerOpenedAt as DateTime?,
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
      'vial_size': vialSize,
      'current_amount': currentAmount,
      'unit': unit,
      'container_type': containerType,
      'unopened_quantity': unopenedQuantity,
      'low_stock_threshold': lowStockThreshold,
      'shipping_days': shippingDays,
      'current_container_opened_at': currentContainerOpenedAt
          ?.toIso8601String(),
      'vendor': vendor,
      'batch': batch,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, Object?> map) {
    return InventoryItem(
      id: map['id'] as String,
      protocolId: map['protocol_id'] as String,
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
      vendor: map['vendor'] as String?,
      batch: map['batch'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

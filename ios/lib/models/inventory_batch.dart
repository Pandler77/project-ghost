class InventoryBatch {
  InventoryBatch({
    String? id,
    required this.inventoryItemId,
    required this.name,
    required this.containerSize,
    required this.unit,
    required this.quantity,
    this.vendor,
    this.batch,
    this.purchaseDate,
    this.expirationDate,
    this.cost,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  static const Object _unset = Object();

  final String id;
  final String inventoryItemId;

  /// Human-readable name used when selecting a batch.
  ///
  /// Examples:
  /// QSC 50mg Kit
  /// QSC 100mg Kit
  /// January NAD Supply
  final String name;

  final double containerSize;
  final String unit;
  final int quantity;

  final String? vendor;

  /// Vendor/manufacturer batch or lot number.
  final String? batch;

  final DateTime? purchaseDate;
  final DateTime? expirationDate;
  final double? cost;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalAmount => containerSize * quantity;

  bool get isEmpty => quantity <= 0;

  InventoryBatch copyWith({
    String? id,
    String? inventoryItemId,
    String? name,
    double? containerSize,
    String? unit,
    int? quantity,
    Object? vendor = _unset,
    Object? batch = _unset,
    Object? purchaseDate = _unset,
    Object? expirationDate = _unset,
    Object? cost = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryBatch(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      name: name ?? this.name,
      containerSize: containerSize ?? this.containerSize,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      vendor: identical(vendor, _unset) ? this.vendor : vendor as String?,
      batch: identical(batch, _unset) ? this.batch : batch as String?,
      purchaseDate: identical(purchaseDate, _unset)
          ? this.purchaseDate
          : purchaseDate as DateTime?,
      expirationDate: identical(expirationDate, _unset)
          ? this.expirationDate
          : expirationDate as DateTime?,
      cost: identical(cost, _unset) ? this.cost : cost as double?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'name': name,
      'container_size': containerSize,
      'unit': unit,
      'quantity': quantity,
      'vendor': vendor,
      'batch': batch,
      'purchase_date': purchaseDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'cost': cost,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryBatch.fromMap(Map<String, Object?> map) {
    final containerSize = (map['container_size'] as num).toDouble();

    final unit = map['unit'] as String;

    final storedName = map['name'] as String?;

    return InventoryBatch(
      id: map['id'] as String,
      inventoryItemId: map['inventory_item_id'] as String,

      // Backward-compatible fallback for batches created
      // before batch names existed.
      name: storedName == null || storedName.trim().isEmpty
          ? '${_formatNumber(containerSize)} $unit Batch'
          : storedName.trim(),

      containerSize: containerSize,
      unit: unit,
      quantity: (map['quantity'] as num).toInt(),
      vendor: map['vendor'] as String?,
      batch: map['batch'] as String?,
      purchaseDate: map['purchase_date'] == null
          ? null
          : DateTime.parse(map['purchase_date'] as String),
      expirationDate: map['expiration_date'] == null
          ? null
          : DateTime.parse(map['expiration_date'] as String),
      cost: (map['cost'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

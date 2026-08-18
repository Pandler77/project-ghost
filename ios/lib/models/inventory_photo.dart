class InventoryPhoto {
  InventoryPhoto({
    String? id,
    required this.inventoryItemId,
    required this.imagePath,
    this.caption,
    DateTime? createdAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String inventoryItemId;
  final String imagePath;
  final String? caption;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'image_path': imagePath,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryPhoto.fromMap(Map<String, Object?> map) {
    return InventoryPhoto(
      id: map['id'] as String,
      inventoryItemId: map['inventory_item_id'] as String,
      imagePath: map['image_path'] as String,
      caption: map['caption'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

import '../../models/inventory_photo.dart';
import '../database/app_database.dart';

class InventoryPhotoRepository {
  InventoryPhotoRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> insert(InventoryPhoto photo) async {
    final database = await _database.database;

    await database.insert(AppDatabase.inventoryPhotosTable, photo.toMap());
  }

  Future<void> update(InventoryPhoto photo) async {
    final database = await _database.database;

    await database.update(
      AppDatabase.inventoryPhotosTable,
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<void> delete(String photoId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.inventoryPhotosTable,
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  Future<InventoryPhoto?> getById(String photoId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.inventoryPhotosTable,
      where: 'id = ?',
      whereArgs: [photoId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return InventoryPhoto.fromMap(rows.first);
  }

  Future<List<InventoryPhoto>> getByInventoryItem(
    String inventoryItemId,
  ) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.inventoryPhotosTable,
      where: 'inventory_item_id = ?',
      whereArgs: [inventoryItemId],
      orderBy: 'created_at DESC',
    );

    return rows.map(InventoryPhoto.fromMap).toList(growable: false);
  }

  Future<void> deleteByInventoryItem(String inventoryItemId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.inventoryPhotosTable,
      where: 'inventory_item_id = ?',
      whereArgs: [inventoryItemId],
    );
  }
}

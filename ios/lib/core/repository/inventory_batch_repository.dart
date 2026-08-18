import '../../models/inventory_batch.dart';
import '../database/app_database.dart';

class InventoryBatchRepository {
  InventoryBatchRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> insert(InventoryBatch batch) async {
    final database = await _database.database;
    await database.insert(AppDatabase.inventoryBatchesTable, batch.toMap());
  }

  Future<void> update(InventoryBatch batch) async {
    final database = await _database.database;
    await database.update(
      AppDatabase.inventoryBatchesTable,
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<void> delete(String batchId) async {
    final database = await _database.database;
    await database.delete(
      AppDatabase.inventoryBatchesTable,
      where: 'id = ?',
      whereArgs: [batchId],
    );
  }

  Future<InventoryBatch?> getById(String batchId) async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.inventoryBatchesTable,
      where: 'id = ?',
      whereArgs: [batchId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return InventoryBatch.fromMap(rows.first);
  }

  Future<List<InventoryBatch>> getByInventoryItem(
    String inventoryItemId,
  ) async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.inventoryBatchesTable,
      where: 'inventory_item_id = ?',
      whereArgs: [inventoryItemId],
      orderBy: 'created_at ASC',
    );

    return rows.map(InventoryBatch.fromMap).toList(growable: false);
  }

  Future<List<InventoryBatch>> getAll() async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.inventoryBatchesTable,
      orderBy: 'created_at ASC',
    );

    return rows.map(InventoryBatch.fromMap).toList(growable: false);
  }

  Future<void> deleteByInventoryItem(String inventoryItemId) async {
    final database = await _database.database;
    await database.delete(
      AppDatabase.inventoryBatchesTable,
      where: 'inventory_item_id = ?',
      whereArgs: [inventoryItemId],
    );
  }
}

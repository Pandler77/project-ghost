import '../database/app_database.dart';
import '../../models/inventory_event.dart';

class InventoryEventRepository {
  InventoryEventRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> insert(InventoryEvent event) async {
    final database = await _database.database;

    await database.insert(AppDatabase.inventoryEventsTable, event.toMap());
  }

  Future<void> update(InventoryEvent event) async {
    final database = await _database.database;

    await database.update(
      AppDatabase.inventoryEventsTable,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> delete(String eventId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.inventoryEventsTable,
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<InventoryEvent?> getById(String eventId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.inventoryEventsTable,
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return InventoryEvent.fromMap(rows.first);
  }

  Future<List<InventoryEvent>> getByInventoryItem(
    String inventoryItemId, {
    int? limit,
  }) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.inventoryEventsTable,
      where: 'inventory_item_id = ?',
      whereArgs: [inventoryItemId],
      orderBy: 'occurred_at DESC',
      limit: limit,
    );

    return rows.map(InventoryEvent.fromMap).toList(growable: false);
  }

  Future<List<InventoryEvent>> getByProtocol(
    String protocolId, {
    int? limit,
  }) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.inventoryEventsTable,
      where: 'protocol_id = ?',
      whereArgs: [protocolId],
      orderBy: 'occurred_at DESC',
      limit: limit,
    );

    return rows.map(InventoryEvent.fromMap).toList(growable: false);
  }

  Future<List<InventoryEvent>> getAll({int? limit}) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.inventoryEventsTable,
      orderBy: 'occurred_at DESC',
      limit: limit,
    );

    return rows.map(InventoryEvent.fromMap).toList(growable: false);
  }

  Future<void> deleteByInventoryItem(String inventoryItemId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.inventoryEventsTable,
      where: 'inventory_item_id = ?',
      whereArgs: [inventoryItemId],
    );
  }

  Future<void> deleteByProtocol(String protocolId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.inventoryEventsTable,
      where: 'protocol_id = ?',
      whereArgs: [protocolId],
    );
  }
}

import 'package:sqflite/sqflite.dart';

import '../../models/dose_record.dart';
import '../../models/inventory_item.dart';
import '../../models/protocol.dart';
import '../../models/weight_record.dart';
import '../../services/settings_service.dart';
import '../database/app_database.dart';

class GhostRepository {
  GhostRepository({AppDatabase? appDatabase, SettingsService? settingsService})
    : _appDatabase = appDatabase ?? AppDatabase.instance,
      _settingsService = settingsService ?? SettingsService();

  final AppDatabase _appDatabase;
  final SettingsService _settingsService;

  Future<String> _getActiveProfileId() async {
    return await _settingsService.getActiveProfileId() ??
        AppDatabase.defaultProfileId;
  }

  Map<String, Object?> _withProfileId(
    Map<String, Object?> values,
    String profileId,
  ) {
    return {...values, 'profile_id': profileId};
  }

  // ------------------------
  // Protocols
  // ------------------------

  Future<List<Protocol>> getProtocols() async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.protocolsTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Protocol.fromMap).toList();
  }

  Future<void> insertProtocol(Protocol protocol) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.insert(
      AppDatabase.protocolsTable,
      _withProfileId(protocol.toMap(), profileId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProtocol(Protocol protocol) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.update(
      AppDatabase.protocolsTable,
      _withProfileId(protocol.toMap(), profileId),
      where: 'id = ? AND profile_id = ?',
      whereArgs: [protocol.id, profileId],
    );
  }

  Future<void> deleteProtocol(String id) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.delete(
      AppDatabase.protocolsTable,
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  // ------------------------
  // Dose records
  // ------------------------

  Future<List<DoseRecord>> getAllDoseRecords() async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'scheduled_for DESC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<List<DoseRecord>> getDoseRecordsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final normalizedStart = DateTime(start.year, start.month, start.day);

    final normalizedEnd = DateTime(end.year, end.month, end.day);

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      where:
          'profile_id = ? '
          'AND scheduled_for >= ? '
          'AND scheduled_for < ?',
      whereArgs: [
        profileId,
        normalizedStart.toIso8601String(),
        normalizedEnd.toIso8601String(),
      ],
      orderBy: 'scheduled_for ASC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<List<DoseRecord>> getDoseRecordsForProtocol(String protocolId) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      where: 'profile_id = ? AND protocol_id = ?',
      whereArgs: [profileId, protocolId],
      orderBy: 'scheduled_for DESC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<List<DoseRecord>> getDoseRecordsForDate(DateTime date) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final start = DateTime(date.year, date.month, date.day);

    final end = start.add(const Duration(days: 1));

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      where:
          'profile_id = ? '
          'AND scheduled_for >= ? '
          'AND scheduled_for < ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_for ASC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<void> saveDoseRecord(DoseRecord record) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.insert(
      AppDatabase.doseRecordsTable,
      _withProfileId(record.toMap(), profileId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDoseRecord({
    required String protocolId,
    required DateTime scheduledFor,
  }) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.delete(
      AppDatabase.doseRecordsTable,
      where:
          'profile_id = ? '
          'AND protocol_id = ? '
          'AND scheduled_for = ?',
      whereArgs: [profileId, protocolId, scheduledFor.toIso8601String()],
    );
  }

  // ------------------------
  // Weight records
  // ------------------------

  Future<void> saveWeightRecord(WeightRecord record) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.insert(
      AppDatabase.weightRecordsTable,
      _withProfileId(record.toMap(), profileId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WeightRecord>> getWeightRecords() async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.weightRecordsTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'recorded_at DESC',
    );

    return rows.map(WeightRecord.fromMap).toList();
  }

  Future<WeightRecord?> getLatestWeight() async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.weightRecordsTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return WeightRecord.fromMap(rows.first);
  }

  Future<void> deleteWeightRecord(String id) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.delete(
      AppDatabase.weightRecordsTable,
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Future<WeightRecord?> getWeightRecordForDate(DateTime date) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final start = DateTime(date.year, date.month, date.day);

    final end = start.add(const Duration(days: 1));

    final rows = await db.query(
      AppDatabase.weightRecordsTable,
      where:
          'profile_id = ? '
          'AND recorded_at >= ? '
          'AND recorded_at < ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return WeightRecord.fromMap(rows.first);
  }

  // ------------------------
  // Inventory
  // ------------------------

  Future<List<InventoryItem>> getInventoryItems() async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.inventoryTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'updated_at DESC',
    );

    return rows.map(InventoryItem.fromMap).toList();
  }

  Future<InventoryItem?> getInventoryItemForProtocol(String protocolId) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.inventoryTable,
      where: 'profile_id = ? AND protocol_id = ?',
      whereArgs: [profileId, protocolId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return InventoryItem.fromMap(rows.first);
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.insert(
      AppDatabase.inventoryTable,
      _withProfileId(item.toMap(), profileId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.update(
      AppDatabase.inventoryTable,
      _withProfileId(item.toMap(), profileId),
      where: 'id = ? AND profile_id = ?',
      whereArgs: [item.id, profileId],
    );
  }

  Future<void> deleteInventoryItem(String id) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.delete(
      AppDatabase.inventoryTable,
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Future<void> deleteInventoryForProtocol(String protocolId) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.delete(
      AppDatabase.inventoryTable,
      where: 'profile_id = ? AND protocol_id = ?',
      whereArgs: [profileId, protocolId],
    );
  }
}

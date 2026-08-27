import 'package:sqflite/sqflite.dart';

import '../../models/dose_record.dart';
import '../../models/inventory_item.dart';
import '../../models/protocol.dart';
import '../../models/schedule_override.dart';
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
  // Medication & dose calculation safety
  // ------------------------

  Future<bool> hasDoseSafetyAcknowledgement({
    required String acknowledgementType,
    required int version,
  }) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.doseSafetyAcknowledgementsTable,
      columns: const ['id'],
      where:
          'profile_id = ? '
          'AND acknowledgement_type = ? '
          'AND version = ?',
      whereArgs: [profileId, acknowledgementType, version],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> saveDoseSafetyAcknowledgement({
    required String acknowledgementType,
    required int version,
    required DateTime acceptedAt,
  }) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final id = '$profileId:$acknowledgementType:$version';

    await db.insert(
      AppDatabase.doseSafetyAcknowledgementsTable,
      {
        'id': id,
        'profile_id': profileId,
        'acknowledgement_type': acknowledgementType,
        'version': version,
        'accepted_at': acceptedAt.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<DateTime?> getDoseSafetyAcknowledgementAcceptedAt({
    required String acknowledgementType,
    required int version,
  }) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.doseSafetyAcknowledgementsTable,
      columns: const ['accepted_at'],
      where:
          'profile_id = ? '
          'AND acknowledgement_type = ? '
          'AND version = ?',
      whereArgs: [profileId, acknowledgementType, version],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['accepted_at'] as String?;

    return value == null ? null : DateTime.tryParse(value);
  }

  // ------------------------
  // Schedule overrides
  // ------------------------

  Future<List<ScheduleOverride>> getScheduleOverrides() async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.scheduleOverridesTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'created_at ASC',
    );

    return rows.map(ScheduleOverride.fromMap).toList();
  }

  Future<List<ScheduleOverride>> getScheduleOverridesForProtocol(
    String protocolId,
  ) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.scheduleOverridesTable,
      where: 'profile_id = ? AND protocol_id = ?',
      whereArgs: [profileId, protocolId],
      orderBy: 'created_at ASC',
    );

    return rows.map(ScheduleOverride.fromMap).toList();
  }

  Future<void> saveScheduleOverride(ScheduleOverride override) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.insert(
      AppDatabase.scheduleOverridesTable,
      _withProfileId(override.toMap(), profileId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteScheduleOverride(String id) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.delete(
      AppDatabase.scheduleOverridesTable,
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Future<void> deleteScheduleOverrideForOccurrence({
    required String protocolId,
    required DateTime originalScheduledFor,
  }) async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    await db.delete(
      AppDatabase.scheduleOverridesTable,
      where:
          'profile_id = ? AND protocol_id = ? AND original_scheduled_for = ?',
      whereArgs: [
        profileId,
        protocolId,
        originalScheduledFor.toIso8601String(),
      ],
    );
  }

  // ------------------------
  // Protocols
  // ------------------------

  Future<List<Protocol>> getProtocols() async {
    final db = await _appDatabase.database;
    final profileId = await _getActiveProfileId();

    final rows = await db.query(
      AppDatabase.protocolsTable,
      where: 'profile_id = ? AND is_deleted = 0',
      whereArgs: [profileId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Protocol.fromMap).toList();
  }

  Future<List<Protocol>> getProtocolsForProfile(String profileId) async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      AppDatabase.protocolsTable,
      where: 'profile_id = ? AND is_deleted = 0',
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

    // Soft-delete the protocol so historical dose records, injection logs,
    // and other history that still references this protocol remain intact.
    await db.update(
      AppDatabase.protocolsTable,
      {'is_deleted': 1},
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );

    await db.delete(
      AppDatabase.scheduleOverridesTable,
      where: 'protocol_id = ? AND profile_id = ?',
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

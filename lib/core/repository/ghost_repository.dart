import 'package:sqflite/sqflite.dart';

import '../../models/dose_record.dart';
import '../../models/protocol.dart';
import '../../models/weight_record.dart';
import '../database/app_database.dart';

class GhostRepository {
  GhostRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  // ------------------------
  // Protocols
  // ------------------------

  Future<List<Protocol>> getProtocols() async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      AppDatabase.protocolsTable,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Protocol.fromMap).toList();
  }

  Future<void> insertProtocol(Protocol protocol) async {
    final db = await _appDatabase.database;

    await db.insert(
      AppDatabase.protocolsTable,
      protocol.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProtocol(Protocol protocol) async {
    final db = await _appDatabase.database;

    await db.update(
      AppDatabase.protocolsTable,
      protocol.toMap(),
      where: 'id = ?',
      whereArgs: [protocol.id],
    );
  }

  Future<void> deleteProtocol(String id) async {
    final db = await _appDatabase.database;

    await db.delete(
      AppDatabase.protocolsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------
  // Dose records
  // ------------------------

  Future<List<DoseRecord>> getAllDoseRecords() async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      orderBy: 'scheduled_for DESC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<List<DoseRecord>> getDoseRecordsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _appDatabase.database;

    final normalizedStart = DateTime(start.year, start.month, start.day);

    final normalizedEnd = DateTime(end.year, end.month, end.day);

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      where: 'scheduled_for >= ? AND scheduled_for < ?',
      whereArgs: [
        normalizedStart.toIso8601String(),
        normalizedEnd.toIso8601String(),
      ],
      orderBy: 'scheduled_for ASC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<List<DoseRecord>> getDoseRecordsForProtocol(String protocolId) async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      where: 'protocol_id = ?',
      whereArgs: [protocolId],
      orderBy: 'scheduled_for DESC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<List<DoseRecord>> getDoseRecordsForDate(DateTime date) async {
    final db = await _appDatabase.database;

    final start = DateTime(date.year, date.month, date.day);

    final end = start.add(const Duration(days: 1));

    final rows = await db.query(
      AppDatabase.doseRecordsTable,
      where: 'scheduled_for >= ? AND scheduled_for < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_for ASC',
    );

    return rows.map(DoseRecord.fromMap).toList();
  }

  Future<void> saveDoseRecord(DoseRecord record) async {
    final db = await _appDatabase.database;

    await db.insert(
      AppDatabase.doseRecordsTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDoseRecord({
    required String protocolId,
    required DateTime scheduledFor,
  }) async {
    final db = await _appDatabase.database;

    await db.delete(
      AppDatabase.doseRecordsTable,
      where: 'protocol_id = ? AND scheduled_for = ?',
      whereArgs: [protocolId, scheduledFor.toIso8601String()],
    );
  }

  // ------------------------
  // Weight records
  // ------------------------

  Future<void> saveWeightRecord(WeightRecord record) async {
    final db = await _appDatabase.database;

    await db.insert(
      AppDatabase.weightRecordsTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WeightRecord>> getWeightRecords() async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      AppDatabase.weightRecordsTable,
      orderBy: 'recorded_at DESC',
    );

    return rows.map(WeightRecord.fromMap).toList();
  }

  Future<WeightRecord?> getLatestWeight() async {
    final db = await _appDatabase.database;

    final rows = await db.query(
      AppDatabase.weightRecordsTable,
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

    await db.delete(
      AppDatabase.weightRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

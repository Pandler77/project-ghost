import '../database/app_database.dart';
import '../../models/injection_log.dart';

class InjectionLogRepository {
  InjectionLogRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> insert(InjectionLog log) async {
    final database = await _database.database;

    await database.insert(AppDatabase.injectionLogsTable, log.toMap());
  }

  Future<void> update(InjectionLog log) async {
    final database = await _database.database;

    final updatedRows = await database.update(
      AppDatabase.injectionLogsTable,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );

    if (updatedRows == 0) {
      throw StateError('Injection log ${log.id} was not found.');
    }
  }

  Future<void> delete(String logId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.injectionLogsTable,
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  Future<InjectionLog?> getById(String logId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.injectionLogsTable,
      where: 'id = ?',
      whereArgs: [logId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return InjectionLog.fromMap(rows.first);
  }

  Future<List<InjectionLog>> getByProtocol(
    String protocolId, {
    int? limit,
  }) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.injectionLogsTable,
      where: 'protocol_id = ?',
      whereArgs: [protocolId],
      orderBy: 'logged_at DESC',
      limit: limit,
    );

    return rows.map(InjectionLog.fromMap).toList();
  }

  Future<InjectionLog?> getMostRecentForProtocol(String protocolId) async {
    final logs = await getByProtocol(protocolId, limit: 1);

    return logs.isEmpty ? null : logs.first;
  }

  Future<List<InjectionLog>> getAll() async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.injectionLogsTable,
      orderBy: 'logged_at DESC',
    );

    return rows.map(InjectionLog.fromMap).toList();
  }

  Future<void> deleteByProtocol(String protocolId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.injectionLogsTable,
      where: 'protocol_id = ?',
      whereArgs: [protocolId],
    );
  }

  Future<InjectionLog?> getByDoseRecordId(String doseRecordId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.injectionLogsTable,
      where: 'dose_record_id = ?',
      whereArgs: [doseRecordId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return InjectionLog.fromMap(rows.first);
  }

  Future<void> deleteByDoseRecordId(String doseRecordId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.injectionLogsTable,
      where: 'dose_record_id = ?',
      whereArgs: [doseRecordId],
    );
  }
}

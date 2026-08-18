import '../../models/symptom_entry.dart';
import '../database/app_database.dart';

class SymptomEntryRepository {
  SymptomEntryRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> insert(SymptomEntry entry) async {
    final database = await _database.database;

    await database.insert(AppDatabase.symptomEntriesTable, entry.toMap());
  }

  Future<void> update(SymptomEntry entry) async {
    final database = await _database.database;

    await database.update(
      AppDatabase.symptomEntriesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> delete(String entryId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.symptomEntriesTable,
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<SymptomEntry?> getById(String entryId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.symptomEntriesTable,
      where: 'id = ?',
      whereArgs: [entryId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return SymptomEntry.fromMap(rows.first);
  }

  Future<List<SymptomEntry>> getAll(String profileId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.symptomEntriesTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'recorded_at DESC',
    );

    return rows.map(SymptomEntry.fromMap).toList(growable: false);
  }

  Future<List<SymptomEntry>> getByDate(String profileId, DateTime date) async {
    final database = await _database.database;

    final start = DateTime(date.year, date.month, date.day);

    final end = start.add(const Duration(days: 1));

    final rows = await database.query(
      AppDatabase.symptomEntriesTable,
      where:
          'profile_id = ? '
          'AND recorded_at >= ? '
          'AND recorded_at < ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at ASC',
    );

    return rows.map(SymptomEntry.fromMap).toList(growable: false);
  }

  Future<List<SymptomEntry>> getBySymptom(
    String profileId,
    String symptomName,
  ) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.symptomEntriesTable,
      where:
          'profile_id = ? '
          'AND LOWER(symptom_name) = LOWER(?)',
      whereArgs: [profileId, symptomName.trim()],
      orderBy: 'recorded_at ASC',
    );

    return rows.map(SymptomEntry.fromMap).toList(growable: false);
  }

  Future<List<SymptomEntry>> getBetween(
    String profileId,
    DateTime start,
    DateTime end,
  ) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.symptomEntriesTable,
      where:
          'profile_id = ? '
          'AND recorded_at >= ? '
          'AND recorded_at < ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at ASC',
    );

    return rows.map(SymptomEntry.fromMap).toList(growable: false);
  }

  Future<List<String>> getSymptomNames(String profileId) async {
    final database = await _database.database;

    final rows = await database.rawQuery(
      '''
      SELECT DISTINCT symptom_name
      FROM ${AppDatabase.symptomEntriesTable}
      WHERE profile_id = ?
      ORDER BY symptom_name COLLATE NOCASE ASC
      ''',
      [profileId],
    );

    return rows
        .map((row) => row['symptom_name'] as String)
        .toList(growable: false);
  }

  Future<void> deleteByProfile(String profileId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.symptomEntriesTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }
}

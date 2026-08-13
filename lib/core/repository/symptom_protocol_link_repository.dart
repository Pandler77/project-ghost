import '../database/app_database.dart';

class SymptomProtocolLinkRepository {
  SymptomProtocolLinkRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> replaceLinks({
    required String symptomEntryId,
    required List<String> protocolIds,
  }) async {
    final database = await _database.database;

    await database.transaction((transaction) async {
      await transaction.delete(
        AppDatabase.symptomProtocolLinksTable,
        where: 'symptom_entry_id = ?',
        whereArgs: [symptomEntryId],
      );

      for (final protocolId in protocolIds.toSet()) {
        await transaction.insert(AppDatabase.symptomProtocolLinksTable, {
          'symptom_entry_id': symptomEntryId,
          'protocol_id': protocolId,
        });
      }
    });
  }

  Future<List<String>> getProtocolIdsForEntry(String symptomEntryId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.symptomProtocolLinksTable,
      columns: ['protocol_id'],
      where: 'symptom_entry_id = ?',
      whereArgs: [symptomEntryId],
    );

    return rows
        .map((row) => row['protocol_id'] as String)
        .toList(growable: false);
  }

  Future<Map<String, List<String>>> getProtocolIdsForEntries(
    List<String> symptomEntryIds,
  ) async {
    if (symptomEntryIds.isEmpty) {
      return {};
    }

    final database = await _database.database;

    final placeholders = List.filled(symptomEntryIds.length, '?').join(',');

    final rows = await database.rawQuery('''
      SELECT symptom_entry_id, protocol_id
      FROM ${AppDatabase.symptomProtocolLinksTable}
      WHERE symptom_entry_id IN ($placeholders)
      ''', symptomEntryIds);

    final result = <String, List<String>>{};

    for (final row in rows) {
      final entryId = row['symptom_entry_id'] as String;
      final protocolId = row['protocol_id'] as String;

      result.putIfAbsent(entryId, () => <String>[]);

      result[entryId]!.add(protocolId);
    }

    return result;
  }

  Future<void> deleteLinksForEntry(String symptomEntryId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.symptomProtocolLinksTable,
      where: 'symptom_entry_id = ?',
      whereArgs: [symptomEntryId],
    );
  }
}

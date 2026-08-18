import '../../models/progress_photo_session.dart';
import '../database/app_database.dart';

class ProgressPhotoSessionRepository {
  ProgressPhotoSessionRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> insert(ProgressPhotoSession session) async {
    final database = await _database.database;

    await database.insert(
      AppDatabase.progressPhotoSessionsTable,
      session.toMap(),
    );
  }

  Future<void> update(ProgressPhotoSession session) async {
    final database = await _database.database;

    await database.update(
      AppDatabase.progressPhotoSessionsTable,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> delete(String sessionId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.progressPhotoSessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<ProgressPhotoSession?> getById(String sessionId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.progressPhotoSessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ProgressPhotoSession.fromMap(rows.first);
  }

  Future<List<ProgressPhotoSession>> getAll(String profileId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.progressPhotoSessionsTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'recorded_at DESC',
    );

    return rows.map(ProgressPhotoSession.fromMap).toList(growable: false);
  }
}

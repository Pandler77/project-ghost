import '../../models/progress_photo.dart';
import '../database/app_database.dart';

class ProgressPhotoRepository {
  ProgressPhotoRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> insert(ProgressPhoto photo) async {
    final database = await _database.database;

    await database.insert(AppDatabase.progressPhotosTable, photo.toMap());
  }

  Future<void> update(ProgressPhoto photo) async {
    final database = await _database.database;

    await database.update(
      AppDatabase.progressPhotosTable,
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<void> delete(String photoId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.progressPhotosTable,
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  Future<ProgressPhoto?> getById(String photoId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.progressPhotosTable,
      where: 'id = ?',
      whereArgs: [photoId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ProgressPhoto.fromMap(rows.first);
  }

  Future<List<ProgressPhoto>> getAll(String profileId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.progressPhotosTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'recorded_at DESC',
    );

    return rows.map(ProgressPhoto.fromMap).toList(growable: false);
  }

  Future<List<ProgressPhoto>> getByType(
    String profileId,
    ProgressPhotoType type,
  ) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.progressPhotosTable,
      where: 'profile_id = ? AND type = ?',
      whereArgs: [profileId, type.storageValue],
      orderBy: 'recorded_at DESC',
    );

    return rows.map(ProgressPhoto.fromMap).toList(growable: false);
  }

  Future<List<ProgressPhoto>> getBySession(String sessionId) async {
    final database = await _database.database;

    final rows = await database.query(
      AppDatabase.progressPhotosTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'recorded_at ASC',
    );

    return rows.map(ProgressPhoto.fromMap).toList(growable: false);
  }

  Future<void> deleteByProfile(String profileId) async {
    final database = await _database.database;

    await database.delete(
      AppDatabase.progressPhotosTable,
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }
}

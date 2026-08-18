import 'package:sqflite/sqflite.dart';

import '../../models/profile.dart';
import '../database/app_database.dart';

class ProfileRepository {
  ProfileRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Profile>> getProfiles() async {
    final db = await _database.database;

    final results = await db.query(
      AppDatabase.profilesTable,
      orderBy: 'created_at ASC',
    );

    return results.map(Profile.fromMap).toList();
  }

  Future<Profile?> getProfile(String id) async {
    final db = await _database.database;

    final results = await db.query(
      AppDatabase.profilesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return Profile.fromMap(results.first);
  }

  Future<void> saveProfile(Profile profile) async {
    final db = await _database.database;

    final existing = await getProfile(profile.id);

    if (existing == null) {
      await db.insert(
        AppDatabase.profilesTable,
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return;
    }

    await db.update(
      AppDatabase.profilesTable,
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> deleteProfile(String id) async {
    final db = await _database.database;

    await db.delete(
      AppDatabase.profilesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getProfileCount() async {
    final db = await _database.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM ${AppDatabase.profilesTable}
      ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> profileExists(String id) async {
    return (await getProfile(id)) != null;
  }
}

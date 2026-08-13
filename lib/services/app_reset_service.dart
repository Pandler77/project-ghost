import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/database/app_database.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class AppResetService {
  AppResetService._();

  static final AppResetService instance = AppResetService._();

  final SettingsService _settingsService = SettingsService();

  final ValueNotifier<int> resetRevision = ValueNotifier<int>(0);

  Future<void> resetAllAppData() async {
    final database = await AppDatabase.instance.database;

    final mediaPaths = <String>{};

    await _collectColumnPaths(
      database,
      AppDatabase.progressPhotosTable,
      'image_path',
      mediaPaths,
    );

    await _collectColumnPaths(
      database,
      AppDatabase.inventoryPhotosTable,
      'image_path',
      mediaPaths,
    );

    await _collectColumnPaths(
      database,
      AppDatabase.profilesTable,
      'avatar_image_path',
      mediaPaths,
    );

    await NotificationService.instance.cancelAllNotifications();

    for (final mediaPath in mediaPaths) {
      await _deleteFileIfPresent(mediaPath);
    }

    await _deleteKnownMediaDirectories();

    await AppDatabase.instance.resetDatabase();

    await _settingsService.resetForFreshStart();

    resetRevision.value++;
  }

  Future<void> _collectColumnPaths(
    dynamic database,
    String table,
    String column,
    Set<String> output,
  ) async {
    try {
      final rows = await database.query(
        table,
        columns: [column],
      );

      for (final row in rows) {
        final value = row[column];

        if (value is String && value.trim().isNotEmpty) {
          output.add(value.trim());
        }
      }
    } catch (_) {
      // Best effort. A missing legacy table/column should not block reset.
    }
  }

  Future<void> _deleteFileIfPresent(String filePath) async {
    try {
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Database/settings reset should still complete if an orphaned file
      // cannot be removed.
    }
  }

  Future<void> _deleteKnownMediaDirectories() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();

      final progressDirectory = Directory(
        path.join(documentsDirectory.path, 'progress_photos'),
      );

      if (await progressDirectory.exists()) {
        await progressDirectory.delete(recursive: true);
      }
    } catch (_) {
      // Best effort cleanup.
    }
  }
}

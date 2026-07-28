import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'ghost.db';
  static const int databaseVersion = 3;

  static const String protocolsTable = 'protocols';
  static const String doseRecordsTable = 'dose_records';
  static const String weightRecordsTable = 'weight_records';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();

    final databasePath = join(databasesPath, databaseName);

    return openDatabase(
      databasePath,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database database, int version) async {
    await _createProtocolsTable(database);
    await _createDoseRecordsTable(database);
    await _createWeightRecordsTable(database);
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createDoseRecordsTable(database);
    }

    if (oldVersion < 3) {
      await _createWeightRecordsTable(database);
    }
  }

  Future<void> _createProtocolsTable(Database database) async {
    await database.execute('''
      CREATE TABLE $protocolsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        status TEXT NOT NULL,
        schedule_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        interval_days INTEGER,
        weekday INTEGER,
        specific_weekdays TEXT,
        monthly_day INTEGER
      )
      ''');
  }

  Future<void> _createDoseRecordsTable(Database database) async {
    await database.execute('''
      CREATE TABLE $doseRecordsTable (
        id TEXT PRIMARY KEY,
        protocol_id TEXT NOT NULL,
        scheduled_for TEXT NOT NULL,
        completed_at TEXT,
        scheduled_amount TEXT NOT NULL,
        actual_amount TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY (protocol_id)
          REFERENCES $protocolsTable (id)
          ON DELETE CASCADE
      )
      ''');

    await database.execute('''
      CREATE UNIQUE INDEX idx_dose_records_protocol_schedule
      ON $doseRecordsTable (
        protocol_id,
        scheduled_for
      )
      ''');
  }

  Future<void> _createWeightRecordsTable(Database database) async {
    await database.execute('''
      CREATE TABLE $weightRecordsTable (
        id TEXT PRIMARY KEY,
        weight REAL NOT NULL,
        recorded_at TEXT NOT NULL
      )
      ''');

    await database.execute('''
      CREATE INDEX idx_weight_records_recorded_at
      ON $weightRecordsTable (
        recorded_at
      )
      ''');
  }

  Future<void> close() async {
    final database = _database;

    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }
}

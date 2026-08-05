import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'ghost.db';
  static const int databaseVersion = 11;

  static const String profilesTable = 'profiles';
  static const String protocolsTable = 'protocols';
  static const String doseRecordsTable = 'dose_records';
  static const String weightRecordsTable = 'weight_records';
  static const String inventoryTable = 'inventory';

  static const String defaultProfileId = 'default-profile';

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
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database database, int version) async {
    await _createProfilesTable(database);
    await _insertDefaultProfile(database);

    await _createProtocolsTable(database);
    await _createDoseRecordsTable(database);
    await _createWeightRecordsTable(database);
    await _createInventoryTable(database);

    await _createProfileIndexes(database);
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

    if (oldVersion < 4) {
      await database.execute('''
        ALTER TABLE $protocolsTable
        ADD COLUMN color_value INTEGER NOT NULL
        DEFAULT 4284960932
      ''');
    }

    if (oldVersion < 5) {
      await _addCycleColumns(database);
    }

    if (oldVersion < 6) {
      await _addReminderColumns(database);
    }

    if (oldVersion < 7) {
      await _createInventoryTable(database);
    }

    if (oldVersion < 8) {
      await database.execute('''
        ALTER TABLE $inventoryTable
        ADD COLUMN container_type TEXT NOT NULL
        DEFAULT 'Container'
      ''');
    }

    if (oldVersion < 9) {
      await database.execute('''
        ALTER TABLE $inventoryTable
        ADD COLUMN current_container_opened_at TEXT
      ''');
    }

    if (oldVersion < 10) {
      await _addProfiles(database);
    }

    if (oldVersion < 11) {
      await _addProtocolDoseColumns(database);
    }
  }

  Future<void> _addProfiles(Database database) async {
    await database.transaction((transaction) async {
      await _createProfilesTable(transaction);
      await _insertDefaultProfile(transaction);

      await transaction.execute('''
        ALTER TABLE $protocolsTable
        ADD COLUMN profile_id TEXT NOT NULL
        DEFAULT '$defaultProfileId'
      ''');

      await transaction.execute('''
        ALTER TABLE $doseRecordsTable
        ADD COLUMN profile_id TEXT NOT NULL
        DEFAULT '$defaultProfileId'
      ''');

      await transaction.execute('''
        ALTER TABLE $weightRecordsTable
        ADD COLUMN profile_id TEXT NOT NULL
        DEFAULT '$defaultProfileId'
      ''');

      await transaction.execute('''
        ALTER TABLE $inventoryTable
        ADD COLUMN profile_id TEXT NOT NULL
        DEFAULT '$defaultProfileId'
      ''');

      await _createProfileIndexes(transaction);
    });
  }

  Future<void> _addProtocolDoseColumns(Database database) async {
    await database.transaction((transaction) async {
      await transaction.execute('''
        ALTER TABLE $protocolsTable
        ADD COLUMN dose_amount REAL
      ''');

      await transaction.execute('''
        ALTER TABLE $protocolsTable
        ADD COLUMN dose_unit TEXT
      ''');
    });
  }

  Future<void> _addCycleColumns(Database database) async {
    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN use_cycle INTEGER NOT NULL
      DEFAULT 0
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN cycle_start_date TEXT
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN cycle_on_duration INTEGER NOT NULL
      DEFAULT 1
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN cycle_on_unit TEXT NOT NULL
      DEFAULT 'weeks'
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN cycle_off_duration INTEGER NOT NULL
      DEFAULT 0
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN cycle_off_unit TEXT NOT NULL
      DEFAULT 'weeks'
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN repeat_cycle INTEGER NOT NULL
      DEFAULT 0
    ''');
  }

  Future<void> _addReminderColumns(Database database) async {
    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN reminder_enabled INTEGER NOT NULL
      DEFAULT 0
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN reminder_minutes_before INTEGER NOT NULL
      DEFAULT 0
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN missed_dose_reminder_enabled INTEGER NOT NULL
      DEFAULT 0
    ''');

    await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN missed_dose_reminder_minutes_after INTEGER NOT NULL
      DEFAULT 60
    ''');
  }

  Future<void> _createProfilesTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $profilesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code_point INTEGER,
        color_value INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _insertDefaultProfile(DatabaseExecutor database) async {
    final now = DateTime.now().toIso8601String();

    await database.insert(profilesTable, {
      'id': defaultProfileId,
      'name': 'Frank',
      'type': 'self',
      'icon_code_point': null,
      'color_value': null,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _createProtocolsTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE $protocolsTable (
        id TEXT PRIMARY KEY,

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        dose_amount REAL,
        dose_unit TEXT,
        status TEXT NOT NULL,

        color_value INTEGER NOT NULL
          DEFAULT 4284960932,

        schedule_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        interval_days INTEGER,
        weekday INTEGER,
        specific_weekdays TEXT,
        monthly_day INTEGER,

        use_cycle INTEGER NOT NULL
          DEFAULT 0,
        cycle_start_date TEXT,
        cycle_on_duration INTEGER NOT NULL
          DEFAULT 1,
        cycle_on_unit TEXT NOT NULL
          DEFAULT 'weeks',
        cycle_off_duration INTEGER NOT NULL
          DEFAULT 0,
        cycle_off_unit TEXT NOT NULL
          DEFAULT 'weeks',
        repeat_cycle INTEGER NOT NULL
          DEFAULT 0,

        reminder_enabled INTEGER NOT NULL
          DEFAULT 0,
        reminder_minutes_before INTEGER NOT NULL
          DEFAULT 0,
        missed_dose_reminder_enabled INTEGER NOT NULL
          DEFAULT 0,
        missed_dose_reminder_minutes_after INTEGER NOT NULL
          DEFAULT 60,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createDoseRecordsTable(Database database) async {
    await database.execute('''
      CREATE TABLE $doseRecordsTable (
        id TEXT PRIMARY KEY,

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        protocol_id TEXT NOT NULL,
        scheduled_for TEXT NOT NULL,
        completed_at TEXT,
        scheduled_amount TEXT NOT NULL,
        actual_amount TEXT,
        status TEXT NOT NULL,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE,

        FOREIGN KEY (protocol_id)
          REFERENCES $protocolsTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX
      idx_dose_records_protocol_schedule
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

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        weight REAL NOT NULL,
        recorded_at TEXT NOT NULL,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX
      idx_weight_records_recorded_at
      ON $weightRecordsTable (
        recorded_at
      )
    ''');
  }

  Future<void> _createInventoryTable(Database database) async {
    await database.execute('''
      CREATE TABLE $inventoryTable (
        id TEXT PRIMARY KEY,

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        protocol_id TEXT NOT NULL,
        vial_size REAL NOT NULL,
        current_amount REAL NOT NULL,
        unit TEXT NOT NULL,

        container_type TEXT NOT NULL
          DEFAULT 'Container',

        unopened_quantity INTEGER NOT NULL
          DEFAULT 0,

        low_stock_threshold INTEGER NOT NULL
          DEFAULT 1,

        shipping_days INTEGER NOT NULL
          DEFAULT 14,

        current_container_opened_at TEXT,
        vendor TEXT,
        batch TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE,

        FOREIGN KEY (protocol_id)
          REFERENCES $protocolsTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX
      idx_inventory_protocol_id
      ON $inventoryTable (
        protocol_id
      )
    ''');
  }

  Future<void> _createProfileIndexes(DatabaseExecutor database) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_protocols_profile_id
      ON $protocolsTable (
        profile_id
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_dose_records_profile_id
      ON $doseRecordsTable (
        profile_id
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_weight_records_profile_id
      ON $weightRecordsTable (
        profile_id
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_inventory_profile_id
      ON $inventoryTable (
        profile_id
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

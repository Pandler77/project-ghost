import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String databaseName = 'ghost.db';
  static const int databaseVersion = 43;

  static const String profilesTable = 'profiles';
  static const String protocolsTable = 'protocols';
  static const String doseRecordsTable = 'dose_records';
  static const String weightRecordsTable = 'weight_records';
  static const String inventoryTable = 'inventory';
  static const String injectionLogsTable = 'injection_logs';
  static const String inventoryEventsTable = 'inventory_events';
  static const String inventoryPhotosTable = 'inventory_photos';
  static const String inventoryBatchesTable = 'inventory_batches';
  static const String progressPhotosTable = 'progress_photos';
  static const String progressPhotoSessionsTable = 'progress_photo_sessions';
  static const String symptomEntriesTable = 'symptom_entries';
  static const String symptomProtocolLinksTable = 'symptom_protocol_links';
  static const String doseSafetyAcknowledgementsTable =
      'dose_safety_acknowledgements';
  static const String scheduleOverridesTable = 'schedule_overrides';

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

  Future<bool> _columnExists(
    DatabaseExecutor database,
    String table,
    String column,
  ) async {
    final columns = await database.rawQuery('PRAGMA table_info($table)');

    return columns.any((entry) => entry['name'] == column);
  }

  Future<void> _addColumnIfMissing(
    DatabaseExecutor database, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final exists = await _columnExists(database, table, column);

    if (exists) {
      return;
    }

    await database.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _onCreate(Database database, int version) async {
    await _createProfilesTable(database);
    await _insertDefaultProfile(database);

    await _createProtocolsTable(database);
    await _createDoseRecordsTable(database);
    await _createWeightRecordsTable(database);
    await _createInventoryTable(database);

    await _createProfileIndexes(database);
    await _createInjectionLogsTable(database);
    await _createInventoryEventsTable(database);
    await _createInventoryPhotosTable(database);
    await _createInventoryBatchesTable(database);
    await _createProgressPhotoSessionsTable(database);
    await _createProgressPhotosTable(database);
    await _createSymptomEntriesTable(database);
    await _createSymptomProtocolLinksTable(database);
    await _createDoseSafetyAcknowledgementsTable(database);
    await _createScheduleOverridesTable(database);
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
      await _addColumnIfMissing(
        database,
        table: protocolsTable,
        column: 'color_value',
        definition: 'INTEGER NOT NULL DEFAULT 4284960932',
      );
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
      await _addColumnIfMissing(
        database,
        table: inventoryTable,
        column: 'container_type',
        definition: "TEXT NOT NULL DEFAULT 'Container'",
      );
    }

    if (oldVersion < 9) {
      await _addColumnIfMissing(
        database,
        table: inventoryTable,
        column: 'current_container_opened_at',
        definition: 'TEXT',
      );
    }

    if (oldVersion < 10) {
      await _addProfiles(database);
    }

    if (oldVersion < 11) {
      await _addProtocolDoseColumns(database);
    }

    if (oldVersion < 12) {
      await _addColumnIfMissing(
        database,
        table: profilesTable,
        column: 'enabled_modules',
        definition: "TEXT NOT NULL DEFAULT 'protocols,weight,inventory'",
      );
    }

    if (oldVersion < 13) {
      await _addColumnIfMissing(
        database,
        table: profilesTable,
        column: 'avatar_image_path',
        definition: 'TEXT',
      );
    }

    if (oldVersion < 14) {
      await _addColumnIfMissing(
        database,
        table: protocolsTable,
        column: 'protocol_type',
        definition: "TEXT NOT NULL DEFAULT 'injection'",
      );
    }

    if (oldVersion < 15) {
      await _addColumnIfMissing(
        database,
        table: protocolsTable,
        column: 'rotation_enabled',
        definition: 'INTEGER NOT NULL DEFAULT 0',
      );

      await _addColumnIfMissing(
        database,
        table: protocolsTable,
        column: 'rotation_mode',
        definition: "TEXT NOT NULL DEFAULT 'sequential'",
      );

      await _addColumnIfMissing(
        database,
        table: protocolsTable,
        column: 'enabled_injection_sites',
        definition: 'TEXT',
      );
    }

    if (oldVersion < 16) {
      await _createInjectionLogsTable(database);
    }

    if (oldVersion < 17) {
      await _migrateInjectionLogsToDoseRecords(database);
    }

    if (oldVersion < 18) {
      await _addInventoryMetadataColumns(database);
    }

    if (oldVersion < 19) {
      await _createInventoryEventsTable(database);
    }

    if (oldVersion < 20) {
      await _createInventoryPhotosTable(database);
    }

    if (oldVersion < 21) {
      await _addSupplyCapacityColumn(database);
    }

    if (oldVersion < 22) {
      await _createInventoryBatchesTable(database);
      await _migrateExistingInventoryToBatches(database);
    }

    if (oldVersion < 23) {
      await _addCurrentContainerBatchIdColumn(database);
    }

    if (oldVersion < 24) {
      await _addInventoryBatchNameColumn(database);
    }

    if (oldVersion < 25) {
      await _addInventoryDisplayNameColumn(database);
    }

    if (oldVersion < 26) {
      await _addProtocolCategoryColumn(database);
    }

    if (oldVersion < 27) {
      await _addProfileGoalWeightColumn(database);
    }

    if (oldVersion < 28) {
      await _addProfileStartingWeightColumn(database);
    }

    if (oldVersion < 29) {
      await _createProgressPhotosTable(database);
    }

    if (oldVersion < 30) {
      await _addProgressPhotoProfileIdColumn(database);
    }

    if (oldVersion < 31) {
      await _createProgressPhotoSessionsTable(database);
      await _addProgressPhotoSessionIdColumn(database);
    }

    if (oldVersion < 32) {
      await _createSymptomEntriesTable(database);
    }

    if (oldVersion < 33) {
      await _createSymptomProtocolLinksTable(database);
    }

    if (oldVersion < 34) {
      await _addProfileHeightColumn(database);
    }

    if (oldVersion < 35) {
      await _addProtocolCustomReminderColumns(database);
    }

    if (oldVersion < 36) {
      await _addProtocolCustomReminderColumns(database);
    }

    if (oldVersion < 37) {
      await _addProtocolAdvancedDoseColumn(database);
    }

    if (oldVersion < 38) {
      await _addDoseRecordSnapshotColumns(database);
    }

    // Repair installs that reached v39 without the follow-up text columns.
    if (oldVersion < 40) {
      await _addProtocolCustomFollowUpColumns(database);
    }

    if (oldVersion < 41) {
      await _addProtocolSoftDeleteColumn(database);
    }

    if (oldVersion < 42) {
      await _createDoseSafetyAcknowledgementsTable(database);
    }

    if (oldVersion < 43) {
      await _createScheduleOverridesTable(database);
    }
  }

  Future<void> _addProfiles(Database database) async {
    await database.transaction((transaction) async {
      await _createProfilesTable(transaction);
      await _insertDefaultProfile(transaction);

      await _addColumnIfMissing(
        transaction,
        table: protocolsTable,
        column: 'profile_id',
        definition: "TEXT NOT NULL DEFAULT '$defaultProfileId'",
      );
      await _addColumnIfMissing(
        transaction,
        table: doseRecordsTable,
        column: 'profile_id',
        definition: "TEXT NOT NULL DEFAULT '$defaultProfileId'",
      );
      await _addColumnIfMissing(
        transaction,
        table: weightRecordsTable,
        column: 'profile_id',
        definition: "TEXT NOT NULL DEFAULT '$defaultProfileId'",
      );
      await _addColumnIfMissing(
        transaction,
        table: inventoryTable,
        column: 'profile_id',
        definition: "TEXT NOT NULL DEFAULT '$defaultProfileId'",
      );

      await _createProfileIndexes(transaction);
    });
  }

  Future<void> _addProtocolDoseColumns(Database database) async {
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'dose_amount',
      definition: 'REAL',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'dose_unit',
      definition: 'TEXT',
    );
  }

  Future<void> _addProtocolAdvancedDoseColumn(Database database) async {
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'advanced_dose_json',
      definition: 'TEXT',
    );
  }

  Future<void> _addCycleColumns(Database database) async {
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'use_cycle',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'cycle_start_date',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'cycle_on_duration',
      definition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'cycle_on_unit',
      definition: "TEXT NOT NULL DEFAULT 'weeks'",
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'cycle_off_duration',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'cycle_off_unit',
      definition: "TEXT NOT NULL DEFAULT 'weeks'",
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'repeat_cycle',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _addReminderColumns(Database database) async {
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'reminder_enabled',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'reminder_minutes_before',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'missed_dose_reminder_enabled',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'missed_dose_reminder_minutes_after',
      definition: 'INTEGER NOT NULL DEFAULT 60',
    );
  }

  Future<void> _addProtocolCustomReminderColumns(Database database) async {
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'custom_reminder_title',
      definition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'custom_reminder_body',
      definition: 'TEXT',
    );
  }

  Future<void> _addProtocolCustomFollowUpColumns(Database database) async {
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'custom_follow_up_title',
      definition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'custom_follow_up_body',
      definition: 'TEXT',
    );
  }

  Future<void> _addProtocolSoftDeleteColumn(Database database) async {
    await _addColumnIfMissing(
      database,
      table: protocolsTable,
      column: 'is_deleted',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _createProgressPhotosTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $progressPhotosTable (
        id TEXT PRIMARY KEY,

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        session_id TEXT NOT NULL,

        image_path TEXT NOT NULL,
        type TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        weight REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE,

        FOREIGN KEY (session_id)
          REFERENCES $progressPhotoSessionsTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_progress_photos_profile_id
      ON $progressPhotosTable (
        profile_id
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_progress_photos_session_id
      ON $progressPhotosTable (
        session_id
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_progress_photos_recorded_at
      ON $progressPhotosTable (
        recorded_at
      )
    ''');
  }

  Future<void> _addProgressPhotoSessionIdColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($progressPhotosTable)',
    );

    final hasSessionId = columns.any(
      (column) => column['name'] == 'session_id',
    );

    if (!hasSessionId) {
      await database.execute('''
        ALTER TABLE $progressPhotosTable
        ADD COLUMN session_id TEXT
      ''');
    }

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_progress_photos_session_id
      ON $progressPhotosTable (
        session_id
      )
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
        avatar_image_path TEXT,
        starting_weight REAL,
        goal_weight REAL,
        height_cm REAL,
        enabled_modules TEXT NOT NULL
        DEFAULT 'protocols,weight,inventory',
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
      'enabled_modules': 'protocols,weight,inventory',
      'created_at': now,
      'updated_at': now,
      'avatar_image_path': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _createProtocolsTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $protocolsTable (
        id TEXT PRIMARY KEY,

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        name TEXT NOT NULL,
        protocol_category TEXT NOT NULL DEFAULT 'custom',
        protocol_type TEXT NOT NULL
        DEFAULT 'injection',
        
        dose TEXT NOT NULL,
        dose_amount REAL,
        dose_unit TEXT,
        advanced_dose_json TEXT,
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
        rotation_enabled INTEGER NOT NULL DEFAULT 0,
        rotation_mode TEXT NOT NULL DEFAULT 'sequential',
        enabled_injection_sites TEXT,
        reminder_enabled INTEGER NOT NULL
          DEFAULT 0,
        reminder_minutes_before INTEGER NOT NULL
          DEFAULT 0,
        missed_dose_reminder_enabled INTEGER NOT NULL
          DEFAULT 0,
        missed_dose_reminder_minutes_after INTEGER NOT NULL
          DEFAULT 60,
        custom_reminder_title TEXT,
        custom_reminder_body TEXT,
        custom_follow_up_title TEXT,
        custom_follow_up_body TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createDoseRecordsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $doseRecordsTable (
        id TEXT PRIMARY KEY,

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        protocol_id TEXT NOT NULL,
        scheduled_for TEXT NOT NULL,
        completed_at TEXT,
        scheduled_amount TEXT NOT NULL,
        actual_amount TEXT,
        status TEXT NOT NULL,
        protocol_name_snapshot TEXT,
        protocol_type_snapshot TEXT,
        protocol_color_value_snapshot INTEGER,
        advanced_dose_json_snapshot TEXT,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE,

        FOREIGN KEY (protocol_id)
          REFERENCES $protocolsTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS
      idx_dose_records_protocol_schedule
      ON $doseRecordsTable (
        protocol_id,
        scheduled_for
      )
    ''');
  }

  Future<void> _addDoseRecordSnapshotColumns(
    Database database,
  ) async {
    await _addColumnIfMissing(
      database,
      table: doseRecordsTable,
      column: 'protocol_name_snapshot',
      definition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      table: doseRecordsTable,
      column: 'protocol_type_snapshot',
      definition: 'TEXT',
    );

    await _addColumnIfMissing(
      database,
      table: doseRecordsTable,
      column: 'protocol_color_value_snapshot',
      definition: 'INTEGER',
    );

    await _addColumnIfMissing(
      database,
      table: doseRecordsTable,
      column: 'advanced_dose_json_snapshot',
      definition: 'TEXT',
    );
  }

  Future<void> _createWeightRecordsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $weightRecordsTable (
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
      CREATE INDEX IF NOT EXISTS
      idx_weight_records_recorded_at
      ON $weightRecordsTable (
        recorded_at
      )
    ''');
  }

  Future<void> _createInventoryTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $inventoryTable (
        id TEXT PRIMARY KEY,

        profile_id TEXT NOT NULL
          DEFAULT '$defaultProfileId',

        protocol_id TEXT NOT NULL,
        display_name TEXT,
        vial_size REAL NOT NULL,
        current_amount REAL NOT NULL,
        supply_capacity REAL,
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
        current_container_batch_id TEXT,
        reconstitution_volume_ml REAL,
        expiration_date TEXT,
        storage_instructions TEXT,
        purchase_date TEXT,
        cost REAL,
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
      CREATE INDEX IF NOT EXISTS
      idx_inventory_protocol_id
      ON $inventoryTable (
        protocol_id
      )
    ''');
  }

  Future<void> _createInventoryEventsTable(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS $inventoryEventsTable (
      id TEXT PRIMARY KEY,
      inventory_item_id TEXT NOT NULL,
      protocol_id TEXT NOT NULL,
      type TEXT NOT NULL,
      amount_changed REAL NOT NULL,
      amount_after REAL NOT NULL,
      unopened_quantity_after INTEGER NOT NULL,
      notes TEXT,
      occurred_at TEXT NOT NULL,

      FOREIGN KEY (inventory_item_id)
        REFERENCES $inventoryTable (id)
        ON DELETE CASCADE,

      FOREIGN KEY (protocol_id)
        REFERENCES $protocolsTable (id)
        ON DELETE CASCADE
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_inventory_events_inventory_item_id
    ON $inventoryEventsTable (
      inventory_item_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_inventory_events_protocol_id
    ON $inventoryEventsTable (
      protocol_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_inventory_events_occurred_at
    ON $inventoryEventsTable (
      occurred_at
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

  Future<void> _createInjectionLogsTable(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS $injectionLogsTable (
      id TEXT PRIMARY KEY,
      protocol_id TEXT NOT NULL,
      dose_record_id TEXT NOT NULL,
      site TEXT NOT NULL,
      logged_at TEXT NOT NULL,
      notes TEXT,

      FOREIGN KEY (protocol_id)
        REFERENCES $protocolsTable (id)
        ON DELETE CASCADE,

      FOREIGN KEY (dose_record_id)
        REFERENCES $doseRecordsTable (id)
        ON DELETE CASCADE
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_injection_logs_protocol_id
    ON $injectionLogsTable (
      protocol_id
    )
  ''');

    await database.execute('''
    CREATE UNIQUE INDEX IF NOT EXISTS
    idx_injection_logs_dose_record_id
    ON $injectionLogsTable (
      dose_record_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_injection_logs_logged_at
    ON $injectionLogsTable (
      logged_at
    )
  ''');
  }

  Future<void> _createInventoryBatchesTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $inventoryBatchesTable (
        id TEXT PRIMARY KEY,
        inventory_item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        container_size REAL NOT NULL,
        unit TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        vendor TEXT,
        batch TEXT,
        purchase_date TEXT,
        expiration_date TEXT,
        cost REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,

        FOREIGN KEY (inventory_item_id)
          REFERENCES $inventoryTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_inventory_batches_inventory_item_id
      ON $inventoryBatchesTable (
        inventory_item_id
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_inventory_batches_expiration_date
      ON $inventoryBatchesTable (
        expiration_date
      )
    ''');
  }

  Future<void> _createScheduleOverridesTable(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $scheduleOverridesTable (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        protocol_id TEXT NOT NULL,
        override_type TEXT NOT NULL,
        original_scheduled_for TEXT,
        override_scheduled_for TEXT,
        created_at TEXT NOT NULL,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE,

        FOREIGN KEY (protocol_id)
          REFERENCES $protocolsTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_schedule_overrides_profile_id
      ON $scheduleOverridesTable (profile_id)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_schedule_overrides_protocol_id
      ON $scheduleOverridesTable (protocol_id)
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS
      idx_schedule_overrides_original_occurrence
      ON $scheduleOverridesTable (
        profile_id,
        protocol_id,
        original_scheduled_for
      )
      WHERE original_scheduled_for IS NOT NULL
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_schedule_overrides_target_time
      ON $scheduleOverridesTable (override_scheduled_for)
    ''');
  }

  Future<void> _createDoseSafetyAcknowledgementsTable(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $doseSafetyAcknowledgementsTable (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        acknowledgement_type TEXT NOT NULL,
        version INTEGER NOT NULL,
        accepted_at TEXT NOT NULL,

        FOREIGN KEY (profile_id)
          REFERENCES $profilesTable (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS
      idx_dose_safety_ack_profile_type_version
      ON $doseSafetyAcknowledgementsTable (
        profile_id,
        acknowledgement_type,
        version
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS
      idx_dose_safety_ack_accepted_at
      ON $doseSafetyAcknowledgementsTable (
        accepted_at
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

  Future<void> resetDatabase() async {
    await close();

    final databasesPath = await getDatabasesPath();
    final databasePath = join(databasesPath, databaseName);

    await deleteDatabase(databasePath);
  }

  Future<void> _migrateInjectionLogsToDoseRecords(Database database) async {
    await database.transaction((transaction) async {
      await transaction.execute('''
      ALTER TABLE $injectionLogsTable
      RENAME TO injection_logs_legacy
    ''');

      await transaction.execute('''
      DROP INDEX IF EXISTS idx_injection_logs_protocol_id
    ''');

      await transaction.execute('''
      DROP INDEX IF EXISTS idx_injection_logs_logged_at
    ''');

      await transaction.execute('''
      DROP INDEX IF EXISTS idx_injection_logs_dose_record_id
    ''');

      await _createInjectionLogsTable(transaction);

      await transaction.execute('''
      INSERT INTO $injectionLogsTable (
        id,
        protocol_id,
        dose_record_id,
        site,
        logged_at,
        notes
      )
      SELECT
        injection_logs_legacy.id,
        injection_logs_legacy.protocol_id,
        $doseRecordsTable.id,
        injection_logs_legacy.site,
        injection_logs_legacy.logged_at,
        injection_logs_legacy.notes
      FROM injection_logs_legacy
      INNER JOIN $doseRecordsTable
        ON $doseRecordsTable.protocol_id =
          injection_logs_legacy.protocol_id
        AND $doseRecordsTable.completed_at =
          injection_logs_legacy.logged_at
    ''');

      await transaction.execute('''
      DROP TABLE injection_logs_legacy
    ''');
    });
  }

  Future<void> _addInventoryMetadataColumns(Database database) async {
    await database.transaction((transaction) async {
      await _addColumnIfMissing(
        transaction,
        table: inventoryTable,
        column: 'reconstitution_volume_ml',
        definition: 'REAL',
      );
      await _addColumnIfMissing(
        transaction,
        table: inventoryTable,
        column: 'expiration_date',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        transaction,
        table: inventoryTable,
        column: 'storage_instructions',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        transaction,
        table: inventoryTable,
        column: 'purchase_date',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        transaction,
        table: inventoryTable,
        column: 'cost',
        definition: 'REAL',
      );
    });
  }

  Future<void> _createInventoryPhotosTable(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS $inventoryPhotosTable (
      id TEXT PRIMARY KEY,
      inventory_item_id TEXT NOT NULL,
      image_path TEXT NOT NULL,
      caption TEXT,
      created_at TEXT NOT NULL,

      FOREIGN KEY (inventory_item_id)
        REFERENCES $inventoryTable (id)
        ON DELETE CASCADE
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_inventory_photos_inventory_item_id
    ON $inventoryPhotosTable (
      inventory_item_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_inventory_photos_created_at
    ON $inventoryPhotosTable (
      created_at
    )
  ''');
  }

  Future<void> _addSupplyCapacityColumn(Database database) async {
    await database.transaction((transaction) async {
      await _addColumnIfMissing(
        transaction,
        table: inventoryTable,
        column: 'supply_capacity',
        definition: 'REAL',
      );

      await transaction.execute('''
      UPDATE $inventoryTable
      SET supply_capacity =
        current_amount + (vial_size * unopened_quantity)
      WHERE supply_capacity IS NULL
    ''');
    });
  }

  Future<void> _migrateExistingInventoryToBatches(Database database) async {
    final now = DateTime.now().toIso8601String();

    await database.execute('''
    INSERT INTO $inventoryBatchesTable (
      id,
      inventory_item_id,
      name,
      container_size,
      unit,
      quantity,
      vendor,
      batch,
      purchase_date,
      expiration_date,
      cost,
      notes,
      created_at,
      updated_at
    )
    SELECT
      id || '-initial-batch',
      id,
      CAST(vial_size AS TEXT) || ' ' || unit || ' Batch',
      vial_size,
      unit,
      unopened_quantity,
      vendor,
      batch,
      purchase_date,
      expiration_date,
      cost,
      notes,
      '$now',
      '$now'
    FROM $inventoryTable
    WHERE unopened_quantity > 0
      AND NOT EXISTS (
        SELECT 1
        FROM $inventoryBatchesTable
        WHERE inventory_item_id = $inventoryTable.id
      )
  ''');
  }

  Future<void> _addCurrentContainerBatchIdColumn(Database database) async {
    await _addColumnIfMissing(
      database,
      table: inventoryTable,
      column: 'current_container_batch_id',
      definition: 'TEXT',
    );
  }

  Future<void> _addInventoryBatchNameColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($inventoryBatchesTable)',
    );

    final hasNameColumn = columns.any((column) => column['name'] == 'name');

    if (!hasNameColumn) {
      await database.execute('''
        ALTER TABLE $inventoryBatchesTable
        ADD COLUMN name TEXT
      ''');
    }

    await database.execute('''
      UPDATE $inventoryBatchesTable
      SET name =
        CAST(container_size AS TEXT) || ' ' || unit || ' Batch'
      WHERE name IS NULL OR TRIM(name) = ''
    ''');
  }

  Future<void> _addInventoryDisplayNameColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($inventoryTable)',
    );

    final hasDisplayNameColumn = columns.any(
      (column) => column['name'] == 'display_name',
    );

    if (!hasDisplayNameColumn) {
      await database.execute('''
      ALTER TABLE $inventoryTable
      ADD COLUMN display_name TEXT
    ''');
    }
  }

  Future<void> _addProtocolCategoryColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($protocolsTable)',
    );

    final hasCategoryColumn = columns.any(
      (column) => column['name'] == 'protocol_category',
    );

    if (!hasCategoryColumn) {
      await database.execute('''
      ALTER TABLE $protocolsTable
      ADD COLUMN protocol_category TEXT NOT NULL DEFAULT 'custom'
    ''');
    }
  }

  Future<void> _addProfileGoalWeightColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($profilesTable)',
    );

    final hasGoalWeightColumn = columns.any(
      (column) => column['name'] == 'goal_weight',
    );

    if (!hasGoalWeightColumn) {
      await database.execute('''
      ALTER TABLE $profilesTable
      ADD COLUMN goal_weight REAL
    ''');
    }
  }

  Future<void> _addProfileStartingWeightColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($profilesTable)',
    );

    final hasStartingWeightColumn = columns.any(
      (column) => column['name'] == 'starting_weight',
    );

    if (!hasStartingWeightColumn) {
      await database.execute('''
      ALTER TABLE $profilesTable
      ADD COLUMN starting_weight REAL
    ''');
    }
  }

  Future<void> _addProfileHeightColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($profilesTable)',
    );

    final hasHeightColumn = columns.any(
      (column) => column['name'] == 'height_cm',
    );

    if (!hasHeightColumn) {
      await database.execute('''
      ALTER TABLE $profilesTable
      ADD COLUMN height_cm REAL
    ''');
    }
  }

  Future<void> _addProgressPhotoProfileIdColumn(Database database) async {
    final columns = await database.rawQuery(
      'PRAGMA table_info($progressPhotosTable)',
    );

    final hasProfileId = columns.any(
      (column) => column['name'] == 'profile_id',
    );

    if (!hasProfileId) {
      await database.execute('''
      ALTER TABLE $progressPhotosTable
      ADD COLUMN profile_id TEXT NOT NULL
      DEFAULT '$defaultProfileId'
    ''');
    }

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_progress_photos_profile_id
    ON $progressPhotosTable (
      profile_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_progress_photos_recorded_at
    ON $progressPhotosTable (
      recorded_at
    )
  ''');
  }

  Future<void> _createProgressPhotoSessionsTable(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS $progressPhotoSessionsTable (
      id TEXT PRIMARY KEY,

      profile_id TEXT NOT NULL
        DEFAULT '$defaultProfileId',

      recorded_at TEXT NOT NULL,
      weight REAL,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,

      FOREIGN KEY (profile_id)
        REFERENCES $profilesTable (id)
        ON DELETE CASCADE
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_progress_photo_sessions_profile_id
    ON $progressPhotoSessionsTable (
      profile_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_progress_photo_sessions_recorded_at
    ON $progressPhotoSessionsTable (
      recorded_at
    )
  ''');
  }

  Future<void> _createSymptomEntriesTable(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS $symptomEntriesTable (
      id TEXT PRIMARY KEY,

      profile_id TEXT NOT NULL
        DEFAULT '$defaultProfileId',

      symptom_name TEXT NOT NULL,
      severity INTEGER NOT NULL,
      notes TEXT,
      recorded_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,

      FOREIGN KEY (profile_id)
        REFERENCES $profilesTable (id)
        ON DELETE CASCADE
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_symptom_entries_profile_id
    ON $symptomEntriesTable (
      profile_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_symptom_entries_recorded_at
    ON $symptomEntriesTable (
      recorded_at
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_symptom_entries_symptom_name
    ON $symptomEntriesTable (
      symptom_name
    )
  ''');
  }

  Future<void> _createSymptomProtocolLinksTable(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS $symptomProtocolLinksTable (
      symptom_entry_id TEXT NOT NULL,
      protocol_id TEXT NOT NULL,

      PRIMARY KEY (
        symptom_entry_id,
        protocol_id
      ),

      FOREIGN KEY (symptom_entry_id)
        REFERENCES $symptomEntriesTable (id)
        ON DELETE CASCADE,

      FOREIGN KEY (protocol_id)
        REFERENCES $protocolsTable (id)
        ON DELETE CASCADE
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_symptom_protocol_links_symptom_entry_id
    ON $symptomProtocolLinksTable (
      symptom_entry_id
    )
  ''');

    await database.execute('''
    CREATE INDEX IF NOT EXISTS
    idx_symptom_protocol_links_protocol_id
    ON $symptomProtocolLinksTable (
      protocol_id
    )
  ''');
  }
}

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_tables.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'haushaltsbuch.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbTables.userMemberships} (
        id TEXT PRIMARY KEY,
        household_id TEXT NOT NULL,
        aktiv INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.households} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        aktiv INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.users}  (
        id TEXT PRIMARY KEY,
        household_id TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        aktiv INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.entries} (
        id TEXT PRIMARY KEY,
        household_id TEXT NOT NULL,
        datum TEXT NOT NULL,
        kategorie TEXT NOT NULL,
        person TEXT NOT NULL,
        betrag INTEGER NOT NULL,
        notiz TEXT,
        year_month TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.fixedCosts} (
        id TEXT PRIMARY KEY,
        household_id TEXT NOT NULL,
        bezeichnung TEXT NOT NULL,
        betrag INTEGER NOT NULL,
        kategorie TEXT NOT NULL,
        person TEXT NOT NULL,
        intervall TEXT NOT NULL,
        start_monat TEXT NOT NULL,
        aktiv INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.vacations} (
        id TEXT PRIMARY KEY,
        household_id TEXT NOT NULL,
        name TEXT NOT NULL,
        start_datum TEXT NOT NULL,
        end_datum TEXT NOT NULL,
        aktiv INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.vacationEntries} (
        id TEXT PRIMARY KEY,
        household_id TEXT NOT NULL,
        vacation_id TEXT NOT NULL,
        datum TEXT NOT NULL,
        kategorie TEXT NOT NULL,
        person TEXT NOT NULL,
        betrag INTEGER NOT NULL,
        notiz TEXT,
        year_month TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_entries_household_year_month ON ${DbTables.entries}(household_id, year_month)',
    );

    await db.execute(
      'CREATE INDEX idx_fixed_costs_household_aktiv ON ${DbTables.fixedCosts}(household_id, aktiv)',
    );

    await db.execute(
      'CREATE INDEX idx_vacations_household_aktiv ON ${DbTables.vacations}(household_id, aktiv)',
    );

    await db.execute(
      'CREATE INDEX idx_vacation_entries_household_year_month ON ${DbTables.vacationEntries}(household_id, year_month)',
    );
  }
}
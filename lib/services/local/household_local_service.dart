import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_tables.dart';
import '../../core/constants/sync_status.dart';
import 'app_database.dart';

class HouseholdLocalService {
  HouseholdLocalService();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<void> saveHousehold({
    required String id,
    required String name,
    required String createdAt,
    required bool aktiv,
    String syncStatus = SyncStatus.synced,
    String? lastSyncedAt,
  }) async {
    final db = await _db;

    await db.insert(
      DbTables.households,
      {
        'id': id,
        'name': name,
        'created_at': createdAt,
        'aktiv': aktiv ? 1 : 0,
        'sync_status': syncStatus,
        'last_synced_at': lastSyncedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getHouseholdById(String id) async {
    final db = await _db;

    final result = await db.query(
      DbTables.households,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<void> updateHousehold({
    required String id,
    required String name,
    required bool aktiv,
    String syncStatus = SyncStatus.pendingUpdate,
    String? lastSyncedAt,
  }) async {
    final db = await _db;

    await db.update(
      DbTables.households,
      {
        'name': name,
        'aktiv': aktiv ? 1 : 0,
        'sync_status': syncStatus,
        'last_synced_at': lastSyncedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteHousehold(String id) async {
    final db = await _db;

    await db.delete(
      DbTables.households,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllHouseholds() async {
    final db = await _db;
    await db.delete(DbTables.households);
  }
}

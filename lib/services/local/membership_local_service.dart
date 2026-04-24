import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_tables.dart';
import '../../core/constants/sync_status.dart';
import 'app_database.dart';

class MembershipLocalService {
  MembershipLocalService();

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<void> saveMembership({
    required String userId,
    required String householdId,
    required bool aktiv,
    required String createdAt,
    required String updatedAt,
    String syncStatus = SyncStatus.synced,
    String? lastSyncedAt,
  }) async {
    final db = await _db;

    await db.insert(
      DbTables.userMemberships,
      {
        'id': userId,
        'household_id': householdId,
        'aktiv': aktiv ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_status': syncStatus,
        'last_synced_at': lastSyncedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getMembershipByUserId(String userId) async {
    final db = await _db;

    final result = await db.query(
      DbTables.userMemberships,
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<void> updateMembership({
    required String userId,
    required String householdId,
    required bool aktiv,
    required String updatedAt,
    String syncStatus = SyncStatus.pendingUpdate,
    String? lastSyncedAt,
  }) async {
    final db = await _db;

    await db.update(
      DbTables.userMemberships,
      {
        'household_id': householdId,
        'aktiv': aktiv ? 1 : 0,
        'updated_at': updatedAt,
        'sync_status': syncStatus,
        'last_synced_at': lastSyncedAt,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteMembership(String userId) async {
    final db = await _db;

    await db.delete(
      DbTables.userMemberships,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> clearAllMemberships() async {
    final db = await _db;
    await db.delete(DbTables.userMemberships);
  }
}
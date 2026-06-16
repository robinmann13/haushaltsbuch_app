import '../models/entry.dart';
import '../services/remote/entry_remote_service.dart';

class EntryRepository {
  EntryRepository({EntryRemoteService? entryRemoteService})
      : _entryRemoteService = entryRemoteService ?? EntryRemoteService();

  final EntryRemoteService _entryRemoteService;

  Stream<List<HouseholdTransaction>> watchTransactionsForHousehold(
    String householdId,
  ) {
    return _entryRemoteService.watchTransactionsForHousehold(householdId);
  }

  Future<List<HouseholdTransaction>> getTransactionsForHousehold(
    String householdId,
  ) {
    return _entryRemoteService.getTransactionsForHousehold(householdId);
  }

  Future<String> createTransaction({
    required String householdId,
    required String userId,
    required TransactionType type,
    required int amountCent,
    required String category,
    required DateTime date,
    String? note,
  }) {
    return _entryRemoteService.createTransaction(
      householdId: householdId,
      userId: userId,
      type: type,
      amountCent: amountCent,
      category: category,
      date: date,
      note: note,
    );
  }

  Future<void> updateEntry({
    required String householdId,
    required String entryId,
    required TransactionType type,
    required int amountCent,
    required String category,
    required DateTime date,
    String? note,
  }) {
    return _entryRemoteService.updateEntry(
      householdId: householdId,
      entryId: entryId,
      type: type,
      amountCent: amountCent,
      category: category,
      date: date,
      note: note,
    );
  }

  Future<void> deleteEntry({
    required String householdId,
    required String entryId,
  }) {
    return _entryRemoteService.deleteEntry(
      householdId: householdId,
      entryId: entryId,
    );
  }
}

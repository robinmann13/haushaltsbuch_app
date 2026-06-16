import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/entry.dart';

class EntryRemoteService {
  EntryRemoteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entries(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('entries');
  }

  Stream<List<HouseholdTransaction>> watchTransactionsForHousehold(
    String householdId,
  ) {
    return _entries(householdId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(HouseholdTransaction.fromFirestore)
              .toList(),
        );
  }

  Future<List<HouseholdTransaction>> getTransactionsForHousehold(
    String householdId,
  ) async {
    final snapshot = await _entries(householdId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map(HouseholdTransaction.fromFirestore).toList();
  }

  Future<String> createTransaction({
    required String householdId,
    required String userId,
    required TransactionType type,
    required int amountCent,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final document = _entries(householdId).doc();
    final cleanNote = note?.trim();

    await document.set({
      'householdId': householdId,
      'userId': userId,
      'type': type.value,
      'amountCent': amountCent,
      'category': category.trim(),
      'date': Timestamp.fromDate(date),
      'yearMonth': yearMonthFromDate(date),
      if (cleanNote != null && cleanNote.isNotEmpty) 'note': cleanNote,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }
}

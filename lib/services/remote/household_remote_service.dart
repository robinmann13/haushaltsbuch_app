import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/household.dart';

class HouseholdRemoteService {
  HouseholdRemoteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _households =>
      _firestore.collection('households');

  Future<Household?> getHouseholdById(String householdId) async {
    final snapshot = await _households.doc(householdId).get();

    if (!snapshot.exists) {
      return null;
    }

    return Household.fromFirestore(snapshot);
  }

  Future<String> createPrivateHousehold({
    required String createdBy,
  }) async {
    final document = _households.doc();

    await document.set({
      'name': 'Privater Haushalt',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }
}

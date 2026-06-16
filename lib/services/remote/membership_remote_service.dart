import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_membership.dart';

class MembershipRemoteService {
  MembershipRemoteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _memberships =>
      _firestore.collection('user_memberships');

  Future<UserMembership?> getMembershipForUser(String userId) async {
    final snapshot = await _memberships.doc(userId).get();

    if (!snapshot.exists) {
      return null;
    }

    return UserMembership.fromFirestore(snapshot);
  }

  Future<void> createMembershipForUser({
    required String userId,
    required String householdId,
    required String role,
  }) {
    return _memberships.doc(userId).set({
      'userId': userId,
      'householdId': householdId,
      'role': role,
      'aktiv': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

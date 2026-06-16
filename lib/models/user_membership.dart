import 'package:cloud_firestore/cloud_firestore.dart';

class UserMembership {
  const UserMembership({
    required this.id,
    required this.userId,
    required this.householdId,
    required this.role,
    required this.aktiv,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String householdId;
  final String role;
  final bool aktiv;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get active => aktiv;

  factory UserMembership.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return UserMembership(
      id: snapshot.id,
      userId: data['userId'] as String? ?? snapshot.id,
      householdId: data['householdId'] as String? ?? '',
      role: data['role'] as String? ?? 'member',
      aktiv: data['aktiv'] as bool? ?? false,
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

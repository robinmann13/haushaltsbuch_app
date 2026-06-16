import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  income,
  expense;

  String get value => name;

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}

class HouseholdTransaction {
  const HouseholdTransaction({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.type,
    required this.amountCent,
    required this.category,
    required this.date,
    required this.yearMonth,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String householdId;
  final String userId;
  final TransactionType type;
  final int amountCent;
  final String category;
  final DateTime date;
  final String yearMonth;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HouseholdTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final date = _readDateTime(data['date']) ?? DateTime.now();

    return HouseholdTransaction(
      id: snapshot.id,
      householdId: data['householdId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: TransactionType.fromValue(data['type'] as String? ?? 'expense'),
      amountCent: data['amountCent'] as int? ?? 0,
      category: data['category'] as String? ?? '',
      date: date,
      yearMonth: data['yearMonth'] as String? ?? _yearMonthFromDate(date),
      note: data['note'] as String?,
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }
}

String yearMonthFromDate(DateTime date) => _yearMonthFromDate(date);

String _yearMonthFromDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
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

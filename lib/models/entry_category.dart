import 'entry.dart';

const incomeCategories = [
  'Gehalt',
  'Nebenjob',
  'Rückerstattung',
  'Geschenk',
  'Sonstiges',
];

const expenseCategories = [
  'Lebensmittel',
  'Wohnen / Miete',
  'Nebenkosten',
  'Strom / Gas / Wasser',
  'Internet / Telefon',
  'Versicherungen',
  'Mobilität',
  'Auto',
  'Freizeit',
  'Gesundheit',
  'Haushalt',
  'Kleidung',
  'Abos',
  'Sonstiges',
];

List<String> categoriesForTransactionType(TransactionType type) {
  return switch (type) {
    TransactionType.income => incomeCategories,
    TransactionType.expense => expenseCategories,
  };
}

String defaultCategoryForTransactionType(TransactionType type) {
  return categoriesForTransactionType(type).first;
}

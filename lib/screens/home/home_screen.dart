import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/entry.dart';
import '../../models/entry_category.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/entry_repository.dart';
import '../../repositories/household_repository.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key,
    required this.authRepository,
    required this.householdMembership,
    required this.user,
    EntryRepository? entryRepository,
  }) : _entryRepository = entryRepository ?? EntryRepository();

  final AuthRepository authRepository;
  final HouseholdMembership householdMembership;
  final User user;
  final EntryRepository _entryRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email;
    final household = widget.householdMembership.household;
    final membership = widget.householdMembership.membership;
    final selectedYearMonth = yearMonthFromDate(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haushaltsbuch'),
        actions: [
          TextButton(
            onPressed: widget.authRepository.signOut,
            child: const Text('Abmelden'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Angemeldet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (email != null) Text('E-Mail: $email'),
            Text('Household-ID: ${household.id}'),
            Text('Rolle: ${membership.role}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _openAddTransactionDialog(context),
              child: const Text('Buchung hinzufuegen'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _goToPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Vorheriger Monat',
                ),
                Text(
                  selectedYearMonth,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _goToNextMonth,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Naechster Monat',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<HouseholdTransaction>>(
                stream: widget._entryRepository.watchTransactionsForHousehold(
                  household.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }

                  final transactions =
                      snapshot.data ?? const <HouseholdTransaction>[];
                  final monthlyTransactions = transactions
                      .where(
                        (transaction) =>
                            transaction.yearMonth == selectedYearMonth,
                      )
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  final summary =
                      _MonthSummary.fromTransactions(monthlyTransactions);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MonthSummaryView(summary: summary),
                      const SizedBox(height: 12),
                      Expanded(
                        child: monthlyTransactions.isEmpty
                            ? const Center(
                                child: Text(
                                  'Keine Buchungen in diesem Monat.',
                                ),
                              )
                            : ListView.separated(
                                itemCount: monthlyTransactions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  return _TransactionTile(
                                    transaction: monthlyTransactions[index],
                                    onEdit: () => _openEditTransactionDialog(
                                      context,
                                      monthlyTransactions[index],
                                    ),
                                    onDelete: () => _confirmDeleteTransaction(
                                      context,
                                      monthlyTransactions[index],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddTransactionDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => _AddTransactionDialog(
        entryRepository: widget._entryRepository,
        householdId: widget.householdMembership.household.id,
        userId: widget.user.uid,
        initialDate: _selectedMonth,
      ),
    );
  }

  Future<void> _openEditTransactionDialog(
    BuildContext context,
    HouseholdTransaction transaction,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => _AddTransactionDialog(
        entryRepository: widget._entryRepository,
        householdId: widget.householdMembership.household.id,
        userId: widget.user.uid,
        initialDate: transaction.date,
        transaction: transaction,
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(
    BuildContext context,
    HouseholdTransaction transaction,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buchung loeschen?'),
        content: const Text('Diese Buchung wird dauerhaft geloescht.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await widget._entryRepository.deleteEntry(
        householdId: widget.householdMembership.household.id,
        entryId: transaction.id,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _MonthSummary {
  const _MonthSummary({
    required this.incomeCent,
    required this.expenseCent,
  });

  final int incomeCent;
  final int expenseCent;

  int get balanceCent => incomeCent - expenseCent;

  factory _MonthSummary.fromTransactions(
    List<HouseholdTransaction> transactions,
  ) {
    var incomeCent = 0;
    var expenseCent = 0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          incomeCent += transaction.amountCent;
        case TransactionType.expense:
          expenseCent += transaction.amountCent;
      }
    }

    return _MonthSummary(
      incomeCent: incomeCent,
      expenseCent: expenseCent,
    );
  }
}

class _MonthSummaryView extends StatelessWidget {
  const _MonthSummaryView({required this.summary});

  final _MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Monatsuebersicht',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('Einnahmen: ${_formatAmount(summary.incomeCent)}'),
                Text('Ausgaben: ${_formatAmount(summary.expenseCent)}'),
                Text('Saldo: ${_formatAmount(summary.balanceCent)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final HouseholdTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final note = transaction.note;

    return ListTile(
      title: Text(
        '${_formatDate(transaction.date)} - ${transaction.type.value} - '
        '${transaction.category}',
      ),
      subtitle: note == null || note.isEmpty ? null : Text(note),
      onTap: onEdit,
      leading: IconButton(
        onPressed: onEdit,
        icon: const Icon(Icons.edit),
        tooltip: 'Bearbeiten',
      ),
      isThreeLine: note != null && note.isNotEmpty,
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(_formatAmount(transaction.amountCent)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            tooltip: 'Loeschen',
          ),
        ],
      ),
    );
  }
}

class _AddTransactionDialog extends StatefulWidget {
  const _AddTransactionDialog({
    required this.entryRepository,
    required this.householdId,
    required this.userId,
    required this.initialDate,
    this.transaction,
  });

  final EntryRepository entryRepository;
  final String householdId;
  final String userId;
  final DateTime initialDate;
  final HouseholdTransaction? transaction;

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  late String _category;
  bool _isSaving = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;

    if (transaction == null) {
      _category = defaultCategoryForTransactionType(_type);
      _dateController.text = _formatDate(widget.initialDate);
    } else {
      _type = transaction.type;
      _category = transaction.category.isEmpty
          ? defaultCategoryForTransactionType(_type)
          : transaction.category;
      _amountController.text = _formatAmountForInput(transaction.amountCent);
      _dateController.text = _formatDate(transaction.date);
      _noteController.text = transaction.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountCent = _parseAmountCent(_amountController.text);
    final date = DateTime.tryParse(_dateController.text.trim());

    if (amountCent == null || amountCent <= 0) {
      _showError('Bitte einen gueltigen Betrag eingeben.');
      return;
    }

    if (_category.isEmpty) {
      _showError('Bitte eine Kategorie eingeben.');
      return;
    }

    if (date == null) {
      _showError('Bitte ein Datum im Format JJJJ-MM-TT eingeben.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transaction = widget.transaction;

      if (transaction == null) {
        await widget.entryRepository.createTransaction(
          householdId: widget.householdId,
          userId: widget.userId,
          type: _type,
          amountCent: amountCent,
          category: _category,
          date: date,
          note: _noteController.text,
        );
      } else {
        await widget.entryRepository.updateEntry(
          householdId: widget.householdId,
          entryId: transaction.id,
          type: _type,
          amountCent: amountCent,
          category: _category,
          date: date,
          note: _noteController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<String> get _availableCategories {
    final categories = List<String>.of(categoriesForTransactionType(_type));

    if (_category.isNotEmpty && !categories.contains(_category)) {
      categories.add(_category);
    }

    return categories;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDate() async {
    final initialDate = DateTime.tryParse(_dateController.text.trim()) ??
        DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      _dateController.text = _formatDate(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Buchung bearbeiten' : 'Buchung hinzufuegen'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TransactionType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: const [
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text('expense'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text('income'),
                  ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                            _category =
                                defaultCategoryForTransactionType(value);
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items: _availableCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Betrag',
                  hintText: '12,50',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'Datum',
                  hintText: '2026-06-16',
                  suffixIcon: IconButton(
                    onPressed: _isSaving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Notiz optional',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _formatAmount(int amountCent) {
  final sign = amountCent < 0 ? '-' : '';
  final absoluteAmountCent = amountCent.abs();
  final euros = absoluteAmountCent ~/ 100;
  final cents = (absoluteAmountCent % 100).toString().padLeft(2, '0');
  return '$sign$euros,$cents';
}

String _formatAmountForInput(int amountCent) {
  final euros = amountCent ~/ 100;
  final cents = (amountCent % 100).toString().padLeft(2, '0');
  return '$euros,$cents';
}

int? _parseAmountCent(String value) {
  final normalized = value.trim().replaceAll(',', '.');

  if (normalized.isEmpty) {
    return null;
  }

  final parts = normalized.split('.');

  if (parts.length > 2 || parts.first.isEmpty) {
    return null;
  }

  final euros = int.tryParse(parts.first);

  if (euros == null) {
    return null;
  }

  final centsText = parts.length == 2 ? parts[1] : '';

  if (centsText.length > 2 ||
      int.tryParse(centsText.padRight(2, '0')) == null) {
    return null;
  }

  final cents = centsText.isEmpty
      ? 0
      : int.parse(centsText.padRight(2, '0'));

  return euros * 100 + cents;
}

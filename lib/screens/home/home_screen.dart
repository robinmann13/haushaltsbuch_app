import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/entry.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/entry_repository.dart';
import '../../repositories/household_repository.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final email = user.email;
    final household = householdMembership.household;
    final membership = householdMembership.membership;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haushaltsbuch'),
        actions: [
          TextButton(
            onPressed: authRepository.signOut,
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
            Expanded(
              child: StreamBuilder<List<HouseholdTransaction>>(
                stream: _entryRepository.watchTransactionsForHousehold(
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

                  if (transactions.isEmpty) {
                    return const Center(
                      child: Text('Noch keine Buchungen vorhanden.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _TransactionTile(
                        transaction: transactions[index],
                      );
                    },
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
        entryRepository: _entryRepository,
        householdId: householdMembership.household.id,
        userId: user.uid,
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final HouseholdTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final note = transaction.note;

    return ListTile(
      title: Text(
        '${_formatDate(transaction.date)} - ${transaction.type.value} - '
        '${transaction.category}',
      ),
      subtitle: note == null || note.isEmpty ? null : Text(note),
      trailing: Text(_formatAmount(transaction.amountCent)),
    );
  }
}

class _AddTransactionDialog extends StatefulWidget {
  const _AddTransactionDialog({
    required this.entryRepository,
    required this.householdId,
    required this.userId,
  });

  final EntryRepository entryRepository;
  final String householdId;
  final String userId;

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountCent = _parseAmountCent(_amountController.text);
    final date = DateTime.tryParse(_dateController.text.trim());
    final category = _categoryController.text.trim();

    if (amountCent == null || amountCent <= 0) {
      _showError('Bitte einen gueltigen Betrag eingeben.');
      return;
    }

    if (category.isEmpty) {
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
      await widget.entryRepository.createTransaction(
        householdId: widget.householdId,
        userId: widget.userId,
        type: _type,
        amountCent: amountCent,
        category: category,
        date: date,
        note: _noteController.text,
      );

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
      title: const Text('Buchung hinzufuegen'),
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
                controller: _categoryController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Kategorie'),
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

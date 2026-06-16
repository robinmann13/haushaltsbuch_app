import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/household_repository.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    AuthRepository? authRepository,
    HouseholdRepository? householdRepository,
  })  : _authRepository = authRepository,
        _householdRepository = householdRepository;

  final AuthRepository? _authRepository;
  final HouseholdRepository? _householdRepository;

  @override
  Widget build(BuildContext context) {
    final authRepository = _authRepository ?? AuthRepository();
    final householdRepository =
        _householdRepository ?? HouseholdRepository();

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return LoginScreen(authRepository: authRepository);
        }

        return _HouseholdLoader(
          authRepository: authRepository,
          householdRepository: householdRepository,
          user: user,
        );
      },
    );
  }
}

class _HouseholdLoader extends StatefulWidget {
  const _HouseholdLoader({
    required this.authRepository,
    required this.householdRepository,
    required this.user,
  });

  final AuthRepository authRepository;
  final HouseholdRepository householdRepository;
  final User user;

  @override
  State<_HouseholdLoader> createState() => _HouseholdLoaderState();
}

class _HouseholdLoaderState extends State<_HouseholdLoader> {
  late Future<HouseholdMembership> _householdMembershipFuture;

  @override
  void initState() {
    super.initState();
    _loadHouseholdMembership();
  }

  @override
  void didUpdateWidget(_HouseholdLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.uid != widget.user.uid) {
      _loadHouseholdMembership();
    }
  }

  void _loadHouseholdMembership() {
    _householdMembershipFuture =
        widget.householdRepository.getOrCreatePrivateHouseholdForUser(
      userId: widget.user.uid,
    );
  }

  void _retry() {
    setState(_loadHouseholdMembership);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HouseholdMembership>(
      future: _householdMembershipFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Haushaltsbuch'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Haushalt konnte nicht geladen werden.'),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Erneut versuchen'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.authRepository.signOut,
                      child: const Text('Abmelden'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final householdMembership = snapshot.data;

        if (householdMembership == null) {
          return const Scaffold(
            body: Center(
              child: Text('Keine Haushaltsdaten gefunden.'),
            ),
          );
        }

        return _HomeScreen(
          authRepository: widget.authRepository,
          householdMembership: householdMembership,
          user: widget.user,
        );
      },
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.authRepository,
    required this.householdMembership,
    required this.user,
  });

  final AuthRepository authRepository;
  final HouseholdMembership householdMembership;
  final User user;

  @override
  Widget build(BuildContext context) {
    final email = user.email;
    final household = householdMembership.household;
    final membership = householdMembership.membership;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haushaltsbuch'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Angemeldet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (email != null) ...[
                const SizedBox(height: 12),
                Text('E-Mail: $email'),
              ],
              const SizedBox(height: 12),
              Text('Household-ID: ${household.id}'),
              const SizedBox(height: 12),
              Text('Rolle: ${membership.role}'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: authRepository.signOut,
                child: const Text('Abmelden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

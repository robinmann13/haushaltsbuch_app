import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haushaltsbuch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthFirestoreTestScreen(),
    );
  }
}

class AuthFirestoreTestScreen extends StatelessWidget {
  const AuthFirestoreTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return const AuthTestView();
        }

        return FirestoreBootstrapView(user: user);
      },
    );
  }
}

class AuthTestView extends StatefulWidget {
  const AuthTestView({super.key});

  @override
  State<AuthTestView> createState() => _AuthTestViewState();
}

class _AuthTestViewState extends State<AuthTestView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _status = '';
  bool _loading = false;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        _status = 'Registriert: ${credential.user?.uid}';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _status = 'Fehler: ${e.code}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() {
        _status = 'Eingeloggt: ${credential.user?.uid}';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _status = 'Fehler: ${e.code}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-Mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Passwort'),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Text('Registrieren'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}

class FirestoreBootstrapView extends StatefulWidget {
  final User user;

  const FirestoreBootstrapView({
    super.key,
    required this.user,
  });

  @override
  State<FirestoreBootstrapView> createState() => _FirestoreBootstrapViewState();
}

class _FirestoreBootstrapViewState extends State<FirestoreBootstrapView> {
  String _status = '';
  bool _loading = false;

  Future<void> _createTestHousehold() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final uid = widget.user.uid;

      final membershipRef = firestore.collection('user_memberships').doc(uid);
      final membershipSnap = await membershipRef.get();

      if (membershipSnap.exists) {
        setState(() {
          _status = 'Für diesen User existiert bereits eine Membership.';
        });
        return;
      }

      final householdRef = firestore.collection('households').doc();
      final now = Timestamp.now();

      await householdRef.set({
        'name': 'Mein Test-Haushalt',
        'createdAt': now,
        'aktiv': true,
      });

      await membershipRef.set({
        'householdId': householdRef.id,
        'aktiv': true,
        'createdAt': now,
        'updatedAt': now,
      });

      await householdRef.collection('users').doc(uid).set({
        'name': widget.user.email ?? 'Unbekannt',
        'email': widget.user.email ?? '',
        'aktiv': true,
      });

      setState(() {
        _status =
            'Test-Haushalt angelegt. householdId: ${householdRef.id}';
      });
    } catch (e) {
      setState(() {
        _status = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadMembership() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_memberships')
          .doc(widget.user.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _status = 'Keine Membership gefunden.';
        });
        return;
      }

      final data = doc.data()!;
      setState(() {
        _status =
            'Membership geladen: householdId=${data['householdId']}, aktiv=${data['aktiv']}';
      });
    } catch (e) {
      setState(() {
        _status = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Bootstrap Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Eingeloggt als: ${widget.user.email}'),
            const SizedBox(height: 8),
            Text('UID: ${widget.user.uid}'),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createTestHousehold,
                  child: const Text('Test-Haushalt anlegen'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadMembership,
                  child: const Text('Membership laden'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  child: const Text('Logout'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
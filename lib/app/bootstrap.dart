import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../firebase_options.dart';
import '../services/local/app_database.dart';
import '../services/local/membership_local_service.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await AppDatabase.instance.database;
    debugPrint('SQLite-Datenbank erfolgreich geöffnet.');

    await _runMembershipLocalTest();
  } catch (e, st) {
    debugPrint('Fehler beim Öffnen der SQLite-Datenbank: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(const App());
}

Future<void> _runMembershipLocalTest() async {
  final membershipService = MembershipLocalService();
  final now = DateTime.now().toUtc().toIso8601String();

  debugPrint('--- TEST START: Membership Local Service ---');

  await membershipService.clearAllMemberships();

  await membershipService.saveMembership(
    userId: 'test_user_1',
    householdId: 'test_household_1',
    aktiv: true,
    createdAt: now,
    updatedAt: now,
  );

  final savedMembership =
      await membershipService.getMembershipByUserId('test_user_1');

  debugPrint('Gespeicherte Membership: $savedMembership');

  await membershipService.updateMembership(
    userId: 'test_user_1',
    householdId: 'test_household_2',
    aktiv: false,
    updatedAt: DateTime.now().toUtc().toIso8601String(),
  );

  final updatedMembership =
      await membershipService.getMembershipByUserId('test_user_1');

  debugPrint('Aktualisierte Membership: $updatedMembership');

  debugPrint('--- TEST ENDE: Membership Local Service ---');
}
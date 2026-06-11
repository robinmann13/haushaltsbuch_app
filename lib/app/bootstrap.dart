import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../firebase_options.dart';
import '../services/local/app_database.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await AppDatabase.instance.database;
    debugPrint('SQLite-Datenbank erfolgreich geöffnet.');
  } catch (e, st) {
    debugPrint('Fehler beim Öffnen der SQLite-Datenbank: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(const App());
}

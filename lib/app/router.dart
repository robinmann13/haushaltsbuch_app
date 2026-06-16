import 'package:go_router/go_router.dart';

import '../screens/auth/auth_gate.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
  ],
);

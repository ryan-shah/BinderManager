import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/binders',
  routes: [
    // TODO: wire up onboarding redirect when corpus not downloaded
    ShellRoute(
      builder: (context, state, child) {
        // App shell placeholder — replaced in Phase 1 Agent B
        return child;
      },
      routes: [
        GoRoute(path: '/binders', builder: (_, _) => const _Stub('Binders')),
        GoRoute(path: '/collection', builder: (_, _) => const _Stub('Collection')),
        GoRoute(path: '/decks', builder: (_, _) => const _Stub('Decks')),
        GoRoute(path: '/settings', builder: (_, _) => const _Stub('Settings')),
      ],
    ),
  ],
);

class _Stub extends StatelessWidget {
  const _Stub(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(label, style: const TextStyle(fontSize: 24))),
    );
  }
}

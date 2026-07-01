import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/binders_list/binders_list_screen.dart';
import '../features/collection_search/collection_search_screen.dart';
import '../features/decks/decks_list_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../shared/providers/corpus_provider.dart';

/// Paths that live inside the shell (order must match AppShell._destinations).
const _shellPaths = ['/binders', '/collection', '/decks', '/settings'];

/// Build the app-level [GoRouter].
///
/// Accepts a [WidgetRef] so it can read the [corpusReadyProvider] for redirect
/// logic. The router is exposed via [appRouterProvider] for use with Riverpod.
GoRouter buildRouter(Ref ref) {
  final corpusReady = ref.watch(corpusReadyProvider);

  return GoRouter(
    initialLocation: '/binders',
    redirect: (context, state) {
      final goingToOnboarding = state.matchedLocation == '/onboarding';

      if (!corpusReady && !goingToOnboarding) {
        return '/onboarding';
      }
      if (corpusReady && goingToOnboarding) {
        return '/binders';
      }
      return null;
    },
    routes: [
      // Onboarding — full-screen, outside the shell
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),

      // Main app shell
      ShellRoute(
        builder: (context, state, child) {
          final index = _indexFromLocation(state.matchedLocation);
          return AppShell(currentIndex: index, child: child);
        },
        routes: [
          GoRoute(
            path: '/binders',
            builder: (_, _) => const BindersListScreen(),
          ),
          GoRoute(
            path: '/collection',
            builder: (_, _) => const CollectionSearchScreen(),
          ),
          GoRoute(
            path: '/decks',
            builder: (_, _) => const DecksListScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Map the current location to the shell nav index (defaults to 0).
int _indexFromLocation(String location) {
  final index = _shellPaths.indexOf(location);
  return index >= 0 ? index : 0;
}

/// Riverpod provider that creates and caches the [GoRouter].
final appRouterProvider = Provider<GoRouter>((ref) => buildRouter(ref));

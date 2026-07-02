import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/binders_list/binders_list_screen.dart';
import '../features/collection_import/collection_import_screen.dart';
import '../features/collection_search/collection_search_screen.dart';
import '../features/decklist_import/decklist_import_screen.dart';
import '../features/decks/deck_detail_screen.dart';
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
  final corpusReadyAsync = ref.watch(corpusReadyProvider);
  final corpusReady = corpusReadyAsync.valueOrNull ?? false;

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
            routes: [
              GoRoute(
                path: 'import',
                builder: (_, _) => const CollectionImportScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/decks',
            builder: (_, _) => const DecksListScreen(),
            routes: [
              // 'import' must precede ':id' or it would match as a deck id.
              GoRoute(
                path: 'import',
                builder: (_, _) => const DecklistImportScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    DeckDetailScreen(deckId: state.pathParameters['id']!),
              ),
            ],
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
///
/// Prefix-matches so sub-routes (e.g. `/decks/import`, `/decks/:id`)
/// highlight their parent destination.
int _indexFromLocation(String location) {
  final index = _shellPaths.indexWhere(
    (p) => location == p || location.startsWith('$p/'),
  );
  return index >= 0 ? index : 0;
}

/// Riverpod provider that creates and caches the [GoRouter].
final appRouterProvider = Provider<GoRouter>((ref) => buildRouter(ref));

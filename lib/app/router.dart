import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/binder_editor/binder_editor_screen.dart';
import '../features/binders_list/binders_list_screen.dart';
import '../features/change_review/change_review_screen.dart';
import '../features/collection_import/collection_import_screen.dart';
import '../features/collection_search/collection_search_screen.dart';
import '../features/decklist_import/decklist_import_screen.dart';
import '../features/decks/deck_detail_screen.dart';
import '../features/decks/decks_list_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../shared/providers/corpus_provider.dart';
import '../shared/widgets/pending_changes_banner.dart';

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
          return AppShell(
            currentIndex: index,
            child: PendingChangesScope(
              location: state.matchedLocation,
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/binders',
            builder: (_, _) => const BindersListScreen(),
            routes: [
              // 'new' must precede ':id/edit' or it would match as an id.
              GoRoute(
                path: 'new',
                builder: (_, _) => const BinderEditorScreen(),
              ),
              // Bare '/binders/:id' is reserved for the Phase 5
              // flip-through view (§9).
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => BinderEditorScreen(
                  binderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          // The universal D7 gate — every staged diff routes here (§10).
          GoRoute(
            path: '/changes',
            builder: (_, _) => const ChangeReviewScreen(),
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

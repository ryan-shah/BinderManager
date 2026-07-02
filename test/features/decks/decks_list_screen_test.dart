import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/core/decks/deck_repository.dart';
import 'package:binder_manager/features/decks/decks_list_screen.dart';
import 'package:binder_manager/shared/providers/deck_providers.dart';

void main() {
  Future<void> pumpList(
    WidgetTester tester, {
    required List<DeckListItem> decks,
    GoRouter? router,
  }) async {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/decks',
          routes: [
            GoRoute(
              path: '/decks',
              builder: (_, _) => const DecksListScreen(),
              routes: [
                GoRoute(
                  path: 'import',
                  builder: (_, _) => const Text('Import Screen'),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      Text('Detail ${state.pathParameters['id']}'),
                ),
              ],
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          decksListProvider.overrideWith((_) => Stream.value(decks)),
        ],
        child: MaterialApp.router(
          routerConfig: effectiveRouter,
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const burn = DeckListItem(
    id: 'deck-1',
    name: 'Burn',
    format: 'modern',
    isAssembled: true,
    isShared: false,
    cardCount: 60,
    unownedCount: 0,
  );
  const cube = DeckListItem(
    id: 'deck-2',
    name: 'Cube Draft',
    isAssembled: false,
    isShared: true,
    cardCount: 360,
    unownedCount: 12,
  );

  group('DecksListScreen', () {
    testWidgets('shows the empty state with a CTA', (tester) async {
      await pumpList(tester, decks: const []);

      expect(find.text('No decks yet'), findsOneWidget);
      expect(
        find.text('Import a decklist to start reserving cards.'),
        findsOneWidget,
      );
      expect(find.text('Import a deck'), findsOneWidget);
    });

    testWidgets('renders deck rows with metadata and badges', (tester) async {
      await pumpList(tester, decks: const [burn, cube]);

      expect(find.text('Burn'), findsOneWidget);
      expect(find.text('modern · 60 cards'), findsOneWidget);
      expect(find.text('Cube Draft'), findsOneWidget);
      expect(find.text('360 cards'), findsOneWidget);

      // Badges: Burn is assembled, Cube is shared with unowned cards.
      expect(find.text('ASSEMBLED'), findsOneWidget);
      expect(find.text('SHARED'), findsOneWidget);
      expect(find.text('12 unowned'), findsOneWidget);
    });

    testWidgets('"Import deck" navigates to the import route',
        (tester) async {
      await pumpList(tester, decks: const []);

      await tester.tap(find.text('Import deck'));
      await tester.pumpAndSettle();

      expect(find.text('Import Screen'), findsOneWidget);
    });

    testWidgets('empty-state CTA navigates to the import route',
        (tester) async {
      await pumpList(tester, decks: const []);

      await tester.tap(find.text('Import a deck'));
      await tester.pumpAndSettle();

      expect(find.text('Import Screen'), findsOneWidget);
    });

    testWidgets('tapping a row opens the deck detail route', (tester) async {
      await pumpList(tester, decks: const [burn, cube]);

      await tester.tap(find.text('Cube Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Detail deck-2'), findsOneWidget);
    });
  });
}

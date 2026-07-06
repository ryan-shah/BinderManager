import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/core/binders/binder_repository.dart';
import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/models/ordering.dart';
import 'package:binder_manager/features/binder_editor/binder_editor_screen.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';
import 'package:binder_manager/shared/providers/user_database_provider.dart';

import '../../helpers/corpus_seed.dart';

void main() {
  late CorpusDatabase corpus;
  late UserDatabase userDb;
  late BinderRepository repository;

  setUp(() {
    corpus = CorpusDatabase(NativeDatabase.memory());
    userDb = UserDatabase(NativeDatabase.memory());
    repository = BinderRepository(userDb);
  });

  tearDown(() async {
    await corpus.close();
    await userDb.close();
  });

  Future<void> pumpEditor(WidgetTester tester, {String? binderId}) async {
    // Tall surface so every form section (ORGANIZATION, MODE, …) is built —
    // ListView skips off-screen children in the default 800×600 viewport.
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation:
          binderId == null ? '/binders/new' : '/binders/$binderId/edit',
      routes: [
        GoRoute(
          path: '/binders',
          builder: (_, _) => const Text('Binders List'),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) => const BinderEditorScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (_, state) => BinderEditorScreen(
                binderId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          corpusDatabaseProvider.overrideWithValue(corpus),
          userDatabaseProvider.overrideWithValue(userDb),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('new binder', () {
    testWidgets('renders the form sections with defaults', (tester) async {
      await pumpEditor(tester);

      expect(find.text('New binder'), findsOneWidget);
      expect(find.text('TYPE'), findsOneWidget);
      expect(find.text('CONTENTS'), findsOneWidget);
      expect(find.text('ORGANIZATION'), findsOneWidget);
      expect(find.text('MODE'), findsOneWidget);
      // Defaults: 3×3, 10 pages, double-sided.
      expect(find.text('Capacity: 180 pockets'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Create binder'),
          findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('capacity readout follows layout, pages, and sides',
        (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.text('4×4'));
      await tester.pump();
      expect(find.text('Capacity: 320 pockets'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
      expect(find.text('Capacity: 288 pockets'), findsOneWidget);

      await tester.tap(find.text('Double-sided pages'));
      await tester.pump();
      expect(find.text('Capacity: 144 pockets'), findsOneWidget);

      // Flush the debounced preview timer before the test ends.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    });

    testWidgets('validates name and query before saving', (tester) async {
      await pumpEditor(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create binder'));
      await tester.pump();

      expect(find.text('Give the binder a name.'), findsOneWidget);
      // Shown under the query field AND mirrored in the preview panel.
      expect(find.text('Define the contents query.'), findsWidgets);
      expect(await repository.listBinders(), isEmpty);
    });

    testWidgets('saves a valid binder and returns to the list',
        (tester) async {
      await pumpEditor(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'e.g. Premium trade binder'),
          'My binder');
      await tester.enterText(
          find.widgetWithText(TextField, 'e.g. usd>=5 -t:land'), 'usd>=5');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create binder'));
      await tester.pumpAndSettle();

      expect(find.text('Binders List'), findsOneWidget);
      final binders = await repository.listBinders();
      expect(binders, hasLength(1));
      expect(binders.single.name, 'My binder');
      expect(binders.single.query, 'usd>=5');
      expect(binders.single.sortBy, BinderAxis.price);
      expect(binders.single.sortDir, SortDirection.desc);
    });

    testWidgets('rejects a query that does not parse', (tester) async {
      await pumpEditor(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'e.g. Premium trade binder'),
          'My binder');
      await tester.enterText(
          find.widgetWithText(TextField, 'e.g. usd>=5 -t:land'), '(((');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create binder'));
      await tester.pumpAndSettle();

      expect(await repository.listBinders(), isEmpty);
      // Still on the editor, with an error under the query field.
      expect(find.text('New binder'), findsOneWidget);
    });

    testWidgets('live preview reports matches, fits, and overflow',
        (tester) async {
      await seedCorpusCards(corpus, [
        seedCard(scryfallId: 'a', name: 'Card A', priceUsd: 10),
        seedCard(scryfallId: 'b', name: 'Card B', priceUsd: 20),
      ]);
      await userDb.into(userDb.stacks).insert(StacksCompanion.insert(
            id: 's1',
            scryfallId: 'a',
            finish: Finish.nonfoil,
            quantity: 3,
            provenance: 'test',
            createdAt: DateTime.utc(2026, 7, 1),
            updatedAt: DateTime.utc(2026, 7, 1),
          ));

      await pumpEditor(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'e.g. usd>=5 -t:land'), 'usd>=5');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // 2 corpus printings match; only the owned stack is eligible.
      expect(find.text('2 printings'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // eligible stacks line
      expect(find.text('Overflow: none'), findsOneWidget);
    });
  });

  group('edit binder', () {
    testWidgets('loads the existing definition and saves changes',
        (tester) async {
      final id = await repository.createBinder(
        name: 'Premium',
        query: 'usd>=20',
        layoutRows: 4,
        layoutCols: 4,
        pageCount: 12,
        doubleSided: false,
        groupBy: BinderAxis.color,
        sortBy: BinderAxis.name,
        sortDir: SortDirection.asc,
      );

      await pumpEditor(tester, binderId: id);

      expect(find.text('Edit binder'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('usd>=20'), findsOneWidget);
      expect(find.text('Capacity: 192 pockets'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Premium'), 'Premium v2');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Binders List'), findsOneWidget);
      final binder = await repository.getBinder(id);
      expect(binder!.name, 'Premium v2');
      expect(binder.groupBy, BinderAxis.color);
    });

    testWidgets('delete removes the binder after confirmation',
        (tester) async {
      final id = await repository.createBinder(
        name: 'Premium',
        query: 'usd>=20',
        layoutRows: 3,
        layoutCols: 3,
        pageCount: 10,
        doubleSided: true,
      );

      await pumpEditor(tester, binderId: id);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Binders List'), findsOneWidget);
      expect(await repository.getBinder(id), isNull);
    });

    testWidgets('shows a not-found state for a missing id', (tester) async {
      await pumpEditor(tester, binderId: 'nope');
      expect(find.text('Binder not found.'), findsOneWidget);
    });
  });
}

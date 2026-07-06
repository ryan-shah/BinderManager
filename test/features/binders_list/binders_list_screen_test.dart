import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/core/binders/binder_repository.dart';
import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/features/binders_list/binders_list_screen.dart';
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

  /// Drift closes its query streams with zero-duration timers when the
  /// ProviderScope is disposed, and testWidgets' pending-timer check runs
  /// before anything would pump them — unmount and flush explicitly at the
  /// end of every test that leaves live drift stream subscriptions.
  Future<void> unmountAndFlush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Nonzero duration: pump() without one does not advance fake time, so
    // the zero-duration close timers would stay pending.
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> pumpList(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/binders',
      routes: [
        GoRoute(
          path: '/binders',
          builder: (_, _) => const BindersListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) => const Text('New Binder Screen'),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (_, state) =>
                  Text('Edit ${state.pathParameters['id']}'),
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

  testWidgets('shows the empty-state CTA when no binders exist',
      (tester) async {
    await pumpList(tester);

    expect(find.text('No binders yet'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'New binder'),
        findsNWidgets(2)); // header button + empty-state CTA

    await unmountAndFlush(tester);
  });

  testWidgets('renders binder rows with meta, query, and badges',
      (tester) async {
    await repository.createBinder(
      name: 'Premium',
      query: 'usd>=20',
      layoutRows: 3,
      layoutCols: 3,
      pageCount: 20,
      doubleSided: true,
    );
    await repository.createBinder(
      name: 'Showcase',
      query: 'is:showcase',
      layoutRows: 4,
      layoutCols: 4,
      pageCount: 10,
      doubleSided: false,
      isVirtual: true,
    );

    await pumpList(tester);

    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('3×3 · 20 pages · double-sided · 360 pockets'),
        findsOneWidget);
    expect(find.text('usd>=20'), findsOneWidget);
    expect(find.text('Showcase'), findsOneWidget);
    expect(find.text('4×4 · 10 pages · single-sided · 160 pockets'),
        findsOneWidget);
    expect(find.text('VIRTUAL'), findsOneWidget);
    // Empty collection: both binders show 0 used.
    expect(find.text('0 / 360'), findsOneWidget);
    expect(find.text('0 / 160'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('shows the overflow badge when stacks do not fit',
      (tester) async {
    await seedCorpusCards(corpus, [
      seedCard(scryfallId: 'a', name: 'Card A', priceUsd: 10),
      seedCard(scryfallId: 'b', name: 'Card B', priceUsd: 20),
      seedCard(scryfallId: 'c', name: 'Card C', priceUsd: 30),
    ]);
    for (final id in ['a', 'b', 'c']) {
      await userDb.into(userDb.stacks).insert(StacksCompanion.insert(
            id: 'stack-$id',
            scryfallId: id,
            finish: Finish.nonfoil,
            quantity: 1,
            provenance: 'test',
            createdAt: DateTime.utc(2026, 7, 1),
            updatedAt: DateTime.utc(2026, 7, 1),
          ));
    }
    // Capacity 2 → one of the three stacks overflows.
    await repository.createBinder(
      name: 'Tiny',
      query: 'usd>=0',
      layoutRows: 1,
      layoutCols: 2,
      pageCount: 1,
      doubleSided: false,
    );

    await pumpList(tester);

    expect(find.text("+1 didn't fit"), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    await unmountAndFlush(tester);
  });

  testWidgets('header button navigates to the editor; row tap opens edit',
      (tester) async {
    await repository.createBinder(
      name: 'Premium',
      query: 'usd>=20',
      layoutRows: 3,
      layoutCols: 3,
      pageCount: 20,
      doubleSided: true,
    );
    await pumpList(tester);

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Edit '), findsOneWidget);

    await unmountAndFlush(tester);
  });
}

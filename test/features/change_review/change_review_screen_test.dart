import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/state/change_staging_service.dart';
import 'package:binder_manager/features/change_review/change_review_screen.dart';
import 'package:binder_manager/shared/providers/change_staging_provider.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';
import 'package:binder_manager/shared/providers/user_database_provider.dart';
import 'package:binder_manager/shared/widgets/commit_rollback_bar.dart';

/// Fake staging service; mirrors every public member of the real one.
class FakeChangeStagingService extends StateNotifier<StagedDiff?>
    implements ChangeStagingService {
  FakeChangeStagingService(super.initial);

  int commitCalls = 0;
  int rollbackCalls = 0;
  bool failCommit = false;

  @override
  StagedDiff? get staged => state;

  @override
  Future<void> stage({
    required ChangeTrigger trigger,
    required List<PlannedPlacement> planned,
    List<OverflowEntry> overflow = const [],
  }) async {}

  @override
  Future<void> commit() async {
    commitCalls++;
    if (failCommit) throw StateError('boom');
    state = null;
  }

  @override
  void discardStagedDiff() {
    state = null;
  }

  @override
  Future<bool> restoreLatestSnapshot() async {
    state = null;
    return true;
  }

  @override
  Future<void> rollback() async {
    rollbackCalls++;
    state = null;
  }
}

void main() {
  final fixedNow = DateTime.utc(2026, 7, 4);

  late UserDatabase userDb;
  late CorpusDatabase corpusDb;
  late FakeChangeStagingService fake;

  setUp(() {
    userDb = UserDatabase(NativeDatabase.memory());
    corpusDb = CorpusDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await userDb.close();
    await corpusDb.close();
  });

  Future<void> insertBinder({
    String id = 'binder-a',
    String name = 'Premium trades',
  }) {
    return userDb.into(userDb.binders).insert(BindersCompanion.insert(
          id: id,
          name: name,
          query: 'unused:true',
          priorityIndex: 0,
          layoutRows: 3,
          layoutCols: 3,
          pageCount: 20,
          createdAt: fixedNow,
          updatedAt: fixedNow,
        ));
  }

  Future<void> insertCard({required String id, required String name}) {
    return corpusDb.into(corpusDb.cards).insert(CardsCompanion.insert(
          scryfallId: id,
          oracleId: 'oracle-$id',
          name: name,
          cmc: 1,
          typeLine: 'Creature — Monkey Pirate',
          colorIdentity: 'R',
          setCode: 'mh2',
          setName: 'Modern Horizons 2',
          collectorNumber: '138',
          rarity: 'mythic',
          finishes: 'nonfoil,foil',
          layout: 'normal',
          releasedAt: '2021-06-18',
        ));
  }

  StagedDiff makeDiff({
    List<BinderDiffEntry>? entries,
    List<OverflowEntry> overflow = const [],
    ChangeTrigger trigger = ChangeTrigger.ruleEdit,
  }) {
    return StagedDiff(
      trigger: trigger,
      entries: entries ??
          [
            const BinderDiffEntry(
              type: DiffType.move,
              binderId: 'binder-a',
              identity: CardIdentity('ragavan-id', Finish.nonfoil),
              quantity: 1,
              from: BinderPosition(page: 1, side: PageSide.front, pocket: 2),
              to: BinderPosition(page: 3, side: PageSide.back, pocket: 5),
            ),
            const BinderDiffEntry(
              type: DiffType.add,
              binderId: 'binder-a',
              identity: CardIdentity('bolt-id', Finish.foil),
              quantity: 4,
              to: BinderPosition(page: 4, side: PageSide.front, pocket: 1),
            ),
            const BinderDiffEntry(
              type: DiffType.remove,
              binderId: 'binder-b',
              identity: CardIdentity('opt-id', Finish.nonfoil),
              quantity: 2,
              from: BinderPosition(page: 2, side: PageSide.front, pocket: 1),
            ),
          ],
      overflowChanges: overflow,
      createdAt: fixedNow,
    );
  }

  Widget buildScreen(StagedDiff? initial) {
    fake = FakeChangeStagingService(initial);
    return ProviderScope(
      overrides: [
        userDatabaseProvider.overrideWithValue(userDb),
        corpusDatabaseProvider.overrideWithValue(corpusDb),
        changeStagingProvider.overrideWith((ref) => fake),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const ChangeReviewScreen(),
      ),
    );
  }

  group('empty state', () {
    testWidgets('shows "No pending changes." when nothing is staged',
        (tester) async {
      await tester.pumpWidget(buildScreen(null));

      expect(find.text('No pending changes.'), findsOneWidget);
      expect(find.byType(CommitRollbackBar), findsNothing);
    });
  });

  group('pending diff', () {
    testWidgets('shows trigger, summary counts, and the action bar',
        (tester) async {
      await tester.pumpWidget(buildScreen(makeDiff()));
      await tester.pumpAndSettle();

      expect(find.text('Review changes'), findsOneWidget);
      expect(find.text('Rule edit'), findsOneWidget);
      // Header + bar both show the summary.
      expect(find.text('1 add · 1 remove · 1 move'), findsNWidgets(2));
      expect(find.byType(CommitRollbackBar), findsOneWidget);
    });

    testWidgets('groups rows by binder and resolves names for instructions',
        (tester) async {
      await insertBinder(id: 'binder-a', name: 'Premium trades');
      await insertBinder(id: 'binder-b', name: 'Bulk binder');
      await insertCard(id: 'ragavan-id', name: 'Ragavan, Nimble Pilferer');
      await insertCard(id: 'bolt-id', name: 'Lightning Bolt');

      await tester.pumpWidget(buildScreen(makeDiff()));
      await tester.pumpAndSettle();

      // Binder group headers.
      expect(find.text('PREMIUM TRADES'), findsOneWidget);
      expect(find.text('BULK BINDER'), findsOneWidget);

      // Exact D7 location instructions with resolved card names.
      expect(
        find.text('Move Ragavan, Nimble Pilferer → page 3, back, pocket 5'),
        findsOneWidget,
      );
      expect(
        find.text('Add Lightning Bolt → page 4, front, pocket 1'),
        findsOneWidget,
      );
      // opt-id is not in the corpus: falls back to the scryfallId.
      expect(
        find.text('Pull opt-id from page 2, front, pocket 1'),
        findsOneWidget,
      );

      // Type chips and quantities.
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('REMOVE'), findsOneWidget);
      expect(find.text('MOVE'), findsOneWidget);
      expect(find.text('×4'), findsOneWidget);
    });

    testWidgets('shows the overflow section when overflow is non-empty',
        (tester) async {
      await insertCard(id: 'urza-id', name: 'Urza, Lord High Artificer');

      await tester.pumpWidget(buildScreen(makeDiff(
        overflow: const [
          OverflowEntry(
            binderId: 'binder-a',
            identity: CardIdentity('urza-id', Finish.foil),
            quantity: 2,
          ),
          OverflowEntry(
            binderId: 'binder-a',
            identity: CardIdentity('missing-id', Finish.nonfoil),
            quantity: 1,
          ),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.text("2 matched but didn't fit"), findsOneWidget);
      expect(
        find.textContaining('Urza, Lord High Artificer ×2'),
        findsOneWidget,
      );
    });

    testWidgets('hides the overflow section when overflow is empty',
        (tester) async {
      await tester.pumpWidget(buildScreen(makeDiff()));
      await tester.pumpAndSettle();

      expect(find.text('OVERFLOW'), findsNothing);
    });
  });

  group('commit', () {
    testWidgets('commits via the notifier and shows the done state',
        (tester) async {
      await tester.pumpWidget(buildScreen(makeDiff()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Commit'));
      await tester.pumpAndSettle();

      expect(fake.commitCalls, 1);
      expect(find.text('Committed'), findsOneWidget);
      expect(find.text('No pending changes.'), findsNothing);
      expect(find.byType(CommitRollbackBar), findsNothing);
    });

    testWidgets('surfaces a commit failure and keeps the diff', (tester) async {
      await tester.pumpWidget(buildScreen(makeDiff()));
      await tester.pumpAndSettle();
      fake.failCommit = true;

      await tester.tap(find.text('Commit'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Commit failed'), findsOneWidget);
      expect(find.byType(CommitRollbackBar), findsOneWidget);
    });
  });

  group('roll back', () {
    testWidgets('rolls back via the notifier and confirms', (tester) async {
      await tester.pumpWidget(buildScreen(makeDiff()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roll back'));
      await tester.pumpAndSettle();

      expect(fake.rollbackCalls, 1);
      expect(
        find.text('Rolled back to the last committed state'),
        findsOneWidget,
      );
      expect(find.text('No pending changes.'), findsOneWidget);
    });
  });
}

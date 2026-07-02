import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/query/query_engine.dart';
import 'package:binder_manager/shared/providers/search_provider.dart';

void main() {
  late CorpusDatabase corpus;
  late UserDatabase userDb;
  late SearchNotifier notifier;

  final now = DateTime.utc(2026, 7, 2);

  setUp(() async {
    corpus = CorpusDatabase(NativeDatabase.memory());
    userDb = UserDatabase(NativeDatabase.memory());
    notifier = SearchNotifier(QueryEngine(corpus, userDb: userDb));

    await corpus.into(corpus.cards).insert(CardsCompanion.insert(
          scryfallId: 'bolt-1',
          oracleId: 'oracle-1',
          name: 'Lightning Bolt',
          cmc: 1,
          typeLine: 'Instant',
          colorIdentity: 'R',
          setCode: 'lea',
          setName: 'Alpha',
          collectorNumber: '1',
          rarity: 'common',
          finishes: 'nonfoil',
          layout: 'normal',
          releasedAt: '1993-08-05',
        ));
  });

  tearDown(() async {
    await corpus.close();
    await userDb.close();
    notifier.dispose();
  });

  group('SearchNotifier.refresh', () {
    test('re-runs the current query after the collection changes', () async {
      await notifier.search('have:true');
      expect(notifier.state.results, isEmpty);

      // Simulate a collection import landing after the search.
      await userDb.into(userDb.stacks).insert(StacksCompanion.insert(
            id: 'stack-1',
            scryfallId: 'bolt-1',
            finish: Finish.nonfoil,
            quantity: 4,
            provenance: 'manabox',
            createdAt: now,
            updatedAt: now,
          ));

      // Same-query searches are guarded — results stay stale.
      await notifier.search('have:true');
      expect(notifier.state.results, isEmpty);

      // refresh() bypasses the guard and sees the new stack.
      await notifier.refresh();
      expect(notifier.state.results.map((c) => c.name), ['Lightning Bolt']);
    });

    test('is a no-op with no current query', () async {
      await notifier.refresh();
      expect(notifier.state.results, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });
  });
}

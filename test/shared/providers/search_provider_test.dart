import 'package:drift/drift.dart' show Value;
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

  group('SearchNotifier.setSort', () {
    setUp(() async {
      // A second card, pricier than Bolt, so sort order is observable.
      await corpus.into(corpus.cards).insert(CardsCompanion.insert(
            scryfallId: 'goyf-1',
            oracleId: 'oracle-2',
            name: 'Tarmogoyf',
            cmc: 2,
            typeLine: 'Creature',
            colorIdentity: 'G',
            setCode: 'mh2',
            setName: 'Modern Horizons 2',
            collectorNumber: '2',
            rarity: 'mythic',
            finishes: 'nonfoil',
            layout: 'normal',
            releasedAt: '2021-06-18',
            priceUsd: const Value(15.0),
          ));
      await (corpus.update(corpus.cards)
            ..where((c) => c.scryfallId.equals('bolt-1')))
          .write(const CardsCompanion(priceUsd: Value(2.5)));
    });

    test('re-runs the query so the whole result set is re-ordered', () async {
      await notifier.search('usd>0');
      // Default sort is name asc.
      expect(notifier.state.results.map((c) => c.name).toList(),
          ['Lightning Bolt', 'Tarmogoyf']);

      await notifier.setSort(SearchSort.priceDesc);
      expect(notifier.state.sort, SearchSort.priceDesc);
      expect(notifier.state.results.map((c) => c.name).toList(),
          ['Tarmogoyf', 'Lightning Bolt']);
    });

    test('same sort is a no-op', () async {
      await notifier.search('usd>0');
      final before = notifier.state.results;
      await notifier.setSort(notifier.state.sort);
      expect(identical(notifier.state.results, before), isTrue);
    });
  });
}

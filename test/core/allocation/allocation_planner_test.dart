import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/allocation/allocation_planner.dart';
import 'package:binder_manager/core/binders/binder_repository.dart';
import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/models/ordering.dart';
import 'package:binder_manager/core/query/query_engine.dart';

final _t = DateTime.utc(2026, 7, 1);

CardsCompanion _makeCard({
  required String scryfallId,
  String name = 'Test Card',
  String typeLine = 'Creature',
  String colorIdentity = 'R',
  String setCode = 'tst',
  String rarity = 'common',
  String finishes = 'nonfoil,foil',
  double? priceUsd,
  double? priceUsdFoil,
}) {
  return CardsCompanion(
    scryfallId: Value(scryfallId),
    oracleId: Value('oracle-$scryfallId'),
    name: Value(name),
    cmc: const Value(1.0),
    typeLine: Value(typeLine),
    colorIdentity: Value(colorIdentity),
    setCode: Value(setCode),
    setName: Value('Set $setCode'),
    collectorNumber: const Value('1'),
    rarity: Value(rarity),
    finishes: Value(finishes),
    priceUsd: Value(priceUsd),
    priceUsdFoil: Value(priceUsdFoil),
    isFullart: const Value(false),
    isPromo: const Value(false),
    layout: const Value('normal'),
    releasedAt: const Value('2023-01-01'),
  );
}

StacksCompanion _makeStack({
  required String id,
  required String scryfallId,
  Finish finish = Finish.nonfoil,
  int quantity = 1,
}) {
  return StacksCompanion.insert(
    id: id,
    scryfallId: scryfallId,
    finish: finish,
    quantity: quantity,
    provenance: 'test',
    createdAt: _t,
    updatedAt: _t,
  );
}

void main() {
  late CorpusDatabase corpus;
  late UserDatabase userDb;
  late QueryEngine engine;
  late BinderRepository repository;
  late AllocationPlanner planner;

  setUp(() async {
    corpus = CorpusDatabase(NativeDatabase.memory());
    userDb = UserDatabase(NativeDatabase.memory());
    engine = QueryEngine(corpus, userDb: userDb);
    repository = BinderRepository(userDb, now: () => _t);
    planner = AllocationPlanner(
      userDb: userDb,
      corpus: corpus,
      engine: engine,
    );

    await corpus.batch((b) {
      b.insertAll(corpus.cards, [
        _makeCard(
          scryfallId: 'bolt',
          name: 'Lightning Bolt',
          typeLine: 'Instant',
          priceUsd: 2,
          priceUsdFoil: 20,
        ),
        _makeCard(
          scryfallId: 'goyf',
          name: 'Tarmogoyf',
          priceUsd: 30,
          priceUsdFoil: 90,
        ),
        _makeCard(
          scryfallId: 'walk',
          name: 'Time Walk',
          typeLine: 'Sorcery',
          priceUsd: 900,
        ),
      ]);
    });
  });

  tearDown(() async {
    await corpus.close();
    await userDb.close();
  });

  Future<String> makeBinder({
    String name = 'Binder',
    String query = 'usd>=0',
    int size = 3,
    int pages = 2,
    bool doubleSided = false,
    bool isVirtual = false,
    BinderAxis sortBy = BinderAxis.price,
    SortDirection sortDir = SortDirection.desc,
  }) {
    return repository.createBinder(
      name: name,
      query: query,
      layoutRows: size,
      layoutCols: size,
      pageCount: pages,
      doubleSided: doubleSided,
      sortBy: sortBy,
      sortDir: sortDir,
      isVirtual: isVirtual,
    );
  }

  test('no binders yields the empty result', () async {
    final result = await planner.plan();
    expect(result.allocations, isEmpty);
  });

  test('places only owned idle stacks; unowned matches are ignored',
      () async {
    await userDb.into(userDb.stacks).insert(
          _makeStack(id: 's1', scryfallId: 'bolt', quantity: 4),
        );
    final binderId = await makeBinder(query: 'usd>=0');

    final result = await planner.plan();
    final allocation = result.forBinder(binderId)!;

    // goyf and walk match the query but are unowned.
    expect(allocation.placements, hasLength(1));
    expect(
      allocation.placements.single.identity,
      const CardIdentity('bolt', Finish.nonfoil),
    );
    expect(allocation.placements.single.quantity, 4);
    expect(allocation.overflow, isEmpty);
  });

  test('D13: reservations consume the cheapest finish first', () async {
    await userDb.into(userDb.stacks).insert(
          _makeStack(id: 's1', scryfallId: 'bolt', quantity: 2),
        );
    await userDb.into(userDb.stacks).insert(
          _makeStack(
            id: 's2',
            scryfallId: 'bolt',
            finish: Finish.foil,
            quantity: 1,
          ),
        );
    await userDb.into(userDb.decks).insert(DecksCompanion.insert(
          id: 'd1',
          name: 'Burn',
          isAssembled: const Value(true),
          createdAt: _t,
          updatedAt: _t,
        ));
    await userDb.into(userDb.deckEntries).insert(DeckEntriesCompanion.insert(
          id: 'e1',
          deckId: 'd1',
          scryfallId: 'bolt',
          cardName: 'Lightning Bolt',
          quantity: 2,
          section: DeckSection.main,
          createdAt: _t,
          updatedAt: _t,
        ));

    final binderId = await makeBinder(query: 't:instant');
    final result = await planner.plan();
    final allocation = result.forBinder(binderId)!;

    // Both nonfoil copies ($2) are reserved; the foil ($20) stays idle.
    expect(allocation.placements, hasLength(1));
    expect(
      allocation.placements.single.identity,
      const CardIdentity('bolt', Finish.foil),
    );
    expect(allocation.placements.single.quantity, 1);
  });

  test('priority walk: the higher binder claims a contested stack',
      () async {
    await userDb.into(userDb.stacks).insert(
          _makeStack(id: 's1', scryfallId: 'goyf', quantity: 1),
        );
    final first = await makeBinder(name: 'Premium', query: 'usd>=5');
    final second = await makeBinder(name: 'Bulk', query: 'usd>=0');

    final result = await planner.plan();

    expect(result.forBinder(first)!.placements, hasLength(1));
    expect(result.forBinder(second)!.placements, isEmpty);
  });

  test('virtual binders draw from the full pool without consuming',
      () async {
    await userDb.into(userDb.stacks).insert(
          _makeStack(id: 's1', scryfallId: 'goyf', quantity: 1),
        );
    final virtual = await makeBinder(
      name: 'Showcase',
      query: 'usd>=5',
      isVirtual: true,
    );
    final consuming = await makeBinder(name: 'Trade', query: 'usd>=0');

    final result = await planner.plan();

    expect(result.forBinder(virtual)!.placements, hasLength(1));
    expect(result.forBinder(consuming)!.placements, hasLength(1));
  });

  test('a stored query that no longer parses matches nothing', () async {
    await userDb.into(userDb.stacks).insert(
          _makeStack(id: 's1', scryfallId: 'bolt', quantity: 1),
        );
    final binderId = await makeBinder(query: '(((');

    final result = await planner.plan();
    final allocation = result.forBinder(binderId)!;
    expect(allocation.placements, isEmpty);
    expect(allocation.overflow, isEmpty);
  });

  group('draft override', () {
    test('an id-less draft is appended after the persisted binders',
        () async {
      await userDb.into(userDb.stacks).insert(
            _makeStack(id: 's1', scryfallId: 'goyf', quantity: 1),
          );
      await makeBinder(name: 'Premium', query: 'usd>=5');

      final result = await planner.plan(
        draft: BinderDraft(
          query: 'usd>=0',
          geometry: const BinderGeometry(
            rows: 3,
            cols: 3,
            pageCount: 2,
            doubleSided: false,
          ),
        ),
      );

      // The persisted binder outranks the draft for the contested stack.
      final draftAllocation =
          result.forBinder(BinderDraft.draftBinderId)!;
      expect(draftAllocation.placements, isEmpty);
    });

    test('a draft with an id replaces that binder in place', () async {
      await userDb.into(userDb.stacks).insert(
            _makeStack(id: 's1', scryfallId: 'bolt', quantity: 1),
          );
      final binderId = await makeBinder(query: 't:instant');

      // Draft narrows the query so nothing matches.
      final result = await planner.plan(
        draft: BinderDraft(
          id: binderId,
          query: 't:sorcery',
          geometry: const BinderGeometry(
            rows: 3,
            cols: 3,
            pageCount: 2,
            doubleSided: false,
          ),
        ),
      );

      expect(result.forBinder(binderId)!.placements, isEmpty);
      // Only the replaced binder ran — no duplicate draft entry.
      expect(result.allocations, hasLength(1));
    });
  });

  test('capacity overflow ranks by the binder sort', () async {
    await userDb.batch((b) {
      b.insertAll(userDb.stacks, [
        _makeStack(id: 's1', scryfallId: 'bolt', quantity: 1),
        _makeStack(id: 's2', scryfallId: 'goyf', quantity: 1),
        _makeStack(id: 's3', scryfallId: 'walk', quantity: 1),
      ]);
    });
    // Capacity 2: 1×2 grid, one page, single-sided.
    final binderId = await repository.createBinder(
      name: 'Tiny',
      query: 'usd>=0',
      layoutRows: 1,
      layoutCols: 2,
      pageCount: 1,
      doubleSided: false,
    );

    final result = await planner.plan();
    final allocation = result.forBinder(binderId)!;

    expect(allocation.placements, hasLength(2));
    expect(allocation.overflow, hasLength(1));
    // Price desc: walk ($900) and goyf ($30) placed; bolt ($2) overflows.
    expect(allocation.overflow.single.identity.scryfallId, 'bolt');
  });
}

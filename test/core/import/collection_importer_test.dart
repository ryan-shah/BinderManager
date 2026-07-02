import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/import/collection_importer.dart';
import 'package:binder_manager/core/import/manabox_parser.dart';
import 'package:binder_manager/core/models/card_identity.dart';

const boltId = 'bolt-1';
const helixId = 'helix-1';
const goyfId = 'goyf-1';

/// Builds a corpus [Card] data class (only the name matters here — it feeds
/// [DiffEntry.cardName]).
Card makeCorpusCard({required String scryfallId, required String name}) {
  return Card(
    scryfallId: scryfallId,
    oracleId: 'oracle-000',
    name: name,
    cmc: 1.0,
    typeLine: 'Instant',
    colorIdentity: 'R',
    setCode: 'tst',
    setName: 'Test Set',
    collectorNumber: '1',
    rarity: 'common',
    finishes: 'nonfoil,foil,etched',
    isFullart: false,
    isPromo: false,
    layout: 'normal',
    releasedAt: '2023-01-01',
  );
}

MatchedStackRow makeRow({
  required String scryfallId,
  Finish finish = Finish.nonfoil,
  int quantity = 1,
  String? condition,
  String? language,
  String name = 'Test Card',
}) {
  return MatchedStackRow(
    identity: CardIdentity(scryfallId, finish),
    quantity: quantity,
    condition: condition,
    language: language,
    corpusCard: makeCorpusCard(scryfallId: scryfallId, name: name),
  );
}

void main() {
  late UserDatabase db;
  late CollectionImporter importer;

  final seedTime = DateTime(2026, 1, 1, 12);

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    importer = CollectionImporter(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedStack({
    required String id,
    required String scryfallId,
    Finish finish = Finish.nonfoil,
    int quantity = 1,
    String? condition,
    String? language,
    String provenance = CollectionImporter.provenanceManaBox,
  }) {
    return db.into(db.stacks).insert(StacksCompanion.insert(
          id: id,
          scryfallId: scryfallId,
          finish: finish,
          quantity: quantity,
          condition: Value(condition),
          language: Value(language),
          provenance: provenance,
          createdAt: seedTime,
          updatedAt: seedTime,
        ));
  }

  Future<List<StackRow>> allStacks() => db.select(db.stacks).get();

  Future<StackRow> stackFor(String scryfallId, Finish finish,
      {String provenance = CollectionImporter.provenanceManaBox}) async {
    final rows = await allStacks();
    return rows.singleWhere((s) =>
        s.scryfallId == scryfallId &&
        s.finish == finish &&
        s.provenance == provenance);
  }

  group('CollectionImporter — append', () {
    test('inserts new identities with manabox provenance and fresh ids',
        () async {
      await importer.commit([
        makeRow(scryfallId: boltId, quantity: 4, condition: 'near_mint'),
        makeRow(scryfallId: helixId, finish: Finish.foil, quantity: 1),
      ], ImportMode.append);

      final stacks = await allStacks();
      expect(stacks, hasLength(2));

      final bolt = await stackFor(boltId, Finish.nonfoil);
      expect(bolt.quantity, 4);
      expect(bolt.condition, 'near_mint');
      expect(bolt.provenance, CollectionImporter.provenanceManaBox);
      expect(bolt.id, isNotEmpty);

      final helix = await stackFor(helixId, Finish.foil);
      expect(helix.id, isNot(bolt.id));
    });

    test('sums quantities into an existing stack, preserving its id',
        () async {
      await seedStack(
          id: 'stack-1', scryfallId: boltId, quantity: 3, condition: 'good');

      await importer.commit(
        [makeRow(scryfallId: boltId, quantity: 2, condition: 'near_mint')],
        ImportMode.append,
      );

      final bolt = await stackFor(boltId, Finish.nonfoil);
      expect(bolt.id, 'stack-1');
      expect(bolt.quantity, 5);
      // Append keeps the existing soft attributes.
      expect(bolt.condition, 'good');
      expect(bolt.createdAt, seedTime);
      expect(bolt.updatedAt.isAfter(seedTime), isTrue);
    });

    test('same identity under a different provenance stays separate',
        () async {
      await seedStack(
        id: 'deck-stack-1',
        scryfallId: boltId,
        quantity: 4,
        provenance: 'deck-import',
      );

      await importer.commit(
          [makeRow(scryfallId: boltId, quantity: 2)], ImportMode.append);

      final deckStack =
          await stackFor(boltId, Finish.nonfoil, provenance: 'deck-import');
      expect(deckStack.quantity, 4);

      final manabox = await stackFor(boltId, Finish.nonfoil);
      expect(manabox.quantity, 2);
    });
  });

  group('CollectionImporter — replace', () {
    test('is an ID-preserving snapshot swap', () async {
      await seedStack(id: 'stack-unchanged', scryfallId: boltId, quantity: 4);
      await seedStack(
          id: 'stack-updated',
          scryfallId: helixId,
          finish: Finish.foil,
          quantity: 1);
      await seedStack(id: 'stack-stale', scryfallId: goyfId, quantity: 2);

      await importer.commit([
        makeRow(scryfallId: boltId, quantity: 4), // unchanged
        makeRow(scryfallId: helixId, finish: Finish.foil, quantity: 3),
        makeRow(scryfallId: 'new-1', quantity: 1), // new
      ], ImportMode.replace);

      final stacks = await allStacks();
      expect(stacks, hasLength(3));

      final unchanged = await stackFor(boltId, Finish.nonfoil);
      expect(unchanged.id, 'stack-unchanged');
      expect(unchanged.quantity, 4);
      expect(unchanged.updatedAt, seedTime); // untouched

      final updated = await stackFor(helixId, Finish.foil);
      expect(updated.id, 'stack-updated'); // id kept (D12)
      expect(updated.quantity, 3);
      expect(updated.createdAt, seedTime); // createdAt kept
      expect(updated.updatedAt.isAfter(seedTime), isTrue);

      // Stale row deleted; new row inserted with a fresh id.
      expect(stacks.any((s) => s.id == 'stack-stale'), isFalse);
      final added = await stackFor('new-1', Finish.nonfoil);
      expect(added.id, isNot('stack-stale'));
    });

    test('leaves other-provenance stacks untouched', () async {
      await seedStack(
        id: 'deck-stack-1',
        scryfallId: goyfId,
        quantity: 4,
        provenance: 'deck-import',
      );
      await seedStack(id: 'manabox-1', scryfallId: boltId, quantity: 2);

      // Incoming snapshot has neither goyf nor bolt → all manabox rows go.
      await importer.commit(
          [makeRow(scryfallId: helixId, quantity: 1)], ImportMode.replace);

      final stacks = await allStacks();
      expect(stacks, hasLength(2));

      final deckStack =
          await stackFor(goyfId, Finish.nonfoil, provenance: 'deck-import');
      expect(deckStack.id, 'deck-stack-1');
      expect(deckStack.quantity, 4);
    });

    test('rolls back the whole commit when one row fails', () async {
      await seedStack(id: 'stack-stale', scryfallId: goyfId, quantity: 2);

      // Duplicate identities violate the (scryfallId, finish, provenance)
      // unique key on the second insert.
      final duplicated = [
        makeRow(scryfallId: boltId, quantity: 1),
        makeRow(scryfallId: boltId, quantity: 2),
      ];

      await expectLater(
        importer.commit(duplicated, ImportMode.replace),
        throwsA(anything),
      );

      // Nothing changed: the stale row survived, nothing was inserted.
      final stacks = await allStacks();
      expect(stacks, hasLength(1));
      expect(stacks.single.id, 'stack-stale');
      expect(stacks.single.quantity, 2);
    });
  });

  group('CollectionImporter — computeDiff', () {
    test('append mode: adds and quantity-sum changes, never removes',
        () async {
      await seedStack(id: 'stack-1', scryfallId: boltId, quantity: 3);
      await seedStack(id: 'stack-2', scryfallId: goyfId, quantity: 2);

      final diff = await importer.computeDiff([
        makeRow(scryfallId: boltId, quantity: 2, name: 'Lightning Bolt'),
        makeRow(scryfallId: helixId, quantity: 1, name: 'Lightning Helix'),
      ], ImportMode.append);

      expect(diff.adds, hasLength(1));
      expect(diff.adds.single.cardName, 'Lightning Helix');
      expect(diff.adds.single.qtyBefore, 0);
      expect(diff.adds.single.qtyAfter, 1);

      expect(diff.changes, hasLength(1));
      expect(diff.changes.single.qtyBefore, 3);
      expect(diff.changes.single.qtyAfter, 5);

      // goyf is not in the incoming file but append never removes.
      expect(diff.removes, isEmpty);
    });

    test('replace mode: add/remove/change against the manabox snapshot',
        () async {
      await seedStack(id: 'stack-1', scryfallId: boltId, quantity: 3);
      await seedStack(id: 'stack-2', scryfallId: goyfId, quantity: 2);
      await seedStack(
        id: 'deck-stack-1',
        scryfallId: helixId,
        quantity: 9,
        provenance: 'deck-import',
      );

      final diff = await importer.computeDiff(
        [
          makeRow(scryfallId: boltId, quantity: 1, name: 'Lightning Bolt'),
          makeRow(scryfallId: helixId, quantity: 4, name: 'Lightning Helix'),
        ],
        ImportMode.replace,
        resolveNames: (ids) async => {goyfId: 'Tarmogoyf'},
      );

      // helix counts as an add: the deck-import stack is invisible here.
      expect(diff.adds, hasLength(1));
      expect(diff.adds.single.identity,
          const CardIdentity(helixId, Finish.nonfoil));
      expect(diff.adds.single.qtyAfter, 4);

      expect(diff.changes, hasLength(1));
      expect(diff.changes.single.qtyBefore, 3);
      expect(diff.changes.single.qtyAfter, 1);

      expect(diff.removes, hasLength(1));
      expect(diff.removes.single.cardName, 'Tarmogoyf');
      expect(diff.removes.single.qtyBefore, 2);
      expect(diff.removes.single.qtyAfter, 0);
    });

    test('identical quantities produce no change entries', () async {
      await seedStack(id: 'stack-1', scryfallId: boltId, quantity: 3);

      final diff = await importer.computeDiff(
        [makeRow(scryfallId: boltId, quantity: 3)],
        ImportMode.replace,
      );

      expect(diff.isEmpty, isTrue);
    });

    test('removes fall back to the scryfall id without a resolver', () async {
      await seedStack(id: 'stack-1', scryfallId: goyfId, quantity: 2);

      final diff = await importer.computeDiff([], ImportMode.replace);

      expect(diff.removes.single.cardName, goyfId);
    });
  });
}

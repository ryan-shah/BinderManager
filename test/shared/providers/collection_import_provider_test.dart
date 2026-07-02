import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/import/collection_importer.dart';
import 'package:binder_manager/core/import/manabox_parser.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/shared/providers/collection_import_provider.dart';

const boltId = '11111111-1111-1111-1111-111111111111';
const helixId = '22222222-2222-2222-2222-222222222222';
const unknownId = '99999999-9999-9999-9999-999999999999';

CardsCompanion _makeCard({
  required String scryfallId,
  required String name,
  String finishes = 'nonfoil,foil',
}) {
  return CardsCompanion(
    scryfallId: Value(scryfallId),
    oracleId: const Value('oracle-000'),
    name: Value(name),
    cmc: const Value(1.0),
    typeLine: const Value('Instant'),
    colorIdentity: const Value('R'),
    setCode: const Value('tst'),
    setName: const Value('Test Set'),
    collectorNumber: const Value('1'),
    rarity: const Value('common'),
    finishes: Value(finishes),
    layout: const Value('normal'),
    releasedAt: const Value('2023-01-01'),
  );
}

const _header =
    'Name,Set code,Set name,Collector number,Foil,Rarity,Quantity,'
    'ManaBox ID,Scryfall ID,Purchase price,Misprint,Altered,Condition,'
    'Language,Purchase price currency';

Uint8List _csv(List<String> dataRows) {
  return Uint8List.fromList(
    utf8.encode([_header, ...dataRows].join('\n')),
  );
}

String _row({
  String name = 'Lightning Bolt',
  String foil = 'normal',
  String quantity = '1',
  String scryfallId = boltId,
  String condition = 'near_mint',
}) {
  return '$name,tst,Test Set,1,$foil,common,$quantity,10001,$scryfallId,'
      '1.00,false,false,$condition,en,USD';
}

void main() {
  late CorpusDatabase corpus;
  late UserDatabase userDb;
  late CollectionImportNotifier notifier;

  setUp(() async {
    corpus = CorpusDatabase(NativeDatabase.memory());
    userDb = UserDatabase(NativeDatabase.memory());
    notifier = CollectionImportNotifier(corpus, userDb);

    await corpus.batch((b) {
      b.insertAll(corpus.cards, [
        _makeCard(scryfallId: boltId, name: 'Lightning Bolt'),
        _makeCard(scryfallId: helixId, name: 'Lightning Helix'),
      ]);
    });
  });

  tearDown(() async {
    notifier.dispose();
    await corpus.close();
    await userDb.close();
  });

  Future<void> seedStack({
    required String id,
    required String scryfallId,
    int quantity = 1,
    String provenance = CollectionImporter.provenanceManaBox,
  }) {
    final now = DateTime(2026, 1, 1);
    return userDb.into(userDb.stacks).insert(StacksCompanion.insert(
          id: id,
          scryfallId: scryfallId,
          finish: Finish.nonfoil,
          quantity: quantity,
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ));
  }

  group('CollectionImportNotifier — loadFile', () {
    test('moves idle → parsing → review and computes the diff', () async {
      final phases = <CollectionImportPhase>[];
      notifier.addListener((s) => phases.add(s.phase));

      await notifier.loadFile('collection.csv', _csv([_row(quantity: '4')]));

      expect(phases, [
        CollectionImportPhase.idle,
        CollectionImportPhase.parsing,
        CollectionImportPhase.review,
      ]);

      final state = notifier.state;
      expect(state.fileName, 'collection.csv');
      expect(state.parseResult!.matched, hasLength(1));
      expect(state.diff!.adds, hasLength(1));
      expect(state.diff!.adds.single.qtyAfter, 4);
      expect(state.previousStackCount, 0);
    });

    test('counts existing manabox stacks for the replace warning', () async {
      await seedStack(id: 's1', scryfallId: boltId, quantity: 3);
      await seedStack(
          id: 's2', scryfallId: helixId, provenance: 'deck-import');

      await notifier.loadFile('collection.csv', _csv([_row()]));

      // Only the manabox stack counts.
      expect(notifier.state.previousStackCount, 1);
    });

    test('enters error phase on a non-ManaBox file', () async {
      await notifier.loadFile(
        'bogus.csv',
        Uint8List.fromList(utf8.encode('a,b\n1,2')),
      );

      expect(notifier.state.phase, CollectionImportPhase.error);
      expect(notifier.state.error, contains('Not a ManaBox CSV'));
    });
  });

  group('CollectionImportNotifier — setMode', () {
    test('recomputes the diff for the new mode', () async {
      await seedStack(id: 's1', scryfallId: boltId, quantity: 3);
      await notifier.loadFile('collection.csv', _csv([_row(quantity: '2')]));

      // Default append: 3 + 2 = 5.
      expect(notifier.state.mode, ImportMode.append);
      expect(notifier.state.diff!.changes.single.qtyAfter, 5);

      await notifier.setMode(ImportMode.replace);

      // Replace: snapshot becomes exactly 2.
      expect(notifier.state.mode, ImportMode.replace);
      expect(notifier.state.diff!.changes.single.qtyAfter, 2);
    });

    test('resolves names for replace-mode removes via the corpus', () async {
      await seedStack(id: 's1', scryfallId: helixId, quantity: 2);
      await notifier.loadFile('collection.csv', _csv([_row()]));

      await notifier.setMode(ImportMode.replace);

      expect(notifier.state.diff!.removes.single.cardName, 'Lightning Helix');
    });

    test('just stores the mode when nothing is parsed yet', () async {
      await notifier.setMode(ImportMode.replace);

      expect(notifier.state.mode, ImportMode.replace);
      expect(notifier.state.diff, isNull);
    });
  });

  group('CollectionImportNotifier — unmatched queue', () {
    test('mapUnmatched moves the row to matched and recomputes the diff',
        () async {
      await notifier.loadFile(
        'collection.csv',
        _csv([
          _row(quantity: '2'),
          _row(name: 'Phantom', scryfallId: unknownId, quantity: '3'),
        ]),
      );
      expect(notifier.state.parseResult!.unmatched, hasLength(1));
      expect(notifier.state.diff!.adds, hasLength(1));

      await notifier.mapUnmatched(
          0, const CardIdentity(helixId, Finish.foil));

      final state = notifier.state;
      expect(state.parseResult!.unmatched, isEmpty);
      expect(state.parseResult!.matched, hasLength(2));
      final mapped = state.parseResult!.matched
          .singleWhere((m) => m.identity.scryfallId == helixId);
      expect(mapped.quantity, 3); // quantity carried from the raw row
      expect(mapped.condition, 'near_mint');
      expect(mapped.corpusCard.name, 'Lightning Helix');
      expect(state.diff!.adds, hasLength(2));
    });

    test('mapUnmatched merges into an existing matched identity', () async {
      await notifier.loadFile(
        'collection.csv',
        _csv([
          _row(quantity: '2'),
          _row(name: 'Phantom', scryfallId: unknownId, quantity: '3'),
        ]),
      );

      await notifier.mapUnmatched(
          0, const CardIdentity(boltId, Finish.nonfoil));

      final state = notifier.state;
      expect(state.parseResult!.matched, hasLength(1));
      expect(state.parseResult!.matched.single.quantity, 5);
      expect(state.diff!.adds.single.qtyAfter, 5);
    });

    test('mapUnmatched rejects a finish the printing lacks', () async {
      await notifier.loadFile(
        'collection.csv',
        _csv([_row(name: 'Phantom', scryfallId: unknownId)]),
      );

      await expectLater(
        notifier.mapUnmatched(0, const CardIdentity(boltId, Finish.etched)),
        throwsArgumentError,
      );
      // Queue unchanged.
      expect(notifier.state.parseResult!.unmatched, hasLength(1));
    });

    test('ignoreUnmatched flags the row without touching the diff', () async {
      await notifier.loadFile(
        'collection.csv',
        _csv([
          _row(quantity: '2'),
          _row(name: 'Phantom', scryfallId: unknownId),
        ]),
      );
      final diffBefore = notifier.state.diff;

      notifier.ignoreUnmatched(0);

      final state = notifier.state;
      expect(state.parseResult!.unmatched.single.ignored, isTrue);
      expect(state.diff, same(diffBefore));
    });
  });

  group('CollectionImportNotifier — commit', () {
    test('moves review → committing → done and writes stacks', () async {
      await notifier.loadFile('collection.csv', _csv([_row(quantity: '4')]));

      final phases = <CollectionImportPhase>[];
      notifier.addListener((s) => phases.add(s.phase));
      await notifier.commit();

      expect(phases, contains(CollectionImportPhase.committing));
      expect(notifier.state.phase, CollectionImportPhase.done);

      final stacks = await userDb.select(userDb.stacks).get();
      expect(stacks, hasLength(1));
      expect(stacks.single.quantity, 4);
      expect(
          stacks.single.provenance, CollectionImporter.provenanceManaBox);
    });

    test('does nothing outside the review phase', () async {
      await notifier.commit();

      expect(notifier.state.phase, CollectionImportPhase.idle);
      expect(await userDb.select(userDb.stacks).get(), isEmpty);
    });
  });

  group('CollectionImportNotifier — reset', () {
    test('returns to a pristine idle state', () async {
      await notifier.loadFile('collection.csv', _csv([_row()]));
      expect(notifier.state.phase, CollectionImportPhase.review);

      notifier.reset();

      final state = notifier.state;
      expect(state.phase, CollectionImportPhase.idle);
      expect(state.fileName, isNull);
      expect(state.parseResult, isNull);
      expect(state.diff, isNull);
      expect(state.mode, ImportMode.append);
    });
  });
}

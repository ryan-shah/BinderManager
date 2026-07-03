import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/decks/deck_repository.dart';
import 'package:binder_manager/core/import/decklist_parser.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/shared/providers/deck_providers.dart';

CardsCompanion makeCard({
  required String id,
  required String name,
  String setCode = 'm10',
  String collectorNumber = '146',
  double? priceUsd,
}) {
  return CardsCompanion.insert(
    scryfallId: id,
    oracleId: 'oracle-$id',
    name: name,
    cmc: 1,
    typeLine: 'Instant',
    colorIdentity: 'R',
    setCode: setCode,
    setName: 'Set $setCode',
    collectorNumber: collectorNumber,
    rarity: 'common',
    finishes: 'nonfoil,foil',
    layout: 'normal',
    releasedAt: '2020-01-01',
    priceUsd: Value(priceUsd),
  );
}

void main() {
  late CorpusDatabase corpus;
  late UserDatabase user;
  late DeckImportNotifier notifier;

  final t = DateTime.utc(2026, 7, 1);

  setUp(() async {
    corpus = CorpusDatabase(NativeDatabase.memory());
    user = UserDatabase(NativeDatabase.memory());
    notifier = DeckImportNotifier(
      DecklistParser(corpus),
      DeckRepository(user),
      user,
    );

    await corpus.batch((b) {
      b.insertAll(corpus.cards, [
        makeCard(
          id: 'bolt-m10',
          name: 'Lightning Bolt',
          setCode: 'm10',
          collectorNumber: '146',
          priceUsd: 3.0,
        ),
        makeCard(
          id: 'bolt-2x2',
          name: 'Lightning Bolt',
          setCode: '2x2',
          collectorNumber: '117',
          priceUsd: 1.0,
        ),
        makeCard(
          id: 'opt-xln',
          name: 'Opt',
          setCode: 'xln',
          collectorNumber: '65',
          priceUsd: 0.2,
        ),
      ]);
    });
  });

  tearDown(() async {
    notifier.dispose();
    await corpus.close();
    await user.close();
  });

  Future<void> addStack(String scryfallId, int quantity,
      {Finish finish = Finish.nonfoil, String provenance = 'manabox'}) {
    return user.into(user.stacks).insert(StacksCompanion.insert(
          id: '$scryfallId-$finish-$provenance',
          scryfallId: scryfallId,
          finish: finish,
          quantity: quantity,
          provenance: provenance,
          createdAt: t,
          updatedAt: t,
        ));
  }

  group('parseText', () {
    test('exact lines go straight to preview with planned entries', () async {
      await addStack('opt-xln', 4);

      await notifier.parseText('3 Opt (XLN) 65');

      final state = notifier.state;
      expect(state.phase, DeckImportPhase.preview);
      expect(state.needsFidelity, isFalse);
      expect(state.unowned, isEmpty);
      expect(state.lines, hasLength(1));
      expect(state.lines.single.planned, hasLength(1));
      expect(state.lines.single.planned.single.card.scryfallId, 'opt-xln');
      expect(state.lines.single.planned.single.quantity, 3);
      expect(state.canCommit, isTrue);
    });

    test('multi-printing names require a fidelity choice', () async {
      await notifier.parseText('4 Lightning Bolt');

      final state = notifier.state;
      expect(state.phase, DeckImportPhase.preview);
      expect(state.needsFidelity, isTrue);
      expect(state.lines.single.planned, isEmpty);
      expect(state.canCommit, isFalse);
    });

    test('errors are carried into state', () async {
      await addStack('opt-xln', 4);
      await notifier.parseText('3 Opt (XLN) 65\nnot a card');

      expect(notifier.state.errors, hasLength(1));
      expect(notifier.state.errors.single.lineNumber, 2);
    });

    test('empty text returns to idle keeping metadata', () async {
      notifier.setMetadata(name: 'Burn', format: 'modern');
      await notifier.parseText('   ');

      expect(notifier.state.phase, DeckImportPhase.idle);
      expect(notifier.state.deckName, 'Burn');
      expect(notifier.state.lines, isEmpty);
    });
  });

  group('chooseFidelity — cheapestFirst', () {
    test('allocates owned printings cheapest first, remainder unowned',
        () async {
      // Owns 1 of the cheap printing, 2 of the expensive one; needs 4.
      await addStack('bolt-2x2', 1);
      await addStack('bolt-m10', 2);

      await notifier.parseText('4 Lightning Bolt');
      await notifier.chooseFidelity(FidelityMode.cheapestFirst);

      final state = notifier.state;
      expect(state.needsFidelity, isFalse);
      expect(state.fidelityMode, FidelityMode.cheapestFirst);

      final planned = state.lines.single.planned;
      expect(planned, hasLength(3));
      // Cheapest owned first (2x2 @ $1), then m10 @ $3, then the
      // overall-cheapest printing (2x2) for the remainder, marked unowned.
      expect(planned[0].card.scryfallId, 'bolt-2x2');
      expect(planned[0].quantity, 1);
      expect(planned[0].isUnowned, isFalse);
      expect(planned[1].card.scryfallId, 'bolt-m10');
      expect(planned[1].quantity, 2);
      expect(planned[1].isUnowned, isFalse);
      expect(planned[2].card.scryfallId, 'bolt-2x2');
      expect(planned[2].quantity, 1);
      expect(planned[2].isUnowned, isTrue);

      // Shortfalls are deferred to commit — canCommit is true here.
      expect(state.unowned, isEmpty);
      expect(state.canCommit, isTrue);
    });

    test('fully owned allocation needs no unowned prompt', () async {
      await addStack('bolt-2x2', 4);

      await notifier.parseText('4 Lightning Bolt');
      await notifier.chooseFidelity(FidelityMode.cheapestFirst);

      final state = notifier.state;
      expect(state.unowned, isEmpty);
      expect(state.lines.single.planned.single.card.scryfallId, 'bolt-2x2');
      expect(state.lines.single.planned.single.quantity, 4);
      expect(state.canCommit, isTrue);
    });

    test('lines with no owned copies stay as pending picks', () async {
      // User owns no Lightning Bolt printings at all.
      await notifier.parseText('4 Lightning Bolt');
      await notifier.chooseFidelity(FidelityMode.cheapestFirst);

      final state = notifier.state;
      expect(state.needsFidelity, isFalse);
      expect(state.fidelityMode, FidelityMode.cheapestFirst);
      expect(state.lines.single.isPendingPick, isTrue);
      expect(state.lines.single.planned, isEmpty);
      expect(state.canCommit, isFalse);
    });

    test('exact lines claim owned copies before fidelity lines', () async {
      await addStack('bolt-2x2', 4);

      // The exact line takes 3 of the 4 owned 2x2 bolts.
      await notifier.parseText('3 Lightning Bolt (2X2) 117\n2 Lightning Bolt');
      await notifier.chooseFidelity(FidelityMode.cheapestFirst);

      final fidelityLine = notifier.state.lines[1];
      expect(fidelityLine.planned[0].card.scryfallId, 'bolt-2x2');
      expect(fidelityLine.planned[0].quantity, 1);
      expect(fidelityLine.planned[0].isUnowned, isFalse);
      expect(fidelityLine.planned[1].quantity, 1);
      expect(fidelityLine.planned[1].isUnowned, isTrue);
    });
  });

  group('chooseFidelity — pickManually', () {
    test('leaves lines pending until each printing is picked', () async {
      await addStack('bolt-m10', 4);

      await notifier.parseText('4 Lightning Bolt');
      await notifier.chooseFidelity(FidelityMode.pickManually);

      var state = notifier.state;
      expect(state.needsFidelity, isFalse);
      expect(state.fidelityMode, FidelityMode.pickManually);
      expect(state.hasPendingPicks, isTrue);
      expect(state.canCommit, isFalse);

      final candidates =
          (state.lines.single.resolution as ResolvedByName).candidates;
      final m10 = candidates.singleWhere((c) => c.scryfallId == 'bolt-m10');
      notifier.pickPrinting(0, m10);
      await pumpEventQueue();

      state = notifier.state;
      expect(state.hasPendingPicks, isFalse);
      expect(state.lines.single.planned.single.card.scryfallId, 'bolt-m10');
      expect(state.lines.single.planned.single.quantity, 4);
      expect(state.unowned, isEmpty);
      expect(state.canCommit, isTrue);
      expect(state.sourceText, '4 Lightning Bolt (M10) 146');
    });

    test('picking an unowned printing is detected on commit', () async {
      await notifier.parseText('4 Lightning Bolt');
      await notifier.chooseFidelity(FidelityMode.pickManually);

      final candidates =
          (notifier.state.lines.single.resolution as ResolvedByName)
              .candidates;
      notifier.pickPrinting(0, candidates.first);
      await pumpEventQueue();

      expect(notifier.state.unowned, isEmpty);
      expect(notifier.state.canCommit, isTrue);

      await notifier.commit();
      expect(notifier.state.unowned, hasLength(1));
      expect(notifier.state.unowned.single.missing, 4);
    });
  });

  group('unowned prompt', () {
    test('commit detects shortfalls for unowned cards', () async {
      await notifier.parseText('3 Opt (XLN) 65');
      expect(notifier.state.unowned, isEmpty);
      expect(notifier.state.canCommit, isTrue);

      await notifier.commit();

      expect(notifier.state.unowned, hasLength(1));
      expect(notifier.state.unowned.single.card.scryfallId, 'opt-xln');
      expect(notifier.state.unowned.single.missing, 3);
    });

    test('partial ownership prompts with the shortfall only', () async {
      await addStack('opt-xln', 1);
      await notifier.parseText('3 Opt (XLN) 65');
      await notifier.commit();

      expect(notifier.state.unowned.single.missing, 2);
    });

    test('importUnowned splits entries into owned and unowned parts',
        () async {
      await addStack('opt-xln', 1);
      await notifier.parseText('3 Opt (XLN) 65');
      await notifier.commit();
      await notifier.resolveUnowned(UnownedChoice.importUnowned);

      final state = notifier.state;
      expect(state.unowned, isEmpty);
      final planned = state.lines.single.planned;
      expect(planned, hasLength(2));
      expect(planned[0].quantity, 1);
      expect(planned[0].isUnowned, isFalse);
      expect(planned[1].quantity, 2);
      expect(planned[1].isUnowned, isTrue);
      expect(state.phase, DeckImportPhase.done);
    });

    test('addToCollection inserts deck-import stacks and clears marks',
        () async {
      await notifier.parseText('3 Opt (XLN) 65');
      await notifier.commit();
      await notifier.resolveUnowned(UnownedChoice.addToCollection);

      final stacks = await user.select(user.stacks).get();
      expect(stacks.any((s) =>
          s.scryfallId == 'opt-xln' &&
          s.quantity == 3 &&
          s.finish == Finish.nonfoil &&
          s.provenance == 'deck-import'), isTrue);

      final state = notifier.state;
      expect(state.unowned, isEmpty);
      expect(state.lines.single.planned.every((p) => !p.isUnowned), isTrue);
      expect(state.phase, DeckImportPhase.done);
    });

    test('addToCollection upserts onto an existing deck-import stack',
        () async {
      await addStack('opt-xln', 1, provenance: 'deck-import');
      await notifier.parseText('3 Opt (XLN) 65');
      await notifier.commit();

      expect(notifier.state.unowned.single.missing, 2);
      await notifier.resolveUnowned(UnownedChoice.addToCollection);

      final stacks = await user.select(user.stacks).get();
      expect(stacks, hasLength(1));
      expect(stacks.single.quantity, 3);
    });

    test('backOut returns to an editable idle state keeping the text',
        () async {
      notifier.setMetadata(name: 'Burn');
      await notifier.parseText('3 Opt (XLN) 65');
      await notifier.commit();
      await notifier.resolveUnowned(UnownedChoice.backOut);

      final state = notifier.state;
      expect(state.phase, DeckImportPhase.idle);
      expect(state.sourceText, '3 Opt (XLN) 65');
      expect(state.deckName, 'Burn');
      expect(state.lines, isEmpty);
      expect(state.unowned, isEmpty);
    });
  });

  group('commit', () {
    test('persists deck metadata, sections, and per-line flags', () async {
      await addStack('opt-xln', 4);
      await addStack('bolt-m10', 4);

      notifier.setMetadata(
        name: 'Burn',
        format: 'modern',
        assembled: false,
        shared: true,
      );
      await notifier.parseText(
        '4 Lightning Bolt (M10) 146\nSideboard\n3 Opt (XLN) 65',
      );
      notifier.toggleEntryShared(1);
      await notifier.commit();

      final state = notifier.state;
      expect(state.phase, DeckImportPhase.done);
      expect(state.createdDeckId, isNotNull);

      final deck = await user.select(user.decks).getSingle();
      expect(deck.id, state.createdDeckId);
      expect(deck.name, 'Burn');
      expect(deck.format, 'modern');
      expect(deck.isAssembled, isFalse);
      expect(deck.isShared, isTrue);

      final entries = await user.select(user.deckEntries).get();
      expect(entries, hasLength(2));
      final bolt = entries.singleWhere((e) => e.scryfallId == 'bolt-m10');
      expect(bolt.section, DeckSection.main);
      expect(bolt.quantity, 4);
      expect(bolt.cardName, 'Lightning Bolt');
      expect(bolt.printingSpecified, isTrue);
      expect(bolt.isShared, isFalse);
      final opt = entries.singleWhere((e) => e.scryfallId == 'opt-xln');
      expect(opt.section, DeckSection.sideboard);
      expect(opt.isShared, isTrue);
      expect(opt.isUnowned, isFalse);
    });

    test('unowned marks survive into deck entries', () async {
      await notifier.parseText('3 Opt (XLN) 65');
      await notifier.commit();
      await notifier.resolveUnowned(UnownedChoice.importUnowned);

      final entry = await user.select(user.deckEntries).getSingle();
      expect(entry.isUnowned, isTrue);
      expect(notifier.state.phase, DeckImportPhase.done);
    });

    test('defaults the name when blank', () async {
      await addStack('opt-xln', 4);
      await notifier.parseText('3 Opt (XLN) 65');
      await notifier.commit();

      final deck = await user.select(user.decks).getSingle();
      expect(deck.name, 'Imported deck');
      expect(deck.isAssembled, isTrue);
      expect(deck.isShared, isFalse);
    });

    test('does nothing while prompts are pending', () async {
      await notifier.parseText('4 Lightning Bolt');
      expect(notifier.state.needsFidelity, isTrue);

      await notifier.commit();

      expect(notifier.state.phase, DeckImportPhase.preview);
      expect(await user.select(user.decks).get(), isEmpty);
    });
  });

  group('misc', () {
    test('toggleEntryShared flips a single line', () async {
      await addStack('opt-xln', 4);
      await notifier.parseText('3 Opt (XLN) 65');

      notifier.toggleEntryShared(0);
      expect(notifier.state.lines.single.shared, isTrue);
      notifier.toggleEntryShared(0);
      expect(notifier.state.lines.single.shared, isFalse);
      // Out-of-range indexes are ignored.
      notifier.toggleEntryShared(5);
    });

    test('setMetadata shared flips all loaded lines', () async {
      await addStack('opt-xln', 4);
      await addStack('bolt-m10', 4);

      await notifier.parseText('3 Opt (XLN) 65\n4 Lightning Bolt (M10) 146');
      expect(notifier.state.lines.every((l) => !l.shared), isTrue);

      notifier.setMetadata(shared: true);
      expect(notifier.state.lines.every((l) => l.shared), isTrue);
      expect(notifier.state.shared, isTrue);

      notifier.setMetadata(shared: false);
      expect(notifier.state.lines.every((l) => !l.shared), isTrue);
      expect(notifier.state.shared, isFalse);
    });

    test('loadFile decodes bytes and defaults the deck name', () async {
      await addStack('opt-xln', 4);

      final bytes = Uint8List.fromList('3 Opt (XLN) 65'.codeUnits);
      await notifier.loadFile('my burn deck.txt', bytes);

      expect(notifier.state.deckName, 'my burn deck');
      expect(notifier.state.phase, DeckImportPhase.preview);
      expect(notifier.state.lines, hasLength(1));
    });

    test('loadFile keeps an existing deck name', () async {
      await addStack('opt-xln', 4);
      notifier.setMetadata(name: 'Kept');

      final bytes = Uint8List.fromList('3 Opt (XLN) 65'.codeUnits);
      await notifier.loadFile('other.txt', bytes);

      expect(notifier.state.deckName, 'Kept');
    });

    test('reset returns to the initial state', () async {
      await addStack('opt-xln', 4);
      await notifier.parseText('3 Opt (XLN) 65');
      notifier.setMetadata(name: 'Burn');

      notifier.reset();

      expect(notifier.state.phase, DeckImportPhase.idle);
      expect(notifier.state.deckName, isEmpty);
      expect(notifier.state.sourceText, isEmpty);
      expect(notifier.state.lines, isEmpty);
    });
  });
}

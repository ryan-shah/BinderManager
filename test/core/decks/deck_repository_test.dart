import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/decks/deck_repository.dart';

void main() {
  late UserDatabase db;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  const drafts = [
    DeckEntryDraft(
      scryfallId: 'bolt-m10',
      cardName: 'Lightning Bolt',
      quantity: 4,
      section: DeckSection.main,
      printingSpecified: true,
    ),
    DeckEntryDraft(
      scryfallId: 'duress-xln',
      cardName: 'Duress',
      quantity: 2,
      section: DeckSection.sideboard,
      isShared: true,
    ),
    DeckEntryDraft(
      scryfallId: 'opt-xln',
      cardName: 'Opt',
      quantity: 3,
      section: DeckSection.main,
      isUnowned: true,
    ),
  ];

  group('createDeck', () {
    test('creates the deck and all entries', () async {
      final repo = DeckRepository(db);
      final deckId = await repo.createDeck(
        name: 'Burn',
        format: 'modern',
        isAssembled: true,
        isShared: false,
        entries: drafts,
      );

      final deck = await db.select(db.decks).getSingle();
      expect(deck.id, deckId);
      expect(deck.name, 'Burn');
      expect(deck.format, 'modern');
      expect(deck.isAssembled, isTrue);
      expect(deck.isShared, isFalse);

      final entries = await db.select(db.deckEntries).get();
      expect(entries, hasLength(3));
      final bolt = entries.singleWhere((e) => e.scryfallId == 'bolt-m10');
      expect(bolt.deckId, deckId);
      expect(bolt.cardName, 'Lightning Bolt');
      expect(bolt.quantity, 4);
      expect(bolt.section, DeckSection.main);
      expect(bolt.printingSpecified, isTrue);
      expect(bolt.isShared, isFalse);
      final duress = entries.singleWhere((e) => e.scryfallId == 'duress-xln');
      expect(duress.section, DeckSection.sideboard);
      expect(duress.isShared, isTrue);
      final opt = entries.singleWhere((e) => e.scryfallId == 'opt-xln');
      expect(opt.isUnowned, isTrue);
    });

    test('null format round-trips', () async {
      final repo = DeckRepository(db);
      await repo.createDeck(
        name: 'Burn',
        isAssembled: true,
        isShared: true,
        entries: const [],
      );

      final deck = await db.select(db.decks).getSingle();
      expect(deck.format, isNull);
      expect(deck.isShared, isTrue);
    });

    test('is transactional — a failing entry rolls back the deck', () async {
      // A fixed id generator makes the second entry collide with the first
      // on the primary key, failing mid-transaction.
      var calls = 0;
      final repo = DeckRepository(db, newId: () => 'dup-${calls++ ~/ 2}');

      await expectLater(
        repo.createDeck(
          name: 'Broken',
          isAssembled: true,
          isShared: false,
          entries: drafts,
        ),
        throwsA(isA<Exception>()),
      );

      expect(await db.select(db.decks).get(), isEmpty);
      expect(await db.select(db.deckEntries).get(), isEmpty);
    });
  });

  group('deleteDeck', () {
    test('cascades to entries', () async {
      final repo = DeckRepository(db);
      final deckId = await repo.createDeck(
        name: 'Burn',
        isAssembled: true,
        isShared: false,
        entries: drafts,
      );

      await repo.deleteDeck(deckId);

      expect(await db.select(db.decks).get(), isEmpty);
      expect(await db.select(db.deckEntries).get(), isEmpty);
    });
  });

  group('toggles', () {
    test('setDeckShared and setDeckAssembled update flags and updatedAt',
        () async {
      var now = DateTime.utc(2026, 7, 1, 12, 0, 0);
      final repo = DeckRepository(db, now: () => now);
      final deckId = await repo.createDeck(
        name: 'Burn',
        isAssembled: true,
        isShared: false,
        entries: const [],
      );

      // Drift stores datetimes as unix seconds and reads them back in
      // local time — compare in UTC.
      now = DateTime.utc(2026, 7, 1, 12, 0, 5);
      await repo.setDeckShared(deckId, true);
      var deck = await db.select(db.decks).getSingle();
      expect(deck.isShared, isTrue);
      expect(deck.updatedAt.toUtc(), DateTime.utc(2026, 7, 1, 12, 0, 5));

      now = DateTime.utc(2026, 7, 1, 12, 0, 9);
      await repo.setDeckAssembled(deckId, false);
      deck = await db.select(db.decks).getSingle();
      expect(deck.isAssembled, isFalse);
      expect(deck.updatedAt.toUtc(), DateTime.utc(2026, 7, 1, 12, 0, 9));
      expect(deck.createdAt.toUtc(), DateTime.utc(2026, 7, 1, 12, 0, 0));
    });

    test('setEntryShared updates the entry and bumps its updatedAt',
        () async {
      var now = DateTime.utc(2026, 7, 1, 12, 0, 0);
      final repo = DeckRepository(db, now: () => now);
      await repo.createDeck(
        name: 'Burn',
        isAssembled: true,
        isShared: false,
        entries: drafts,
      );
      final entry = (await db.select(db.deckEntries).get())
          .singleWhere((e) => e.scryfallId == 'bolt-m10');

      now = DateTime.utc(2026, 7, 1, 12, 0, 7);
      await repo.setEntryShared(entry.id, true);

      final updated = (await db.select(db.deckEntries).get())
          .singleWhere((e) => e.id == entry.id);
      expect(updated.isShared, isTrue);
      expect(updated.updatedAt.toUtc(), DateTime.utc(2026, 7, 1, 12, 0, 7));

      // Other entries untouched.
      final others = (await db.select(db.deckEntries).get())
          .where((e) => e.id != entry.id);
      expect(others.every((e) => !e.isShared || e.scryfallId == 'duress-xln'),
          isTrue);
    });

    test('setEntryPrinting re-points the entry and marks it deliberate',
        () async {
      var now = DateTime.utc(2026, 7, 1, 12, 0, 0);
      final repo = DeckRepository(db, now: () => now);
      await repo.createDeck(
        name: 'Burn',
        isAssembled: true,
        isShared: false,
        entries: drafts,
      );
      // Opt resolved cheapest-first (printingSpecified false).
      final entry = (await db.select(db.deckEntries).get())
          .singleWhere((e) => e.scryfallId == 'opt-xln');
      expect(entry.printingSpecified, isFalse);

      now = DateTime.utc(2026, 7, 1, 12, 0, 7);
      await repo.setEntryPrinting(entry.id, 'opt-inv');

      final updated = (await db.select(db.deckEntries).get())
          .singleWhere((e) => e.id == entry.id);
      expect(updated.scryfallId, 'opt-inv');
      expect(updated.printingSpecified, isTrue);
      expect(updated.updatedAt.toUtc(), DateTime.utc(2026, 7, 1, 12, 0, 7));
      // Name and quantity survive; the entry identity is stable.
      expect(updated.cardName, 'Opt');
      expect(updated.quantity, 3);

      // Other entries untouched.
      final bolt = (await db.select(db.deckEntries).get())
          .singleWhere((e) => e.cardName == 'Lightning Bolt');
      expect(bolt.scryfallId, 'bolt-m10');
    });
  });

  group('watchDecks', () {
    test('emits items with counts, sorted by name, and updates live',
        () async {
      final repo = DeckRepository(db);

      final emissions = <List<DeckListItem>>[];
      final sub = repo.watchDecks().listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      await repo.createDeck(
        name: 'Zoo',
        format: 'modern',
        isAssembled: true,
        isShared: false,
        entries: drafts,
      );
      await repo.createDeck(
        name: 'Affinity',
        isAssembled: false,
        isShared: true,
        entries: const [],
      );
      await pumpEventQueue();

      final items = emissions.last;
      expect(items, hasLength(2));
      // Name-sorted.
      expect(items[0].name, 'Affinity');
      expect(items[1].name, 'Zoo');

      expect(items[0].cardCount, 0);
      expect(items[0].unownedCount, 0);
      expect(items[0].isAssembled, isFalse);
      expect(items[0].isShared, isTrue);

      expect(items[1].cardCount, 4 + 2 + 3);
      expect(items[1].unownedCount, 3);
      expect(items[1].format, 'modern');
    });
  });

  group('watchDeck', () {
    test('emits deck with sorted entries, null for missing ids', () async {
      final repo = DeckRepository(db);
      final deckId = await repo.createDeck(
        name: 'Burn',
        isAssembled: true,
        isShared: false,
        entries: drafts,
      );

      final detail = await repo.watchDeck(deckId).first;
      expect(detail, isNotNull);
      expect(detail!.deck.name, 'Burn');
      expect(detail.entries, hasLength(3));
      // Main before sideboard; names sorted within a section.
      expect(detail.entries[0].cardName, 'Lightning Bolt');
      expect(detail.entries[1].cardName, 'Opt');
      expect(detail.entries[2].cardName, 'Duress');

      final missing = await repo.watchDeck('nope').first;
      expect(missing, isNull);
    });

    test('deck with no entries has an empty entry list', () async {
      final repo = DeckRepository(db);
      final deckId = await repo.createDeck(
        name: 'Empty',
        isAssembled: true,
        isShared: false,
        entries: const [],
      );

      final detail = await repo.watchDeck(deckId).first;
      expect(detail!.entries, isEmpty);
    });

    test('emits again when an entry changes', () async {
      final repo = DeckRepository(db);
      final deckId = await repo.createDeck(
        name: 'Burn',
        isAssembled: true,
        isShared: false,
        entries: drafts,
      );

      final emissions = <DeckDetail?>[];
      final sub = repo.watchDeck(deckId).listen(emissions.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      final first = emissions.length;

      final entry = (await db.select(db.deckEntries).get()).first;
      await repo.setEntryShared(entry.id, true);
      await pumpEventQueue();

      expect(emissions.length, greaterThan(first));
      expect(
        emissions.last!.entries.singleWhere((e) => e.id == entry.id).isShared,
        isTrue,
      );
    });
  });
}

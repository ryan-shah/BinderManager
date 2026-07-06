import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/models/ordering.dart';

void main() {
  late UserDatabase db;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  StacksCompanion makeStack({
    String id = 'stack-1',
    String scryfallId = 'card-1',
    Finish finish = Finish.nonfoil,
    int quantity = 1,
    String provenance = 'manabox',
  }) {
    final now = DateTime.utc(2026, 7, 1);
    return StacksCompanion.insert(
      id: id,
      scryfallId: scryfallId,
      finish: finish,
      quantity: quantity,
      provenance: provenance,
      createdAt: now,
      updatedAt: now,
    );
  }

  DecksCompanion makeDeck({
    String id = 'deck-1',
    String name = 'Mono Red',
  }) {
    final now = DateTime.utc(2026, 7, 1);
    return DecksCompanion.insert(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
  }

  DeckEntriesCompanion makeEntry({
    String id = 'entry-1',
    String deckId = 'deck-1',
    String scryfallId = 'card-1',
    String cardName = 'Lightning Bolt',
    int quantity = 4,
    DeckSection section = DeckSection.main,
  }) {
    final now = DateTime.utc(2026, 7, 1);
    return DeckEntriesCompanion.insert(
      id: id,
      deckId: deckId,
      scryfallId: scryfallId,
      cardName: cardName,
      quantity: quantity,
      section: section,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('stacks', () {
    test('insert and select round-trips', () async {
      await db.into(db.stacks).insert(makeStack(quantity: 3));

      final rows = await db.select(db.stacks).get();
      expect(rows, hasLength(1));
      expect(rows.first.scryfallId, 'card-1');
      expect(rows.first.finish, Finish.nonfoil);
      expect(rows.first.quantity, 3);
      expect(rows.first.provenance, 'manabox');
      expect(rows.first.condition, isNull);
    });

    test('unique (scryfallId, finish, provenance) violation throws', () async {
      await db.into(db.stacks).insert(makeStack(id: 'a'));

      expect(
        () => db.into(db.stacks).insert(makeStack(id: 'b')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('same printing coexists across finishes and provenances', () async {
      await db.into(db.stacks).insert(makeStack(id: 'a'));
      await db.into(db.stacks).insert(makeStack(id: 'b', finish: Finish.foil));
      await db
          .into(db.stacks)
          .insert(makeStack(id: 'c', provenance: 'deck-import'));

      final rows = await db.select(db.stacks).get();
      expect(rows, hasLength(3));
    });
  });

  group('decks and entries', () {
    test('insert and select round-trips with defaults', () async {
      await db.into(db.decks).insert(makeDeck());
      await db.into(db.deckEntries).insert(makeEntry());

      final deck = await db.select(db.decks).getSingle();
      expect(deck.name, 'Mono Red');
      expect(deck.isAssembled, isTrue); // D3: assembled by default
      expect(deck.isShared, isFalse);
      expect(deck.format, isNull);

      final entry = await db.select(db.deckEntries).getSingle();
      expect(entry.deckId, 'deck-1');
      expect(entry.section, DeckSection.main);
      expect(entry.isShared, isFalse);
      expect(entry.isUnowned, isFalse);
      expect(entry.printingSpecified, isFalse);
      expect(entry.finish, isNull);
    });

    test('deleting a deck cascades to its entries', () async {
      await db.into(db.decks).insert(makeDeck());
      await db.into(db.deckEntries).insert(makeEntry(id: 'e1'));
      await db
          .into(db.deckEntries)
          .insert(makeEntry(id: 'e2', section: DeckSection.sideboard));

      await (db.delete(db.decks)..where((d) => d.id.equals('deck-1'))).go();

      expect(await db.select(db.deckEntries).get(), isEmpty);
    });

    test('entry referencing a missing deck throws', () async {
      expect(
        () => db.into(db.deckEntries).insert(makeEntry(deckId: 'nope')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('binders, binder_slots, snapshots (v2 tables, fresh create)', () {
    final now = DateTime.utc(2026, 7, 4);

    BindersCompanion makeBinder({String id = 'binder-1'}) =>
        BindersCompanion.insert(
          id: id,
          name: 'Trade binder',
          query: 'unused:true usd>5',
          priorityIndex: 0,
          layoutRows: 3,
          layoutCols: 3,
          pageCount: 20,
          createdAt: now,
          updatedAt: now,
        );

    BinderSlotsCompanion makeSlot({
      String id = 'slot-1',
      String binderId = 'binder-1',
    }) =>
        BinderSlotsCompanion.insert(
          id: id,
          binderId: binderId,
          scryfallId: 'bolt-1',
          finish: Finish.foil,
          quantity: 4,
          page: 3,
          side: PageSide.back,
          pocket: 5,
          createdAt: now,
          updatedAt: now,
        );

    test('binder round-trips with D6 defaults', () async {
      await db.into(db.binders).insert(makeBinder());

      final binder = await db.select(db.binders).getSingle();
      expect(binder.query, 'unused:true usd>5');
      expect(binder.doubleSided, isTrue);
      expect(binder.groupBy, isNull);
      expect(binder.sortBy, BinderAxis.price);
      expect(binder.sortDir, SortDirection.desc);
      expect(binder.isVirtual, isFalse);
    });

    test('slot round-trips exact position and enums', () async {
      await db.into(db.binders).insert(makeBinder());
      await db.into(db.binderSlots).insert(makeSlot());

      final slot = await db.select(db.binderSlots).getSingle();
      expect(slot.finish, Finish.foil);
      expect(slot.page, 3);
      expect(slot.side, PageSide.back);
      expect(slot.pocket, 5);
      expect(slot.isPinned, isFalse);
    });

    test('deleting a binder cascades to its slots', () async {
      await db.into(db.binders).insert(makeBinder());
      await db.into(db.binderSlots).insert(makeSlot(id: 's1'));
      await db.into(db.binderSlots).insert(makeSlot(id: 's2'));

      await (db.delete(db.binders)..where((b) => b.id.equals('binder-1')))
          .go();

      expect(await db.select(db.binderSlots).get(), isEmpty);
    });

    test('slot referencing a missing binder throws', () async {
      expect(
        () => db.into(db.binderSlots).insert(makeSlot(binderId: 'nope')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('snapshot round-trips', () async {
      await db.into(db.snapshots).insert(SnapshotsCompanion.insert(
            id: 'snap-1',
            triggerLabel: 'Price refresh',
            state: '{"binders":[]}',
            createdAt: now,
          ));

      final snapshot = await db.select(db.snapshots).getSingle();
      expect(snapshot.triggerLabel, 'Price refresh');
      expect(snapshot.state, '{"binders":[]}');
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/allocation/reservation.dart';
import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/card_identity.dart';

final _t = DateTime.utc(2026, 7, 1);
var _idCounter = 0;

StackRow stack(
  String scryfallId,
  int quantity, {
  Finish finish = Finish.nonfoil,
  String provenance = 'manabox',
}) {
  return StackRow(
    id: 's${_idCounter++}',
    scryfallId: scryfallId,
    finish: finish,
    quantity: quantity,
    provenance: provenance,
    createdAt: _t,
    updatedAt: _t,
  );
}

Deck deck(
  String id, {
  bool isAssembled = true,
  bool isShared = false,
}) {
  return Deck(
    id: id,
    name: 'Deck $id',
    isAssembled: isAssembled,
    isShared: isShared,
    createdAt: _t,
    updatedAt: _t,
  );
}

DeckEntryRow entry(
  String deckId,
  String scryfallId,
  int quantity, {
  DeckSection section = DeckSection.main,
  bool isShared = false,
  bool isUnowned = false,
}) {
  return DeckEntryRow(
    id: 'e${_idCounter++}',
    deckId: deckId,
    scryfallId: scryfallId,
    cardName: scryfallId,
    quantity: quantity,
    section: section,
    isShared: isShared,
    isUnowned: isUnowned,
    printingSpecified: false,
    createdAt: _t,
    updatedAt: _t,
  );
}

void main() {
  group('computeReservations', () {
    test('sums across assembled non-shared decks', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 8)],
        decks: [deck('a'), deck('b')],
        entries: [entry('a', 'bolt', 4), entry('b', 'bolt', 4)],
      );

      expect(summary.reservedOf('bolt'), 8);
      expect(summary.idleOf('bolt'), 0);
    });

    test('union-max across shared decks', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 4)],
        decks: [deck('a', isShared: true), deck('b', isShared: true)],
        entries: [entry('a', 'bolt', 4), entry('b', 'bolt', 3)],
      );

      expect(summary.reservedOf('bolt'), 4);
      expect(summary.idleOf('bolt'), 0);
    });

    test('mixed shared and non-shared = sum(non-shared) + max(shared)', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 10)],
        decks: [
          deck('a'),
          deck('b', isShared: true),
          deck('c', isShared: true),
        ],
        entries: [
          entry('a', 'bolt', 4),
          entry('b', 'bolt', 3),
          entry('c', 'bolt', 2),
        ],
      );

      expect(summary.reservedOf('bolt'), 4 + 3);
      expect(summary.idleOf('bolt'), 3);
    });

    test('entry-level shared flag joins the shared pool', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 10)],
        decks: [deck('a'), deck('b', isShared: true)],
        entries: [
          entry('a', 'bolt', 2, isShared: true),
          entry('b', 'bolt', 3),
        ],
      );

      // Both entries are effectively shared → union-max = 3.
      expect(summary.reservedOf('bolt'), 3);
    });

    test('maybeboard never reserves', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 4)],
        decks: [deck('a')],
        entries: [entry('a', 'bolt', 4, section: DeckSection.maybeboard)],
      );

      expect(summary.reservedOf('bolt'), 0);
      expect(summary.idleOf('bolt'), 4);
    });

    test('sideboard reserves like main', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 6)],
        decks: [deck('a')],
        entries: [
          entry('a', 'bolt', 4),
          entry('a', 'bolt', 2, section: DeckSection.sideboard),
        ],
      );

      expect(summary.reservedOf('bolt'), 6);
    });

    test('unassembled decks reserve nothing', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 4)],
        decks: [deck('a', isAssembled: false)],
        entries: [entry('a', 'bolt', 4)],
      );

      expect(summary.reservedOf('bolt'), 0);
      expect(summary.idleOf('bolt'), 4);
    });

    test('idle clamps to zero when over-reserved', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 2)],
        decks: [deck('a')],
        entries: [entry('a', 'bolt', 4)],
      );

      expect(summary.ownedOf('bolt'), 2);
      expect(summary.reservedOf('bolt'), 4);
      expect(summary.idleOf('bolt'), 0);
    });

    test('unowned entries are included in reservations', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 4)],
        decks: [deck('a')],
        entries: [entry('a', 'bolt', 4, isUnowned: true)],
      );

      expect(summary.reservedOf('bolt'), 4);
      expect(summary.idleOf('bolt'), 0);
    });

    test('finishes pool into owned quantity', () {
      final summary = computeReservations(
        stacks: [
          stack('bolt', 3),
          stack('bolt', 2, finish: Finish.foil),
          stack('bolt', 1, provenance: 'deck-import'),
        ],
        decks: [],
        entries: [],
      );

      expect(summary.ownedOf('bolt'), 6);
      expect(summary.idleOf('bolt'), 6);
    });

    test("a deck's multiple shared entries sum before union-max", () {
      final summary = computeReservations(
        stacks: [stack('bolt', 10)],
        decks: [deck('a', isShared: true), deck('b', isShared: true)],
        entries: [
          entry('a', 'bolt', 2),
          entry('a', 'bolt', 2, section: DeckSection.sideboard),
          entry('b', 'bolt', 3),
        ],
      );

      // Deck a pools 2+2=4 shared, deck b 3 → max is 4.
      expect(summary.reservedOf('bolt'), 4);
    });

    test('entries pointing at a missing deck are ignored', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 4)],
        decks: [],
        entries: [entry('ghost', 'bolt', 4)],
      );

      expect(summary.reservedOf('bolt'), 0);
    });

    test('ownedIds and idleIds reflect quantities', () {
      final summary = computeReservations(
        stacks: [stack('bolt', 4), stack('opt', 2)],
        decks: [deck('a')],
        entries: [entry('a', 'opt', 2)],
      );

      expect(summary.ownedIds, {'bolt', 'opt'});
      expect(summary.idleIds, {'bolt'});
      expect(summary.ownedOf('nope'), 0);
      expect(summary.reservedOf('nope'), 0);
      expect(summary.idleOf('nope'), 0);
    });
  });

  group('watchReservations', () {
    late UserDatabase db;

    setUp(() {
      db = UserDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('emits an initial summary and reloads on table updates', () async {
      await db.into(db.stacks).insert(StacksCompanion.insert(
            id: 'st1',
            scryfallId: 'bolt',
            finish: Finish.nonfoil,
            quantity: 4,
            provenance: 'manabox',
            createdAt: _t,
            updatedAt: _t,
          ));

      final emissions = <ReservationSummary>[];
      final sub = watchReservations(db).listen(emissions.add);
      addTearDown(sub.cancel);

      // Initial load.
      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions.last.ownedOf('bolt'), 4);
      expect(emissions.last.reservedOf('bolt'), 0);

      // A deck + entry arrives → reload with reservations.
      await db.into(db.decks).insert(DecksCompanion.insert(
            id: 'd1',
            name: 'Burn',
            createdAt: _t,
            updatedAt: _t,
          ));
      await db.into(db.deckEntries).insert(DeckEntriesCompanion.insert(
            id: 'e1',
            deckId: 'd1',
            scryfallId: 'bolt',
            cardName: 'Lightning Bolt',
            quantity: 3,
            section: DeckSection.main,
            createdAt: _t,
            updatedAt: _t,
          ));

      await pumpEventQueue();
      expect(emissions.length, greaterThan(1));
      expect(emissions.last.reservedOf('bolt'), 3);
      expect(emissions.last.idleOf('bolt'), 1);
    });
  });
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/tables/deck_tables.dart';
import '../database/user_database.dart';

/// Value type describing one deck entry to create with [DeckRepository.createDeck].
class DeckEntryDraft {
  const DeckEntryDraft({
    required this.scryfallId,
    required this.cardName,
    required this.quantity,
    required this.section,
    this.isShared = false,
    this.isUnowned = false,
    this.printingSpecified = false,
  });

  final String scryfallId;

  /// The name as written in the imported list.
  final String cardName;

  final int quantity;
  final DeckSection section;
  final bool isShared;
  final bool isUnowned;
  final bool printingSpecified;
}

/// One row of the decks list: deck metadata plus aggregate counts.
class DeckListItem {
  const DeckListItem({
    required this.id,
    required this.name,
    this.format,
    required this.isAssembled,
    required this.isShared,
    required this.cardCount,
    required this.unownedCount,
  });

  final String id;
  final String name;
  final String? format;
  final bool isAssembled;
  final bool isShared;

  /// Sum of entry quantities across all sections.
  final int cardCount;

  /// Sum of quantities of entries flagged unowned.
  final int unownedCount;
}

/// A deck with its entries, for the detail screen.
class DeckDetail {
  const DeckDetail({required this.deck, required this.entries});

  final Deck deck;
  final List<DeckEntryRow> entries;
}

/// Repository for decks and deck entries in the user database.
///
/// [newId] and [now] are injectable for tests (drift stores datetimes at
/// second precision, so tests inject a controllable clock).
class DeckRepository {
  DeckRepository(
    this._db, {
    String Function()? newId,
    DateTime Function()? now,
  })  : _newId = newId ?? (() => const Uuid().v4()),
        _now = now ?? DateTime.now;

  final UserDatabase _db;
  final String Function() _newId;
  final DateTime Function() _now;

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Creates a deck and all its entries in one transaction. Returns the
  /// new deck id.
  Future<String> createDeck({
    required String name,
    String? format,
    required bool isAssembled,
    required bool isShared,
    required List<DeckEntryDraft> entries,
  }) async {
    final deckId = _newId();
    final now = _now();

    await _db.transaction(() async {
      await _db.into(_db.decks).insert(DecksCompanion.insert(
            id: deckId,
            name: name,
            format: Value(format),
            isAssembled: Value(isAssembled),
            isShared: Value(isShared),
            createdAt: now,
            updatedAt: now,
          ));
      for (final draft in entries) {
        await _db.into(_db.deckEntries).insert(DeckEntriesCompanion.insert(
              id: _newId(),
              deckId: deckId,
              scryfallId: draft.scryfallId,
              cardName: draft.cardName,
              quantity: draft.quantity,
              section: draft.section,
              isShared: Value(draft.isShared),
              isUnowned: Value(draft.isUnowned),
              printingSpecified: Value(draft.printingSpecified),
              createdAt: now,
              updatedAt: now,
            ));
      }
    });

    return deckId;
  }

  /// Deletes the deck; entries cascade (PRAGMA foreign_keys is ON).
  Future<void> deleteDeck(String deckId) =>
      (_db.delete(_db.decks)..where((d) => d.id.equals(deckId))).go();

  Future<void> setDeckShared(String deckId, bool shared) =>
      (_db.update(_db.decks)..where((d) => d.id.equals(deckId))).write(
        DecksCompanion(
          isShared: Value(shared),
          updatedAt: Value(_now()),
        ),
      );

  Future<void> setDeckAssembled(String deckId, bool assembled) =>
      (_db.update(_db.decks)..where((d) => d.id.equals(deckId))).write(
        DecksCompanion(
          isAssembled: Value(assembled),
          updatedAt: Value(_now()),
        ),
      );

  Future<void> setEntryShared(String entryId, bool shared) =>
      (_db.update(_db.deckEntries)..where((e) => e.id.equals(entryId))).write(
        DeckEntriesCompanion(
          isShared: Value(shared),
          updatedAt: Value(_now()),
        ),
      );

  // ---------------------------------------------------------------------------
  // Watches
  // ---------------------------------------------------------------------------

  /// All decks (name-sorted) with card and unowned counts.
  Stream<List<DeckListItem>> watchDecks() {
    final qtySum = _db.deckEntries.quantity.sum();
    final unownedSum = _db.deckEntries.quantity
        .sum(filter: _db.deckEntries.isUnowned.equals(true));

    final query = _db.select(_db.decks).join([
      leftOuterJoin(
        _db.deckEntries,
        _db.deckEntries.deckId.equalsExp(_db.decks.id),
        useColumns: false,
      ),
    ])
      ..addColumns([qtySum, unownedSum])
      ..groupBy([_db.decks.id])
      ..orderBy([OrderingTerm.asc(_db.decks.name)]);

    return query.watch().map((rows) => rows.map((row) {
          final deck = row.readTable(_db.decks);
          return DeckListItem(
            id: deck.id,
            name: deck.name,
            format: deck.format,
            isAssembled: deck.isAssembled,
            isShared: deck.isShared,
            cardCount: row.read(qtySum) ?? 0,
            unownedCount: row.read(unownedSum) ?? 0,
          );
        }).toList());
  }

  /// One deck with its entries (section order, then card name), or null
  /// when the deck does not exist.
  Stream<DeckDetail?> watchDeck(String deckId) {
    final query = _db.select(_db.decks).join([
      leftOuterJoin(
        _db.deckEntries,
        _db.deckEntries.deckId.equalsExp(_db.decks.id),
      ),
    ])
      ..where(_db.decks.id.equals(deckId));

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final deck = rows.first.readTable(_db.decks);
      final entries = rows
          .map((r) => r.readTableOrNull(_db.deckEntries))
          .whereType<DeckEntryRow>()
          .toList()
        ..sort((a, b) {
          final bySection = a.section.index.compareTo(b.section.index);
          if (bySection != 0) return bySection;
          return a.cardName.compareTo(b.cardName);
        });
      return DeckDetail(deck: deck, entries: entries);
    });
  }
}

import 'package:drift/drift.dart';

import '../../models/card_identity.dart';

/// Which part of a decklist an entry belongs to.
///
/// Main and sideboard reserve copies from the collection; maybeboard never
/// reserves (D3/D10).
enum DeckSection { main, sideboard, maybeboard }

/// A named deck (D3, D10).
///
/// Assembled decks reserve their full quantities; sharing is opt-in at the
/// deck level here or per-entry on [DeckEntries]. Shared quantities pool
/// via union-max across decks.
class Decks extends Table {
  /// Client-generated UUID v4 — stable across devices for later sync (D12).
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// Free-text format label (e.g. `commander`, `modern`), if given.
  TextColumn get format => text().nullable()();

  BoolColumn get isAssembled => boolean().withDefault(const Constant(true))();
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'decks';
}

/// One card line of a deck.
@DataClassName('DeckEntryRow')
@TableIndex(name: 'idx_deck_entries_deck_id', columns: {#deckId})
@TableIndex(name: 'idx_deck_entries_scryfall_id', columns: {#scryfallId})
class DeckEntries extends Table {
  /// Client-generated UUID v4 (D12).
  TextColumn get id => text()();

  TextColumn get deckId =>
      text().references(Decks, #id, onDelete: KeyAction.cascade)();

  /// Resolved printing. Always set by commit time; which printing depends
  /// on the list's `(SET) collector#` suffix or the fidelity choice (D3).
  TextColumn get scryfallId => text()();

  /// v1 decklists never carry finish; reserved for Phase 4 allocation.
  TextColumn get finish => textEnum<Finish>().nullable()();

  /// The card name as written in the imported list (survives corpus
  /// refreshes and makes re-import diffs readable).
  TextColumn get cardName => text()();

  IntColumn get quantity => integer()();
  TextColumn get section => textEnum<DeckSection>()();

  /// Per-card shared override; effective sharing is
  /// `deck.isShared || entry.isShared` (D3).
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();

  /// Named in the list but not owned at import time (D10 option 2).
  BoolColumn get isUnowned => boolean().withDefault(const Constant(false))();

  /// Whether the imported line carried a `(SET) collector#` suffix.
  BoolColumn get printingSpecified =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'deck_entries';
}

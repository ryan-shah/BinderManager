import 'package:drift/drift.dart';

import 'tables/corpus_tables.dart';

part 'corpus_database.g.dart';

/// The drift database for the Scryfall card corpus.
///
/// Stores every card from the Scryfall Default Cards bulk download.
/// Used as a read-heavy reference database for card search, pricing, and
/// identity lookups.
@DriftDatabase(tables: [Cards])
class CorpusDatabase extends _$CorpusDatabase {
  CorpusDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: border_color column for is:borderless queries. Existing
            // rows get null — a corpus re-download populates them.
            await m.addColumn(cards, cards.borderColor);
          }
        },
      );

  // ---------------------------------------------------------------------------
  // Corpus management
  // ---------------------------------------------------------------------------

  /// Deletes all rows from the cards table. Use before a full corpus refresh.
  Future<void> clearAllCards() => delete(cards).go();

  /// Returns the total number of cards in the corpus.
  Future<int> cardCount() async {
    final count = countAll();
    final query = selectOnly(cards)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count)!;
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Case-insensitive prefix search on the card name.
  Future<List<Card>> searchByName(String query, {int limit = 50}) {
    return (select(cards)
          ..where((c) => c.name.like('%$query%'))
          ..limit(limit))
        .get();
  }

  /// Returns all cards in the given set (case-insensitive).
  Future<List<Card>> searchBySet(String setCode, {int limit = 200}) {
    return (select(cards)
          ..where(
            (c) => c.setCode.equals(setCode.toLowerCase()),
          )
          ..limit(limit))
        .get();
  }

  /// Fetch a single card by its Scryfall UUID.
  Future<Card?> getCard(String scryfallId) {
    return (select(cards)..where((c) => c.scryfallId.equals(scryfallId)))
        .getSingleOrNull();
  }
}

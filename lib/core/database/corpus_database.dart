import 'package:drift/drift.dart';

import 'tables/corpus_tables.dart';

part 'corpus_database.g.dart';

/// The drift database for the Scryfall card corpus.
///
/// Stores every card from the Scryfall Default Cards bulk download.
/// Used as a read-heavy reference database for card search, pricing, and
/// identity lookups.
@DriftDatabase(tables: [Cards, CorpusMeta])
class CorpusDatabase extends _$CorpusDatabase {
  CorpusDatabase(super.e);

  /// Meta key for the ISO-8601 UTC timestamp of the last completed import.
  static const metaImportedAt = 'imported_at';

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: border_color column for is:borderless queries. Existing
            // rows get null — a corpus re-download populates them.
            await m.addColumn(cards, cards.borderColor);
          }
          if (from < 3) {
            // v3 (Phase 4): corpus_meta for the D11 freshness timestamp.
            await m.createTable(corpusMeta);
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

  /// Reads a corpus metadata value, or null if unset.
  Future<String?> getMeta(String key) async {
    final row = await (select(corpusMeta)..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Writes (upserts) a corpus metadata value.
  Future<void> setMeta(String key, String value) =>
      into(corpusMeta).insertOnConflictUpdate(
        CorpusMetaCompanion.insert(key: key, value: value),
      );

  /// When the corpus was last imported, or null if never recorded.
  Future<DateTime?> lastImportedAt() async {
    final raw = await getMeta(metaImportedAt);
    return raw == null ? null : DateTime.tryParse(raw);
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

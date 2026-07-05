import 'package:drift/drift.dart';

/// Drift table definition for the Scryfall card corpus.
///
/// Maps columns from the Scryfall Default Cards bulk JSON. Multi-value fields
/// (colors, colorIdentity, finishes, frameEffects) are stored as
/// comma-separated strings (e.g. "W,U,B").
@TableIndex(name: 'idx_cards_name', columns: {#name})
@TableIndex(name: 'idx_cards_set_code', columns: {#setCode})
@TableIndex(name: 'idx_cards_type_line', columns: {#typeLine})
@TableIndex(name: 'idx_cards_color_identity', columns: {#colorIdentity})
@TableIndex(name: 'idx_cards_rarity', columns: {#rarity})
@TableIndex(name: 'idx_cards_price_usd', columns: {#priceUsd})
class Cards extends Table {
  // --- Identity ---
  TextColumn get scryfallId => text()();
  TextColumn get oracleId => text()();
  TextColumn get name => text()();

  // --- Mana & type ---
  TextColumn get manaCost => text().nullable()();
  RealColumn get cmc => real()();
  TextColumn get typeLine => text()();
  TextColumn get oracleText => text().nullable()();

  // --- Colors ---
  TextColumn get colors => text().nullable()();
  TextColumn get colorIdentity => text()();

  // --- Set & printing ---
  TextColumn get setCode => text()();
  TextColumn get setName => text()();
  TextColumn get collectorNumber => text()();
  TextColumn get rarity => text()();
  TextColumn get finishes => text()();

  // --- Prices (USD / EUR) ---
  RealColumn get priceUsd => real().nullable()();
  RealColumn get priceUsdFoil => real().nullable()();
  RealColumn get priceUsdEtched => real().nullable()();
  RealColumn get priceEur => real().nullable()();
  RealColumn get priceEurFoil => real().nullable()();

  // --- Images ---
  TextColumn get imageUriSmall => text().nullable()();
  TextColumn get imageUriNormal => text().nullable()();

  // --- Flags ---
  BoolColumn get isFullart => boolean().withDefault(const Constant(false))();
  BoolColumn get isPromo => boolean().withDefault(const Constant(false))();

  // --- Metadata ---
  TextColumn get frameEffects => text().nullable()();
  TextColumn get securityStamp => text().nullable()();
  TextColumn get borderColor => text().nullable()();
  TextColumn get layout => text()();
  TextColumn get releasedAt => text()();

  @override
  Set<Column> get primaryKey => {scryfallId};

  @override
  String get tableName => 'cards';
}

/// Key-value metadata about the corpus itself (e.g. when it was last
/// imported, for the D11 staleness/refresh UI).
///
/// Lives in the corpus database on purpose: wiping the corpus wipes its
/// freshness timestamp with it.
@DataClassName('CorpusMetaRow')
class CorpusMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'corpus_meta';
}

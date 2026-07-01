import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/corpus_database.dart';

/// Parses a Scryfall Default Cards JSON payload and batch-inserts cards into
/// the [CorpusDatabase].
///
/// The JSON is a single top-level array: `[{card}, {card}, ...]`.
/// This parser decodes the JSON and processes cards in batches to keep
/// memory and transaction overhead manageable.
class ScryfallParser {
  /// Number of rows to insert per transaction batch.
  static const int batchSize = 500;

  final CorpusDatabase _db;

  ScryfallParser(this._db);

  /// Parses [jsonBytes] (the raw Scryfall JSON) and inserts all cards into the
  /// database.
  ///
  /// [onProgress] is called after each batch with the total number of cards
  /// processed so far.
  ///
  /// Returns the total number of cards inserted.
  Future<int> parseAndInsert(
    List<int> jsonBytes, {
    void Function(int cardsProcessed)? onProgress,
  }) async {
    final jsonString = utf8.decode(jsonBytes);
    final list = jsonDecode(jsonString) as List<dynamic>;

    var totalProcessed = 0;

    for (var i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize > list.length) ? list.length : i + batchSize;
      final batch = list.sublist(i, end);

      await _db.batch((b) {
        for (final item in batch) {
          final card = item as Map<String, dynamic>;
          final companion = _mapToCompanion(card);
          b.insert(_db.cards, companion, mode: InsertMode.insertOrReplace);
        }
      });

      totalProcessed = end;
      onProgress?.call(totalProcessed);
    }

    return totalProcessed;
  }

  /// Maps a single Scryfall card JSON object to a [CardsCompanion].
  CardsCompanion _mapToCompanion(Map<String, dynamic> card) {
    final prices = card['prices'] as Map<String, dynamic>? ?? {};
    final imageUris = card['image_uris'] as Map<String, dynamic>? ?? {};

    return CardsCompanion(
      scryfallId: Value(card['id'] as String),
      oracleId: Value(card['oracle_id'] as String? ?? ''),
      name: Value(card['name'] as String),
      manaCost: Value(card['mana_cost'] as String?),
      cmc: Value((card['cmc'] as num?)?.toDouble() ?? 0.0),
      typeLine: Value(card['type_line'] as String? ?? ''),
      oracleText: Value(card['oracle_text'] as String?),
      colors: Value(_joinList(card['colors'])),
      colorIdentity: Value(_joinList(card['color_identity']) ?? ''),
      setCode: Value(card['set'] as String? ?? ''),
      setName: Value(card['set_name'] as String? ?? ''),
      collectorNumber: Value(card['collector_number'] as String? ?? ''),
      rarity: Value(card['rarity'] as String? ?? ''),
      finishes: Value(_joinList(card['finishes']) ?? ''),
      priceUsd: Value(_parsePrice(prices['usd'])),
      priceUsdFoil: Value(_parsePrice(prices['usd_foil'])),
      priceUsdEtched: Value(_parsePrice(prices['usd_etched'])),
      priceEur: Value(_parsePrice(prices['eur'])),
      priceEurFoil: Value(_parsePrice(prices['eur_foil'])),
      imageUriSmall: Value(imageUris['small'] as String?),
      imageUriNormal: Value(imageUris['normal'] as String?),
      isFullart: Value(card['full_art'] as bool? ?? false),
      isPromo: Value(card['promo'] as bool? ?? false),
      frameEffects: Value(_joinList(card['frame_effects'])),
      securityStamp: Value(card['security_stamp'] as String?),
      layout: Value(card['layout'] as String? ?? ''),
      releasedAt: Value(card['released_at'] as String? ?? ''),
    );
  }

  /// Joins a JSON list of strings into a comma-separated string.
  /// Returns null if the input is null or not a list.
  static String? _joinList(dynamic value) {
    if (value is List) {
      return value.cast<String>().join(',');
    }
    return null;
  }

  /// Parses a Scryfall price string (e.g. "12.34") into a double.
  /// Returns null if the value is null or not parseable.
  static double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

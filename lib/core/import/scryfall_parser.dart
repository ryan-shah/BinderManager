import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/corpus_database.dart';

/// Parses Scryfall Default Cards JSON and batch-inserts cards into the
/// [CorpusDatabase].
///
/// Supports two modes:
/// - [parseAndInsert]: accepts pre-loaded bytes (tests / native).
/// - [parseFromStream]: accepts a byte stream and parses incrementally
///   without buffering the full payload — required for web where ~150 MB
///   exceeds practical memory limits.
class ScryfallParser {
  /// Number of rows to insert per transaction batch.
  static const int batchSize = 500;

  final CorpusDatabase _db;

  ScryfallParser(this._db);

  // -----------------------------------------------------------------------
  // Streaming API (web-safe)
  // -----------------------------------------------------------------------

  /// Parses a byte stream of Scryfall JSON and inserts cards as they arrive.
  ///
  /// The JSON must be a top-level array: `[{card}, {card}, ...]`.
  /// Individual card objects are extracted via brace-depth tracking, then
  /// decoded and batch-inserted. Peak memory is proportional to
  /// [batchSize] × card-size, not the full payload.
  ///
  /// [onBytesReceived] fires on every network chunk with cumulative bytes
  /// (useful for download progress when piping directly from HTTP).
  ///
  /// [onProgress] fires after each batch with total cards processed.
  ///
  /// [cardLimit] stops parsing after that many cards. Returning early
  /// cancels the underlying stream subscription, which aborts the HTTP
  /// download — used for the debug quick-import mode.
  ///
  /// Returns the total number of cards inserted.
  Future<int> parseFromStream(
    Stream<List<int>> byteStream, {
    void Function(int bytesReceived)? onBytesReceived,
    void Function(int cardsProcessed)? onProgress,
    int? cardLimit,
  }) async {
    final buffer = StringBuffer();
    var braceDepth = 0;
    var inString = false;
    var escaped = false;
    var foundArray = false;

    var pendingBatch = <Map<String, dynamic>>[];
    var totalProcessed = 0;
    var bytesReceived = 0;

    await for (final chunk in byteStream.transform(utf8.decoder)) {
      bytesReceived += utf8.encode(chunk).length;
      onBytesReceived?.call(bytesReceived);

      for (var i = 0; i < chunk.length; i++) {
        final char = chunk[i];

        // Scan for the opening '[' of the top-level array.
        if (!foundArray) {
          if (char == '[') foundArray = true;
          continue;
        }

        // Inside a string literal — only watch for escape and closing quote.
        if (inString) {
          buffer.writeCharCode(char.codeUnitAt(0));
          if (escaped) {
            escaped = false;
          } else if (char == r'\') {
            escaped = true;
          } else if (char == '"') {
            inString = false;
          }
          continue;
        }

        // Outside a string.
        switch (char) {
          case '{':
            braceDepth++;
            buffer.writeCharCode(char.codeUnitAt(0));
          case '}':
            buffer.writeCharCode(char.codeUnitAt(0));
            braceDepth--;
            if (braceDepth == 0) {
              // Completed one card object.
              final card =
                  jsonDecode(buffer.toString()) as Map<String, dynamic>;
              pendingBatch.add(card);
              buffer.clear();

              // Card limit reached — flush and stop. Returning from inside
              // the await-for cancels the stream, aborting the download.
              if (cardLimit != null &&
                  totalProcessed + pendingBatch.length >= cardLimit) {
                await _insertBatch(pendingBatch);
                totalProcessed += pendingBatch.length;
                onProgress?.call(totalProcessed);
                return totalProcessed;
              }

              if (pendingBatch.length >= batchSize) {
                await _insertBatch(pendingBatch);
                totalProcessed += pendingBatch.length;
                onProgress?.call(totalProcessed);
                pendingBatch = <Map<String, dynamic>>[];
              }
            }
          case '"':
            inString = true;
            buffer.writeCharCode(char.codeUnitAt(0));
          default:
            if (braceDepth > 0) {
              buffer.writeCharCode(char.codeUnitAt(0));
            }
          // Whitespace / commas outside braces are skipped.
        }
      }
    }

    // Flush remaining cards.
    if (pendingBatch.isNotEmpty) {
      await _insertBatch(pendingBatch);
      totalProcessed += pendingBatch.length;
      onProgress?.call(totalProcessed);
    }

    return totalProcessed;
  }

  // -----------------------------------------------------------------------
  // In-memory API (tests / native)
  // -----------------------------------------------------------------------

  /// Parses [jsonBytes] (the raw Scryfall JSON) and inserts all cards.
  ///
  /// Suitable for tests and native platforms where memory is not
  /// constrained. On web, prefer [parseFromStream].
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

      await _insertBatch(
        batch.cast<Map<String, dynamic>>(),
      );

      totalProcessed = end;
      onProgress?.call(totalProcessed);
    }

    return totalProcessed;
  }

  // -----------------------------------------------------------------------
  // Shared helpers
  // -----------------------------------------------------------------------

  Future<void> _insertBatch(List<Map<String, dynamic>> cards) async {
    await _db.batch((b) {
      for (final card in cards) {
        final companion = _mapToCompanion(card);
        b.insert(_db.cards, companion, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Maps a single Scryfall card JSON object to a [CardsCompanion].
  ///
  /// Multi-face layouts (transform, modal_dfc, …) keep `colors`,
  /// `image_uris`, `mana_cost`, and `oracle_text` on the `card_faces`
  /// objects rather than the card itself — merge from faces when the
  /// top-level field is absent so DFCs aren't colorless and image-less.
  CardsCompanion _mapToCompanion(Map<String, dynamic> card) {
    final prices = card['prices'] as Map<String, dynamic>? ?? {};
    final faces =
        (card['card_faces'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    var imageUris = card['image_uris'] as Map<String, dynamic>? ?? {};
    if (imageUris.isEmpty && faces.isNotEmpty) {
      imageUris = faces.first['image_uris'] as Map<String, dynamic>? ?? {};
    }

    var colors = _joinList(card['colors']);
    if (colors == null && faces.isNotEmpty) {
      final union = <String>{};
      var anyFaceHasColors = false;
      for (final face in faces) {
        final faceColors = face['colors'];
        if (faceColors is List) {
          anyFaceHasColors = true;
          union.addAll(faceColors.cast<String>());
        }
      }
      if (anyFaceHasColors) colors = union.join(',');
    }

    var manaCost = card['mana_cost'] as String?;
    if ((manaCost == null || manaCost.isEmpty) && faces.isNotEmpty) {
      final parts = faces
          .map((f) => f['mana_cost'] as String? ?? '')
          .where((c) => c.isNotEmpty);
      if (parts.isNotEmpty) manaCost = parts.join(' // ');
    }

    var oracleText = card['oracle_text'] as String?;
    if (oracleText == null && faces.isNotEmpty) {
      final parts = faces
          .map((f) => f['oracle_text'] as String? ?? '')
          .where((t) => t.isNotEmpty);
      if (parts.isNotEmpty) oracleText = parts.join('\n//\n');
    }

    return CardsCompanion(
      scryfallId: Value(card['id'] as String),
      oracleId: Value(card['oracle_id'] as String? ?? ''),
      name: Value(card['name'] as String),
      manaCost: Value(manaCost),
      cmc: Value((card['cmc'] as num?)?.toDouble() ?? 0.0),
      typeLine: Value(card['type_line'] as String? ?? ''),
      oracleText: Value(oracleText),
      colors: Value(colors),
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
      borderColor: Value(card['border_color'] as String?),
      layout: Value(card['layout'] as String? ?? ''),
      releasedAt: Value(card['released_at'] as String? ?? ''),
    );
  }

  /// Joins a JSON list of strings into a comma-separated string.
  static String? _joinList(dynamic value) {
    if (value is List) {
      return value.cast<String>().join(',');
    }
    return null;
  }

  /// Parses a Scryfall price string (e.g. "12.34") into a double.
  static double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/import/scryfall_parser.dart';

/// Builds a minimal Scryfall-format card JSON map with sensible defaults.
Map<String, dynamic> makeScryfallCard({
  String? id,
  String oracleId = 'oracle-000',
  String name = 'Lightning Bolt',
  String? manaCost = '{R}',
  num cmc = 1,
  String typeLine = 'Instant',
  String? oracleText = 'Lightning Bolt deals 3 damage to any target.',
  List<String>? colors = const ['R'],
  List<String> colorIdentity = const ['R'],
  String set_ = 'lea',
  String setName = 'Limited Edition Alpha',
  String collectorNumber = '1',
  String rarity = 'common',
  List<String> finishes = const ['nonfoil'],
  Map<String, String?>? prices,
  Map<String, String?>? imageUris,
  bool fullArt = false,
  bool promo = false,
  List<String>? frameEffects,
  String? securityStamp,
  String layout = 'normal',
  String releasedAt = '1993-08-05',
}) {
  id ??= 'id-${DateTime.now().microsecondsSinceEpoch}';
  return {
    'id': id,
    'oracle_id': oracleId,
    'name': name,
    if (manaCost != null) 'mana_cost': manaCost,
    'cmc': cmc,
    'type_line': typeLine,
    if (oracleText != null) 'oracle_text': oracleText,
    if (colors != null) 'colors': colors,
    'color_identity': colorIdentity,
    'set': set_,
    'set_name': setName,
    'collector_number': collectorNumber,
    'rarity': rarity,
    'finishes': finishes,
    if (prices != null) 'prices': prices,
    if (imageUris != null) 'image_uris': imageUris,
    'full_art': fullArt,
    'promo': promo,
    if (frameEffects != null) 'frame_effects': frameEffects,
    if (securityStamp != null) 'security_stamp': securityStamp,
    'layout': layout,
    'released_at': releasedAt,
  };
}

/// Encodes a list of card maps as Scryfall-style JSON bytes.
List<int> toJsonBytes(List<Map<String, dynamic>> cards) {
  return utf8.encode(jsonEncode(cards));
}

void main() {
  late CorpusDatabase db;
  late ScryfallParser parser;

  setUp(() {
    db = CorpusDatabase(NativeDatabase.memory());
    parser = ScryfallParser(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Basic insert
  // ---------------------------------------------------------------------------

  group('parseAndInsert', () {
    test('single card inserts 1 row and returns 1', () async {
      final bytes = toJsonBytes([makeScryfallCard(id: 'card-1')]);
      final count = await parser.parseAndInsert(bytes);
      expect(count, 1);
      expect(await db.cardCount(), 1);
    });

    test('three cards insert 3 rows and returns 3', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(id: 'card-1', name: 'Card A'),
        makeScryfallCard(id: 'card-2', name: 'Card B'),
        makeScryfallCard(id: 'card-3', name: 'Card C'),
      ]);
      final count = await parser.parseAndInsert(bytes);
      expect(count, 3);
      expect(await db.cardCount(), 3);
    });

    test('empty array inserts 0 rows and returns 0', () async {
      final bytes = toJsonBytes([]);
      final count = await parser.parseAndInsert(bytes);
      expect(count, 0);
      expect(await db.cardCount(), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Progress callback
  // ---------------------------------------------------------------------------

  group('progress callback', () {
    test('fires with correct count after each batch', () async {
      final progressValues = <int>[];
      final bytes = toJsonBytes([
        makeScryfallCard(id: 'c1'),
        makeScryfallCard(id: 'c2'),
        makeScryfallCard(id: 'c3'),
      ]);
      await parser.parseAndInsert(
        bytes,
        onProgress: (count) => progressValues.add(count),
      );
      // All 3 cards fit in a single batch (batchSize=500), so one callback.
      expect(progressValues, [3]);
    });

    test('does not throw when onProgress is null', () async {
      final bytes = toJsonBytes([makeScryfallCard(id: 'c1')]);
      // Should complete without error.
      await parser.parseAndInsert(bytes);
    });
  });

  // ---------------------------------------------------------------------------
  // Optional / missing fields
  // ---------------------------------------------------------------------------

  group('missing optional fields', () {
    test('handles card with no prices or image_uris', () async {
      final card = makeScryfallCard(id: 'no-extras');
      // Ensure prices and image_uris are absent from the JSON.
      card.remove('prices');
      card.remove('image_uris');

      final bytes = toJsonBytes([card]);
      final count = await parser.parseAndInsert(bytes);
      expect(count, 1);

      final stored = await db.getCard('no-extras');
      expect(stored, isNotNull);
      expect(stored!.priceUsd, isNull);
      expect(stored.imageUriSmall, isNull);
      expect(stored.imageUriNormal, isNull);
    });

    test('handles card with all fields populated', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(
          id: 'full-card',
          name: 'Ancestral Recall',
          manaCost: '{U}',
          cmc: 1,
          typeLine: 'Instant',
          oracleText: 'Draw three cards.',
          colors: ['U'],
          colorIdentity: ['U'],
          set_: 'lea',
          setName: 'Limited Edition Alpha',
          collectorNumber: '210',
          rarity: 'rare',
          finishes: ['nonfoil', 'foil'],
          prices: {
            'usd': '5000.00',
            'usd_foil': '10000.00',
            'usd_etched': null,
            'eur': '4500.00',
            'eur_foil': '9000.00',
          },
          imageUris: {
            'small': 'https://img.scryfall.com/small.jpg',
            'normal': 'https://img.scryfall.com/normal.jpg',
          },
          fullArt: false,
          promo: true,
          frameEffects: ['legendary'],
          securityStamp: 'oval',
          layout: 'normal',
          releasedAt: '1993-08-05',
        ),
      ]);

      final count = await parser.parseAndInsert(bytes);
      expect(count, 1);

      final stored = await db.getCard('full-card');
      expect(stored, isNotNull);
      expect(stored!.name, 'Ancestral Recall');
      expect(stored.priceUsd, 5000.0);
      expect(stored.priceUsdFoil, 10000.0);
      expect(stored.priceUsdEtched, isNull);
      expect(stored.priceEur, 4500.0);
      expect(stored.priceEurFoil, 9000.0);
      expect(stored.imageUriSmall, 'https://img.scryfall.com/small.jpg');
      expect(stored.imageUriNormal, 'https://img.scryfall.com/normal.jpg');
      expect(stored.isPromo, true);
      expect(stored.frameEffects, 'legendary');
      expect(stored.securityStamp, 'oval');
    });
  });

  // ---------------------------------------------------------------------------
  // Price parsing
  // ---------------------------------------------------------------------------

  group('price parsing', () {
    test('string "12.34" is parsed to double 12.34', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(
          id: 'price-card',
          prices: {'usd': '12.34'},
        ),
      ]);
      await parser.parseAndInsert(bytes);
      final card = await db.getCard('price-card');
      expect(card!.priceUsd, 12.34);
    });

    test('null prices remain null', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(
          id: 'null-price',
          prices: {'usd': null, 'usd_foil': null},
        ),
      ]);
      await parser.parseAndInsert(bytes);
      final card = await db.getCard('null-price');
      expect(card!.priceUsd, isNull);
      expect(card.priceUsdFoil, isNull);
    });

    test('string "0.01" is parsed correctly (small price)', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(
          id: 'cheap-card',
          prices: {'usd': '0.01'},
        ),
      ]);
      await parser.parseAndInsert(bytes);
      final card = await db.getCard('cheap-card');
      expect(card!.priceUsd, 0.01);
    });
  });

  // ---------------------------------------------------------------------------
  // Multi-value field joining
  // ---------------------------------------------------------------------------

  group('multi-value field joining', () {
    test('colors ["W","U","B"] becomes "W,U,B"', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(
          id: 'multi-color',
          colors: ['W', 'U', 'B'],
        ),
      ]);
      await parser.parseAndInsert(bytes);
      final card = await db.getCard('multi-color');
      expect(card!.colors, 'W,U,B');
    });

    test('empty colors list becomes empty string', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(id: 'colorless', colors: []),
      ]);
      await parser.parseAndInsert(bytes);
      final card = await db.getCard('colorless');
      expect(card!.colors, '');
    });

    test('null colors (omitted) becomes null', () async {
      final cardJson = makeScryfallCard(id: 'no-colors');
      cardJson.remove('colors');
      final bytes = toJsonBytes([cardJson]);
      await parser.parseAndInsert(bytes);
      final card = await db.getCard('no-colors');
      expect(card!.colors, isNull);
    });

    test('finishes ["nonfoil","foil"] becomes "nonfoil,foil"', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(
          id: 'dual-finish',
          finishes: ['nonfoil', 'foil'],
        ),
      ]);
      await parser.parseAndInsert(bytes);
      final card = await db.getCard('dual-finish');
      expect(card!.finishes, 'nonfoil,foil');
    });
  });

  // ---------------------------------------------------------------------------
  // Batch processing
  // ---------------------------------------------------------------------------

  group('batch processing', () {
    test('500 cards process in 1 batch (single progress callback)', () async {
      final cards = List.generate(
        500,
        (i) => makeScryfallCard(id: 'batch-$i', name: 'Card $i'),
      );
      final progressValues = <int>[];
      await parser.parseAndInsert(
        toJsonBytes(cards),
        onProgress: (count) => progressValues.add(count),
      );
      expect(progressValues, [500]);
      expect(await db.cardCount(), 500);
    });

    test('501 cards process in 2 batches (two progress callbacks)', () async {
      final cards = List.generate(
        501,
        (i) => makeScryfallCard(id: 'batch-$i', name: 'Card $i'),
      );
      final progressValues = <int>[];
      await parser.parseAndInsert(
        toJsonBytes(cards),
        onProgress: (count) => progressValues.add(count),
      );
      expect(progressValues, [500, 501]);
      expect(await db.cardCount(), 501);
    });

    test('1000 cards process in 2 batches', () async {
      final cards = List.generate(
        1000,
        (i) => makeScryfallCard(id: 'batch-$i', name: 'Card $i'),
      );
      final progressValues = <int>[];
      await parser.parseAndInsert(
        toJsonBytes(cards),
        onProgress: (count) => progressValues.add(count),
      );
      expect(progressValues, [500, 1000]);
      expect(await db.cardCount(), 1000);
    });
  });

  // ---------------------------------------------------------------------------
  // Upsert / duplicate handling
  // ---------------------------------------------------------------------------

  group('duplicate handling', () {
    test('cards with duplicate scryfallId are upserted (last wins)', () async {
      final bytes = toJsonBytes([
        makeScryfallCard(id: 'dup-id', name: 'First Version'),
        makeScryfallCard(id: 'dup-id', name: 'Second Version'),
      ]);
      await parser.parseAndInsert(bytes);
      expect(await db.cardCount(), 1);
      final card = await db.getCard('dup-id');
      expect(card!.name, 'Second Version');
    });
  });
}

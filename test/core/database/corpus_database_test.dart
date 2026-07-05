import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';

/// Creates a [CardsCompanion] with sensible defaults so tests only need to
/// specify the fields they care about.
CardsCompanion makeTestCard({
  required String scryfallId,
  String oracleId = 'oracle-000',
  String name = 'Test Card',
  String? manaCost = '{1}{R}',
  double cmc = 1.0,
  String typeLine = 'Creature',
  String? oracleText,
  String? colors = 'R',
  String colorIdentity = 'R',
  String setCode = 'tst',
  String setName = 'Test Set',
  String collectorNumber = '1',
  String rarity = 'common',
  String finishes = 'nonfoil',
  double? priceUsd,
  double? priceUsdFoil,
  double? priceUsdEtched,
  double? priceEur,
  double? priceEurFoil,
  String? imageUriSmall,
  String? imageUriNormal,
  bool isFullart = false,
  bool isPromo = false,
  String? frameEffects,
  String? securityStamp,
  String layout = 'normal',
  String releasedAt = '2023-01-01',
}) {
  return CardsCompanion(
    scryfallId: Value(scryfallId),
    oracleId: Value(oracleId),
    name: Value(name),
    manaCost: Value(manaCost),
    cmc: Value(cmc),
    typeLine: Value(typeLine),
    oracleText: Value(oracleText),
    colors: Value(colors),
    colorIdentity: Value(colorIdentity),
    setCode: Value(setCode),
    setName: Value(setName),
    collectorNumber: Value(collectorNumber),
    rarity: Value(rarity),
    finishes: Value(finishes),
    priceUsd: Value(priceUsd),
    priceUsdFoil: Value(priceUsdFoil),
    priceUsdEtched: Value(priceUsdEtched),
    priceEur: Value(priceEur),
    priceEurFoil: Value(priceEurFoil),
    imageUriSmall: Value(imageUriSmall),
    imageUriNormal: Value(imageUriNormal),
    isFullart: Value(isFullart),
    isPromo: Value(isPromo),
    frameEffects: Value(frameEffects),
    securityStamp: Value(securityStamp),
    layout: Value(layout),
    releasedAt: Value(releasedAt),
  );
}

void main() {
  late CorpusDatabase db;

  setUp(() {
    db = CorpusDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // cardCount / insert basics
  // ---------------------------------------------------------------------------

  group('cardCount', () {
    test('empty database has cardCount == 0', () async {
      expect(await db.cardCount(), 0);
    });

    test('inserting one card yields cardCount == 1', () async {
      await db.into(db.cards).insert(makeTestCard(scryfallId: 'card-1'));
      expect(await db.cardCount(), 1);
    });

    test('inserting multiple cards yields correct count', () async {
      await db.into(db.cards).insert(makeTestCard(scryfallId: 'card-1'));
      await db.into(db.cards).insert(makeTestCard(scryfallId: 'card-2'));
      await db.into(db.cards).insert(makeTestCard(scryfallId: 'card-3'));
      expect(await db.cardCount(), 3);
    });
  });

  // ---------------------------------------------------------------------------
  // clearAllCards
  // ---------------------------------------------------------------------------

  group('clearAllCards', () {
    test('deletes all rows and count returns 0', () async {
      await db.into(db.cards).insert(makeTestCard(scryfallId: 'card-1'));
      await db.into(db.cards).insert(makeTestCard(scryfallId: 'card-2'));
      expect(await db.cardCount(), 2);

      await db.clearAllCards();
      expect(await db.cardCount(), 0);
    });

    test('clearing an already empty database is a no-op', () async {
      await db.clearAllCards();
      expect(await db.cardCount(), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // searchByName
  // ---------------------------------------------------------------------------

  group('searchByName', () {
    setUp(() async {
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'bolt-1',
            name: 'Lightning Bolt',
          ));
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'helix-1',
            name: 'Lightning Helix',
          ));
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'recall-1',
            name: 'Ancestral Recall',
          ));
    });

    test('finds cards by partial name match', () async {
      final results = await db.searchByName('Lightning');
      expect(results, hasLength(2));
      expect(results.map((c) => c.name),
          containsAll(['Lightning Bolt', 'Lightning Helix']));
    });

    test('returns empty list when no cards match', () async {
      final results = await db.searchByName('Counterspell');
      expect(results, isEmpty);
    });

    test('LIKE match is case-insensitive (SQLite default)', () async {
      // SQLite LIKE is case-insensitive for ASCII letters by default.
      final results = await db.searchByName('lightning');
      expect(results, hasLength(2));
    });

    test('respects the limit parameter', () async {
      final results = await db.searchByName('Lightning', limit: 1);
      expect(results, hasLength(1));
    });

    test('matches substring anywhere in the name', () async {
      final results = await db.searchByName('Bolt');
      expect(results, hasLength(1));
      expect(results.first.name, 'Lightning Bolt');
    });
  });

  // ---------------------------------------------------------------------------
  // searchBySet
  // ---------------------------------------------------------------------------

  group('searchBySet', () {
    setUp(() async {
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'a-1',
            name: 'Card A',
            setCode: 'lea',
          ));
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'b-1',
            name: 'Card B',
            setCode: 'lea',
          ));
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'c-1',
            name: 'Card C',
            setCode: 'arn',
          ));
    });

    test('returns only cards from the specified set', () async {
      final results = await db.searchBySet('lea');
      expect(results, hasLength(2));
      for (final card in results) {
        expect(card.setCode, 'lea');
      }
    });

    test('returns empty list for a set with no cards', () async {
      final results = await db.searchBySet('xxx');
      expect(results, isEmpty);
    });

    test('is case-insensitive (lowercases input)', () async {
      final results = await db.searchBySet('LEA');
      expect(results, hasLength(2));
    });

    test('respects the limit parameter', () async {
      final results = await db.searchBySet('lea', limit: 1);
      expect(results, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // getCard
  // ---------------------------------------------------------------------------

  group('getCard', () {
    test('returns the correct card by scryfallId', () async {
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'unique-id',
            name: 'Unique Card',
          ));
      final card = await db.getCard('unique-id');
      expect(card, isNotNull);
      expect(card!.name, 'Unique Card');
      expect(card.scryfallId, 'unique-id');
    });

    test('returns null for non-existent scryfallId', () async {
      final card = await db.getCard('does-not-exist');
      expect(card, isNull);
    });

    test('returns null in an empty database', () async {
      final card = await db.getCard('any-id');
      expect(card, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Upsert behavior
  // ---------------------------------------------------------------------------

  group('upsert', () {
    test('inserting a card with the same scryfallId replaces the old row',
        () async {
      await db.into(db.cards).insertOnConflictUpdate(makeTestCard(
            scryfallId: 'dup-id',
            name: 'Original Name',
            priceUsd: 1.0,
          ));

      await db.into(db.cards).insertOnConflictUpdate(makeTestCard(
            scryfallId: 'dup-id',
            name: 'Updated Name',
            priceUsd: 5.0,
          ));

      expect(await db.cardCount(), 1);
      final card = await db.getCard('dup-id');
      expect(card!.name, 'Updated Name');
      expect(card.priceUsd, 5.0);
    });
  });

  // ---------------------------------------------------------------------------
  // corpus_meta (v3)
  // ---------------------------------------------------------------------------

  group('corpus meta', () {
    test('getMeta returns null for unset keys', () async {
      expect(await db.getMeta('nope'), isNull);
    });

    test('setMeta round-trips and upserts', () async {
      await db.setMeta('k', 'v1');
      expect(await db.getMeta('k'), 'v1');

      await db.setMeta('k', 'v2');
      expect(await db.getMeta('k'), 'v2');
    });

    test('lastImportedAt parses the stored timestamp', () async {
      expect(await db.lastImportedAt(), isNull);

      final stamp = DateTime.utc(2026, 7, 4, 12, 30);
      await db.setMeta(CorpusDatabase.metaImportedAt,
          stamp.toIso8601String());

      expect(await db.lastImportedAt(), stamp);
    });

    test('lastImportedAt survives clearAllCards (refresh wipes cards only)',
        () async {
      await db.into(db.cards).insert(makeTestCard(scryfallId: 'card-1'));
      await db.setMeta(CorpusDatabase.metaImportedAt,
          DateTime.utc(2026, 7, 4).toIso8601String());

      await db.clearAllCards();

      expect(await db.lastImportedAt(), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Field storage
  // ---------------------------------------------------------------------------

  group('field storage', () {
    test('stores and retrieves all fields correctly', () async {
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'full-card',
            oracleId: 'oracle-full',
            name: 'Full Card',
            manaCost: '{2}{U}{U}',
            cmc: 4.0,
            typeLine: 'Instant',
            oracleText: 'Draw three cards.',
            colors: 'U',
            colorIdentity: 'U',
            setCode: 'lea',
            setName: 'Limited Edition Alpha',
            collectorNumber: '42',
            rarity: 'rare',
            finishes: 'nonfoil,foil',
            priceUsd: 500.0,
            priceUsdFoil: 1500.0,
            imageUriSmall: 'https://example.com/small.jpg',
            imageUriNormal: 'https://example.com/normal.jpg',
            isFullart: true,
            isPromo: false,
            layout: 'normal',
            releasedAt: '1993-08-05',
          ));

      final card = await db.getCard('full-card');
      expect(card, isNotNull);
      expect(card!.oracleId, 'oracle-full');
      expect(card.manaCost, '{2}{U}{U}');
      expect(card.cmc, 4.0);
      expect(card.typeLine, 'Instant');
      expect(card.oracleText, 'Draw three cards.');
      expect(card.colors, 'U');
      expect(card.colorIdentity, 'U');
      expect(card.setCode, 'lea');
      expect(card.setName, 'Limited Edition Alpha');
      expect(card.collectorNumber, '42');
      expect(card.rarity, 'rare');
      expect(card.finishes, 'nonfoil,foil');
      expect(card.priceUsd, 500.0);
      expect(card.priceUsdFoil, 1500.0);
      expect(card.imageUriSmall, 'https://example.com/small.jpg');
      expect(card.imageUriNormal, 'https://example.com/normal.jpg');
      expect(card.isFullart, true);
      expect(card.isPromo, false);
      expect(card.layout, 'normal');
      expect(card.releasedAt, '1993-08-05');
    });

    test('nullable fields default to null when not provided', () async {
      await db.into(db.cards).insert(makeTestCard(
            scryfallId: 'nullable-card',
            manaCost: null,
            oracleText: null,
            colors: null,
            priceUsd: null,
            priceUsdFoil: null,
            priceUsdEtched: null,
            priceEur: null,
            priceEurFoil: null,
            imageUriSmall: null,
            imageUriNormal: null,
            frameEffects: null,
            securityStamp: null,
          ));

      final card = await db.getCard('nullable-card');
      expect(card, isNotNull);
      expect(card!.manaCost, isNull);
      expect(card.oracleText, isNull);
      expect(card.colors, isNull);
      expect(card.priceUsd, isNull);
      expect(card.priceUsdFoil, isNull);
      expect(card.priceUsdEtched, isNull);
      expect(card.priceEur, isNull);
      expect(card.priceEurFoil, isNull);
      expect(card.imageUriSmall, isNull);
      expect(card.imageUriNormal, isNull);
      expect(card.frameEffects, isNull);
      expect(card.securityStamp, isNull);
    });
  });
}

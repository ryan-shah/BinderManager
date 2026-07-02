import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/query/query_engine.dart';

/// Creates a [CardsCompanion] with sensible defaults so tests only need to
/// specify the fields they care about.
CardsCompanion _makeCard({
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
  late QueryEngine engine;

  setUp(() async {
    db = CorpusDatabase(NativeDatabase.memory());
    engine = QueryEngine(db);

    // Insert test cards.
    await db.into(db.cards).insert(_makeCard(
          scryfallId: 'bolt-1',
          name: 'Lightning Bolt',
          typeLine: 'Instant',
          oracleText: 'Lightning Bolt deals 3 damage to any target.',
          colors: 'R',
          colorIdentity: 'R',
          setCode: 'lea',
          rarity: 'common',
          priceUsd: 2.50,
        ));
    await db.into(db.cards).insert(_makeCard(
          scryfallId: 'helix-1',
          name: 'Lightning Helix',
          typeLine: 'Instant',
          oracleText:
              'Lightning Helix deals 3 damage to any target and you gain 3 life.',
          colors: 'R,W',
          colorIdentity: 'R,W',
          setCode: 'rav',
          rarity: 'uncommon',
          priceUsd: 1.00,
        ));
    await db.into(db.cards).insert(_makeCard(
          scryfallId: 'goyf-1',
          name: 'Tarmogoyf',
          typeLine: 'Creature — Lhurgoyf',
          oracleText:
              "Tarmogoyf's power is equal to the number of card types among cards in all graveyards.",
          colors: 'G',
          colorIdentity: 'G',
          setCode: 'mh2',
          rarity: 'mythic',
          priceUsd: 15.00,
        ));
    await db.into(db.cards).insert(_makeCard(
          scryfallId: 'jace-1',
          name: 'Jace, the Mind Sculptor',
          typeLine: 'Legendary Planeswalker — Jace',
          oracleText: 'Draw three cards.',
          colors: 'U',
          colorIdentity: 'U',
          setCode: 'wwk',
          rarity: 'mythic',
          priceUsd: 30.00,
        ));
    await db.into(db.cards).insert(_makeCard(
          scryfallId: 'forest-1',
          name: 'Forest',
          typeLine: 'Basic Land — Forest',
          oracleText: null,
          colors: null,
          colorIdentity: '',
          setCode: 'lea',
          rarity: 'common',
          priceUsd: 0.10,
        ));
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // search() — basic functionality
  // ---------------------------------------------------------------------------

  group('search()', () {
    test('returns matching cards', () async {
      final result = await engine.search('lightning');
      expect(result.isSuccess, isTrue);
      expect(result.cards, hasLength(2));
      expect(result.cards.map((c) => c.name),
          containsAll(['Lightning Bolt', 'Lightning Helix']));
    });

    test('returns totalCount matching all results', () async {
      final result = await engine.search('lightning');
      expect(result.totalCount, equals(2));
    });

    test('empty query returns empty result', () async {
      final result = await engine.search('');
      expect(result.isSuccess, isTrue);
      expect(result.cards, isEmpty);
      expect(result.totalCount, equals(0));
    });

    test('whitespace-only query returns empty result', () async {
      final result = await engine.search('   ');
      expect(result.isSuccess, isTrue);
      expect(result.cards, isEmpty);
    });

    test('no matches returns empty list with totalCount 0', () async {
      final result = await engine.search('counterspell');
      expect(result.isSuccess, isTrue);
      expect(result.cards, isEmpty);
      expect(result.totalCount, equals(0));
    });

    test('invalid query returns error info', () async {
      final result = await engine.search('"unterminated');
      expect(result.isSuccess, isFalse);
      expect(result.parseError, isNotNull);
      expect(result.cards, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // search() — limit and offset
  // ---------------------------------------------------------------------------

  group('search() pagination', () {
    test('limit restricts number of returned cards', () async {
      final result = await engine.search('lightning', limit: 1);
      expect(result.cards, hasLength(1));
      // totalCount still reflects all matches.
      expect(result.totalCount, equals(2));
    });

    test('offset skips cards', () async {
      final all = await engine.search('lightning', limit: 100);
      final page2 = await engine.search('lightning', limit: 1, offset: 1);

      expect(page2.cards, hasLength(1));
      expect(page2.totalCount, equals(2));

      // The card returned with offset should differ from the first.
      expect(page2.cards.first.scryfallId,
          isNot(equals(all.cards.first.scryfallId)));
    });

    test('offset beyond results returns empty list', () async {
      final result = await engine.search('lightning', offset: 100);
      expect(result.cards, isEmpty);
      expect(result.totalCount, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // search() — filter integration
  // ---------------------------------------------------------------------------

  group('search() filters', () {
    test('color filter works end-to-end', () async {
      final result = await engine.search('c:G');
      expect(result.isSuccess, isTrue);
      expect(result.cards.map((c) => c.name), contains('Tarmogoyf'));
    });

    test('type filter works end-to-end', () async {
      final result = await engine.search('t:instant');
      expect(result.isSuccess, isTrue);
      expect(result.cards, hasLength(2));
    });

    test('price filter works end-to-end', () async {
      final result = await engine.search('usd>10');
      expect(result.isSuccess, isTrue);
      expect(result.cards, hasLength(2));
      for (final card in result.cards) {
        expect(card.priceUsd, greaterThan(10.0));
      }
    });

    test('combined filters work end-to-end', () async {
      final result = await engine.search('c:R t:instant');
      expect(result.isSuccess, isTrue);
      expect(result.cards, hasLength(2));
    });

    test('OR filter works end-to-end', () async {
      final result = await engine.search('c:U OR c:G');
      expect(result.isSuccess, isTrue);
      expect(result.cards, hasLength(2));
      expect(result.cards.map((c) => c.name),
          containsAll(['Tarmogoyf', 'Jace, the Mind Sculptor']));
    });
  });

  // ---------------------------------------------------------------------------
  // parse() — standalone parsing
  // ---------------------------------------------------------------------------

  group('parse()', () {
    test('returns AST for valid query', () {
      final result = engine.parse('c:W');
      expect(result.isSuccess, isTrue);
      expect(result.ast, isNotNull);
    });

    test('returns error for invalid query', () {
      final result = engine.parse('"unterminated');
      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
      expect(result.errorPosition, isNotNull);
    });

    test('returns null AST for empty query', () {
      final result = engine.parse('');
      expect(result.isSuccess, isTrue);
      expect(result.ast, isNull);
    });
  });
}

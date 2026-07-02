import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/query/ast.dart';
import 'package:binder_manager/core/query/compiler.dart';
import 'package:binder_manager/core/query/parser.dart';

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
  String? borderColor = 'black',
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
    borderColor: Value(borderColor),
    layout: Value(layout),
    releasedAt: Value(releasedAt),
  );
}

void main() {
  late CorpusDatabase db;
  late QueryCompiler compiler;

  setUp(() async {
    db = CorpusDatabase(NativeDatabase.memory());
    compiler = QueryCompiler(db.cards);

    // Insert a diverse set of test cards.
    await db.into(db.cards).insert(_makeCard(
          scryfallId: 'bolt-1',
          name: 'Lightning Bolt',
          typeLine: 'Instant',
          oracleText: 'Lightning Bolt deals 3 damage to any target.',
          colors: 'R',
          colorIdentity: 'R',
          setCode: 'lea',
          rarity: 'common',
          finishes: 'nonfoil',
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
          finishes: 'nonfoil,foil',
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
          finishes: 'nonfoil,foil,etched',
          priceUsd: 15.00,
          isPromo: false,
          frameEffects: 'showcase',
          securityStamp: 'oval',
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
          finishes: 'nonfoil',
          priceUsd: 30.00,
          isFullart: true,
          securityStamp: 'oval',
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
          finishes: 'nonfoil',
          priceUsd: 0.10,
        ));
    await db.into(db.cards).insert(_makeCard(
          scryfallId: 'sol-ring-1',
          name: 'Sol Ring',
          typeLine: 'Artifact',
          oracleText: '{T}: Add {C}{C}.',
          colors: '',
          colorIdentity: '',
          setCode: 'cmd',
          rarity: 'uncommon',
          finishes: 'nonfoil',
          priceUsd: 3.00,
          borderColor: 'borderless',
        ));
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper to run a compiled query and return matching card names.
  Future<List<String>> _queryNames(QueryNode node) async {
    final expr = compiler.compile(node);
    final results =
        await (db.select(db.cards)..where((_) => expr)).get();
    return results.map((c) => c.name).toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // TextNode
  // ---------------------------------------------------------------------------

  group('TextNode', () {
    test('matches cards by name substring', () async {
      final names = await _queryNames(const TextNode('Lightning'));
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
      expect(names, hasLength(2));
    });

    test('case-insensitive name search', () async {
      final names = await _queryNames(const TextNode('lightning'));
      expect(names, hasLength(2));
    });

    test('no matches returns empty', () async {
      final names = await _queryNames(const TextNode('Counterspell'));
      expect(names, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: colors
  // ---------------------------------------------------------------------------

  group('color filter', () {
    test('c:R matches red cards', () async {
      final names =
          await _queryNames(const FilterNode('c', FilterOp.eq, 'R'));
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
    });

    test('c:WR matches cards with both W and R', () async {
      final names =
          await _queryNames(const FilterNode('c', FilterOp.eq, 'WR'));
      // Only Lightning Helix has both W and R.
      expect(names, equals(['Lightning Helix']));
    });

    test('c:U matches blue cards', () async {
      final names =
          await _queryNames(const FilterNode('c', FilterOp.eq, 'U'));
      expect(names, equals(['Jace, the Mind Sculptor']));
    });

    test('color name "red" expands to R', () async {
      final names =
          await _queryNames(const FilterNode('c', FilterOp.eq, 'red'));
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
    });

    test('c:C matches colorless cards (null and empty colors)', () async {
      final names =
          await _queryNames(const FilterNode('c', FilterOp.eq, 'C'));
      expect(names, containsAll(['Forest', 'Sol Ring']));
      expect(names, isNot(contains('Lightning Bolt')));
    });

    test('c:colorless matches colorless cards', () async {
      final names =
          await _queryNames(const FilterNode('c', FilterOp.eq, 'colorless'));
      expect(names, containsAll(['Forest', 'Sol Ring']));
    });

    test('c:M matches multicolor cards', () async {
      final names =
          await _queryNames(const FilterNode('c', FilterOp.eq, 'M'));
      expect(names, equals(['Lightning Helix']));
    });

    test('c:multicolor matches multicolor cards', () async {
      final names =
          await _queryNames(
              const FilterNode('c', FilterOp.eq, 'multicolor'));
      expect(names, equals(['Lightning Helix']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: color identity
  // ---------------------------------------------------------------------------

  group('color identity filter', () {
    test('id:R matches red identity', () async {
      final names =
          await _queryNames(const FilterNode('id', FilterOp.eq, 'R'));
      // Bolt has identity R; Helix has identity R,W — both contain R.
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: set
  // ---------------------------------------------------------------------------

  group('set filter', () {
    test('s:lea matches Alpha cards', () async {
      final names =
          await _queryNames(const FilterNode('s', FilterOp.eq, 'lea'));
      expect(names, containsAll(['Lightning Bolt', 'Forest']));
    });

    test('s:mh2 matches Modern Horizons 2', () async {
      final names =
          await _queryNames(const FilterNode('s', FilterOp.eq, 'mh2'));
      expect(names, equals(['Tarmogoyf']));
    });

    test('s:lea,mh2 matches cards from either set', () async {
      final names =
          await _queryNames(const FilterNode('s', FilterOp.eq, 'lea,mh2'));
      expect(names, containsAll(['Lightning Bolt', 'Forest', 'Tarmogoyf']));
      expect(names, isNot(contains('Lightning Helix')));
      expect(names, isNot(contains('Sol Ring')));
    });

    test('set filter is case-insensitive', () async {
      final names =
          await _queryNames(const FilterNode('s', FilterOp.eq, 'MH2'));
      expect(names, equals(['Tarmogoyf']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: type
  // ---------------------------------------------------------------------------

  group('type filter', () {
    test('t:creature matches creature cards', () async {
      final names =
          await _queryNames(const FilterNode('t', FilterOp.eq, 'creature'));
      // Only Tarmogoyf has "Creature" in its type line among non-land cards.
      expect(names, contains('Tarmogoyf'));
    });

    test('t:instant matches instants', () async {
      final names =
          await _queryNames(const FilterNode('t', FilterOp.eq, 'instant'));
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
    });

    test('t:"legendary planeswalker" matches with quoted substring', () async {
      final names = await _queryNames(
          const FilterNode('t', FilterOp.eq, 'legendary planeswalker'));
      expect(names, equals(['Jace, the Mind Sculptor']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: oracle text
  // ---------------------------------------------------------------------------

  group('oracle text filter', () {
    test('o:"draw three cards" matches Jace', () async {
      final names = await _queryNames(
          const FilterNode('o', FilterOp.eq, 'draw three cards'));
      expect(names, contains('Jace, the Mind Sculptor'));
    });

    test('o:damage matches cards with "damage" in oracle text', () async {
      final names =
          await _queryNames(const FilterNode('o', FilterOp.eq, 'damage'));
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: rarity
  // ---------------------------------------------------------------------------

  group('rarity filter', () {
    test('r:common matches common cards', () async {
      final names =
          await _queryNames(const FilterNode('r', FilterOp.eq, 'common'));
      expect(names, containsAll(['Lightning Bolt', 'Forest']));
    });

    test('r:mythic matches mythic cards', () async {
      final names =
          await _queryNames(const FilterNode('r', FilterOp.eq, 'mythic'));
      expect(names,
          containsAll(['Tarmogoyf', 'Jace, the Mind Sculptor']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: price
  // ---------------------------------------------------------------------------

  group('price filter', () {
    test('usd>5 matches expensive cards', () async {
      final names =
          await _queryNames(const FilterNode('usd', FilterOp.gt, '5'));
      expect(names,
          containsAll(['Tarmogoyf', 'Jace, the Mind Sculptor']));
      expect(names, isNot(contains('Lightning Bolt')));
    });

    test('usd>=15 matches cards at or above 15', () async {
      final names =
          await _queryNames(const FilterNode('usd', FilterOp.gte, '15'));
      expect(names,
          containsAll(['Tarmogoyf', 'Jace, the Mind Sculptor']));
    });

    test('usd<2 matches cheap cards', () async {
      final names =
          await _queryNames(const FilterNode('usd', FilterOp.lt, '2'));
      expect(names, containsAll(['Lightning Helix', 'Forest']));
    });

    test('usd<=1 matches cards at or below 1', () async {
      final names =
          await _queryNames(const FilterNode('usd', FilterOp.lte, '1'));
      expect(names, containsAll(['Lightning Helix', 'Forest']));
    });

    test('usd:2.5 matches exact price', () async {
      final names =
          await _queryNames(const FilterNode('usd', FilterOp.eq, '2.5'));
      expect(names, equals(['Lightning Bolt']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: is:
  // ---------------------------------------------------------------------------

  group('is: filter', () {
    test('is:foil matches cards with foil finish', () async {
      final names =
          await _queryNames(const FilterNode('is', FilterOp.eq, 'foil'));
      expect(names, containsAll(['Lightning Helix', 'Tarmogoyf']));
      // Must NOT match nonfoil-only cards.
      expect(names, isNot(contains('Lightning Bolt')));
      expect(names, isNot(contains('Jace, the Mind Sculptor')));
    });

    test('is:etched matches cards with etched finish', () async {
      final names =
          await _queryNames(const FilterNode('is', FilterOp.eq, 'etched'));
      expect(names, equals(['Tarmogoyf']));
    });

    test('is:fullart matches full-art cards', () async {
      final names =
          await _queryNames(const FilterNode('is', FilterOp.eq, 'fullart'));
      expect(names, equals(['Jace, the Mind Sculptor']));
    });

    test('is:promo matches promo cards', () async {
      // None of our test cards are promos.
      final names =
          await _queryNames(const FilterNode('is', FilterOp.eq, 'promo'));
      expect(names, isEmpty);
    });

    test('is:borderless matches borderless cards via border_color', () async {
      final names = await _queryNames(
          const FilterNode('is', FilterOp.eq, 'borderless'));
      expect(names, equals(['Sol Ring']));
    });

    test('is:showcase matches showcase cards', () async {
      final names =
          await _queryNames(const FilterNode('is', FilterOp.eq, 'showcase'));
      expect(names, equals(['Tarmogoyf']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: frame
  // ---------------------------------------------------------------------------

  group('frame filter', () {
    test('frame:showcase matches cards with showcase frame', () async {
      final names = await _queryNames(
          const FilterNode('frame', FilterOp.eq, 'showcase'));
      expect(names, equals(['Tarmogoyf']));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: stamp
  // ---------------------------------------------------------------------------

  group('stamp filter', () {
    test('stamp:oval matches cards with oval security stamp', () async {
      final names =
          await _queryNames(const FilterNode('stamp', FilterOp.eq, 'oval'));
      expect(names,
          containsAll(['Tarmogoyf', 'Jace, the Mind Sculptor']));
    });

    test('-stamp:oval includes cards with null security stamp', () async {
      final names = await _queryNames(
          const NotNode(FilterNode('stamp', FilterOp.eq, 'oval')));
      expect(names, containsAll(['Lightning Bolt', 'Forest', 'Sol Ring']));
      expect(names, isNot(contains('Tarmogoyf')));
      expect(names, isNot(contains('Jace, the Mind Sculptor')));
    });
  });

  // ---------------------------------------------------------------------------
  // FilterNode: finish
  // ---------------------------------------------------------------------------

  group('finish filter', () {
    test('finish:foil matches cards with foil finish', () async {
      final names = await _queryNames(
          const FilterNode('finish', FilterOp.eq, 'foil'));
      expect(names, containsAll(['Lightning Helix', 'Tarmogoyf']));
      expect(names, isNot(contains('Lightning Bolt')));
    });

    test('finish:etched matches cards with etched finish', () async {
      final names = await _queryNames(
          const FilterNode('finish', FilterOp.eq, 'etched'));
      expect(names, equals(['Tarmogoyf']));
    });
  });

  // ---------------------------------------------------------------------------
  // Logical operators
  // ---------------------------------------------------------------------------

  group('logical operators', () {
    test('AndNode combines filters', () async {
      final names = await _queryNames(const AndNode([
        FilterNode('c', FilterOp.eq, 'R'),
        FilterNode('t', FilterOp.eq, 'instant'),
      ]));
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
    });

    test('OrNode matches either side', () async {
      final names = await _queryNames(const OrNode(
        FilterNode('c', FilterOp.eq, 'U'),
        FilterNode('c', FilterOp.eq, 'G'),
      ));
      expect(names,
          containsAll(['Jace, the Mind Sculptor', 'Tarmogoyf']));
    });

    test('NotNode excludes matching cards', () async {
      final names = await _queryNames(
          const NotNode(FilterNode('c', FilterOp.eq, 'R')));
      expect(names, isNot(contains('Lightning Bolt')));
      expect(names, isNot(contains('Lightning Helix')));
      // Should contain non-red cards.
      expect(names, containsAll(['Tarmogoyf', 'Jace, the Mind Sculptor']));
    });
  });

  // ---------------------------------------------------------------------------
  // Integration: parse -> compile -> execute
  // ---------------------------------------------------------------------------

  group('integration: parse -> compile -> execute', () {
    test('c:W t:creature usd>1 finds no matches in test data', () async {
      // No white creatures above $1 in our test data.
      final ast = parseQuery('c:W t:creature usd>1').ast!;
      final names = await _queryNames(ast);
      expect(names, isEmpty);
    });

    test('c:R t:instant finds red instants', () async {
      final ast = parseQuery('c:R t:instant').ast!;
      final names = await _queryNames(ast);
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
    });

    test('r:mythic usd>20 finds expensive mythics', () async {
      final ast = parseQuery('r:mythic usd>20').ast!;
      final names = await _queryNames(ast);
      expect(names, equals(['Jace, the Mind Sculptor']));
    });

    test('t:instant OR t:planeswalker', () async {
      final ast = parseQuery('t:instant OR t:planeswalker').ast!;
      final names = await _queryNames(ast);
      expect(names,
          containsAll(['Lightning Bolt', 'Lightning Helix', 'Jace, the Mind Sculptor']));
    });

    test('-c:R r:common finds non-red commons', () async {
      final ast = parseQuery('-c:R r:common').ast!;
      final names = await _queryNames(ast);
      expect(names, equals(['Forest']));
    });

    test('(t:instant OR t:creature) c:R finds red instants and creatures',
        () async {
      final ast = parseQuery('(t:instant OR t:creature) c:R').ast!;
      final names = await _queryNames(ast);
      expect(names, containsAll(['Lightning Bolt', 'Lightning Helix']));
      expect(names, isNot(contains('Tarmogoyf')));
    });

    test('unused:true matches nothing until the user DB exists', () async {
      final ast = parseQuery('unused:true').ast!;
      final names = await _queryNames(ast);
      expect(names, isEmpty);
    });

    test('have:true matches nothing until the user DB exists', () async {
      final ast = parseQuery('have:true').ast!;
      final names = await _queryNames(ast);
      expect(names, isEmpty);
    });

    test('c:R unused:true matches nothing (empty collection)', () async {
      final ast = parseQuery('c:R unused:true').ast!;
      final names = await _queryNames(ast);
      expect(names, isEmpty);
    });

    test('-have:true matches everything (nothing is owned)', () async {
      final ast = parseQuery('-have:true').ast!;
      final names = await _queryNames(ast);
      expect(names.length, 6);
    });
  });
}

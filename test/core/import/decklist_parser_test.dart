import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/import/decklist_parser.dart';

CardsCompanion makeCard({
  required String id,
  required String name,
  String setCode = 'm10',
  String collectorNumber = '146',
  double? priceUsd,
  String layout = 'normal',
}) {
  return CardsCompanion.insert(
    scryfallId: id,
    oracleId: 'oracle-$id',
    name: name,
    cmc: 1,
    typeLine: 'Instant',
    colorIdentity: 'R',
    setCode: setCode,
    setName: 'Set $setCode',
    collectorNumber: collectorNumber,
    rarity: 'common',
    finishes: 'nonfoil,foil',
    layout: layout,
    releasedAt: '2020-01-01',
    priceUsd: Value(priceUsd),
  );
}

void main() {
  group('DecklistParser.tokenize', () {
    test('parses "4 Name" and "4x Name"', () {
      final lines = DecklistParser.tokenize('4 Lightning Bolt\n4x Opt');

      expect(lines, hasLength(2));
      expect(lines[0].quantity, 4);
      expect(lines[0].name, 'Lightning Bolt');
      expect(lines[0].setCode, isNull);
      expect(lines[0].collectorNumber, isNull);
      expect(lines[0].section, DeckSection.main);
      expect(lines[0].lineNumber, 1);
      expect(lines[1].quantity, 4);
      expect(lines[1].name, 'Opt');
      expect(lines[1].lineNumber, 2);
    });

    test('parses "(SET) collector" suffix', () {
      final lines = DecklistParser.tokenize('4 Lightning Bolt (M10) 146');

      expect(lines.single.name, 'Lightning Bolt');
      expect(lines.single.setCode, 'M10');
      expect(lines.single.collectorNumber, '146');
    });

    test('parses "(SET)" without a collector number', () {
      final lines = DecklistParser.tokenize('4 Lightning Bolt (M10)');

      expect(lines.single.setCode, 'M10');
      expect(lines.single.collectorNumber, isNull);
    });

    test('sideboard via header, with and without colon', () {
      for (final header in ['Sideboard', 'Sideboard:', 'Side:', 'SIDEBOARD']) {
        final lines =
            DecklistParser.tokenize('4 Lightning Bolt\n$header\n2 Duress');
        expect(lines[0].section, DeckSection.main, reason: header);
        expect(lines[1].section, DeckSection.sideboard, reason: header);
      }
    });

    test('sideboard via MTGO SB: prefix marks only that line', () {
      final lines = DecklistParser.tokenize(
        '4 Lightning Bolt\nSB: 2 Duress\n3 Opt',
      );

      expect(lines[0].section, DeckSection.main);
      expect(lines[1].section, DeckSection.sideboard);
      expect(lines[1].name, 'Duress');
      expect(lines[2].section, DeckSection.main);
    });

    test('blank line switches to sideboard when no headers exist', () {
      final lines = DecklistParser.tokenize(
        '4 Lightning Bolt\n\n2 Duress\n\n3 Opt',
      );

      expect(lines[0].section, DeckSection.main);
      expect(lines[1].section, DeckSection.sideboard);
      // Subsequent blanks are ignored — no further section changes.
      expect(lines[2].section, DeckSection.sideboard);
    });

    test('blank line does NOT switch when the text has headers', () {
      final lines = DecklistParser.tokenize(
        '4 Lightning Bolt\n\n4 Opt\nSideboard\n2 Duress',
      );

      expect(lines[0].section, DeckSection.main);
      expect(lines[1].section, DeckSection.main);
      expect(lines[2].section, DeckSection.sideboard);
    });

    test('leading blank lines never switch sections', () {
      final lines = DecklistParser.tokenize('\n\n4 Lightning Bolt\n\n2 Opt');

      expect(lines[0].section, DeckSection.main);
      expect(lines[1].section, DeckSection.sideboard);
    });

    test('maybeboard headers', () {
      for (final header in ['Maybeboard', 'Maybeboard:', 'Considering']) {
        final lines =
            DecklistParser.tokenize('4 Lightning Bolt\n$header\n1 Opt');
        expect(lines[1].section, DeckSection.maybeboard, reason: header);
      }
    });

    test('Deck, Mainboard, and Commander headers map to main', () {
      final lines = DecklistParser.tokenize(
        'Commander\n1 Krenko, Mob Boss\nDeck\n4 Lightning Bolt\n'
        'Sideboard\n2 Duress\nMainboard\n3 Opt',
      );

      expect(lines[0].section, DeckSection.main);
      expect(lines[1].section, DeckSection.main);
      expect(lines[2].section, DeckSection.sideboard);
      expect(lines[3].section, DeckSection.main);
    });

    test('strips Moxfield *F* and *E* finish markers', () {
      final lines = DecklistParser.tokenize(
        '4 Lightning Bolt (M10) 146 *F*\n2 Opt *E*',
      );

      expect(lines[0].name, 'Lightning Bolt');
      expect(lines[0].collectorNumber, '146');
      expect(lines[1].name, 'Opt');
    });

    test('drops unparseable lines', () {
      final lines = DecklistParser.tokenize(
        '4 Lightning Bolt\nnot a card line\n2 Opt',
      );

      expect(lines, hasLength(2));
      expect(lines[1].name, 'Opt');
      expect(lines[1].lineNumber, 3);
    });
  });

  group('DecklistParser.parse', () {
    late CorpusDatabase corpus;
    late DecklistParser parser;

    setUp(() async {
      corpus = CorpusDatabase(NativeDatabase.memory());
      parser = DecklistParser(corpus);

      await corpus.batch((b) {
        b.insertAll(corpus.cards, [
          makeCard(
            id: 'bolt-m10',
            name: 'Lightning Bolt',
            setCode: 'm10',
            collectorNumber: '146',
            priceUsd: 3.0,
          ),
          makeCard(
            id: 'bolt-2x2',
            name: 'Lightning Bolt',
            setCode: '2x2',
            collectorNumber: '117',
            priceUsd: 1.0,
          ),
          makeCard(
            id: 'opt-xln',
            name: 'Opt',
            setCode: 'xln',
            collectorNumber: '65',
            priceUsd: 0.2,
          ),
          makeCard(
            id: 'fable-neo',
            name: 'Fable of the Mirror-Breaker // Reflection of Kiki-Jiki',
            setCode: 'neo',
            collectorNumber: '141',
            priceUsd: 15.0,
            layout: 'transform',
          ),
        ]);
      });
    });

    tearDown(() async {
      await corpus.close();
    });

    test('(SET) collector resolves to the exact printing', () async {
      final result = await parser.parse('4 Lightning Bolt (2X2) 117');

      final resolution = result.lines.single.resolution;
      expect(resolution, isA<ResolvedExact>());
      expect((resolution as ResolvedExact).card.scryfallId, 'bolt-2x2');
      expect(result.needsFidelityChoice, isFalse);
    });

    test('(SET) with wrong collector falls back to set+name', () async {
      final result = await parser.parse('4 Lightning Bolt (M10) 999');

      final resolution = result.lines.single.resolution;
      expect(resolution, isA<ResolvedExact>());
      expect((resolution as ResolvedExact).card.scryfallId, 'bolt-m10');
    });

    test('(SET) without collector resolves via set+name', () async {
      final result = await parser.parse('4 Lightning Bolt (M10)');

      final resolution = result.lines.single.resolution;
      expect(resolution, isA<ResolvedExact>());
      expect((resolution as ResolvedExact).card.scryfallId, 'bolt-m10');
    });

    test('unknown set is unresolved', () async {
      final result = await parser.parse('4 Lightning Bolt (ZZZ) 1');

      expect(result.lines.single.resolution, isA<Unresolved>());
    });

    test('name-only with a single printing resolves exactly', () async {
      final result = await parser.parse('3 Opt');

      final resolution = result.lines.single.resolution;
      expect(resolution, isA<ResolvedExact>());
      expect((resolution as ResolvedExact).card.scryfallId, 'opt-xln');
    });

    test('name matching is case-insensitive', () async {
      final result = await parser.parse('3 oPt');

      expect(result.lines.single.resolution, isA<ResolvedExact>());
    });

    test('name-only with multiple printings yields candidates', () async {
      final result = await parser.parse('4 Lightning Bolt');

      final resolution = result.lines.single.resolution;
      expect(resolution, isA<ResolvedByName>());
      final candidates = (resolution as ResolvedByName).candidates;
      expect(candidates, hasLength(2));
      expect(
        candidates.map((c) => c.scryfallId),
        containsAll(['bolt-m10', 'bolt-2x2']),
      );
      expect(result.needsFidelityChoice, isTrue);
    });

    test('DFC resolves by its front face name', () async {
      final result = await parser.parse('2 Fable of the Mirror-Breaker');

      final resolution = result.lines.single.resolution;
      expect(resolution, isA<ResolvedExact>());
      expect((resolution as ResolvedExact).card.scryfallId, 'fable-neo');
    });

    test('unknown name is unresolved', () async {
      final result = await parser.parse('4 Storm Crow Supreme');

      expect(result.lines.single.resolution, isA<Unresolved>());
      expect(result.needsFidelityChoice, isFalse);
    });

    test('error lines carry their line numbers', () async {
      final result = await parser.parse(
        '4 Lightning Bolt (2X2) 117\ngibberish here\n???\n3 Opt',
      );

      expect(result.lines, hasLength(2));
      expect(result.errors, hasLength(2));
      expect(result.errors[0].lineNumber, 2);
      expect(result.errors[1].lineNumber, 3);
      expect(result.errors[0].message, contains('gibberish'));
    });

    test('zero quantity is an error, not a line', () async {
      final result = await parser.parse('0 Opt');

      expect(result.lines, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.lineNumber, 1);
    });

    test('sections survive resolution', () async {
      final result = await parser.parse(
        'Deck\n4 Lightning Bolt (M10) 146\nSideboard\n3 Opt',
      );

      expect(result.lines[0].raw.section, DeckSection.main);
      expect(result.lines[1].raw.section, DeckSection.sideboard);
    });
  });
}

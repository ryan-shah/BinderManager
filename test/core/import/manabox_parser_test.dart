import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/import/manabox_parser.dart';
import 'package:binder_manager/core/models/card_identity.dart';

const boltId = '11111111-1111-1111-1111-111111111111';
const helixId = '22222222-2222-2222-2222-222222222222';
const goyfId = '33333333-3333-3333-3333-333333333333';
const borrowId = '44444444-4444-4444-4444-444444444444';
const unknownId = '99999999-9999-9999-9999-999999999999';

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
    layout: Value(layout),
    releasedAt: Value(releasedAt),
  );
}

const _header =
    'Name,Set code,Set name,Collector number,Foil,Rarity,Quantity,'
    'ManaBox ID,Scryfall ID,Purchase price,Misprint,Altered,Condition,'
    'Language,Purchase price currency';

/// Builds a full 15-column ManaBox data row with defaults.
String _row({
  String name = 'Lightning Bolt',
  String setCode = 'lea',
  String setName = 'Limited Edition Alpha',
  String collectorNumber = '161',
  String foil = 'normal',
  String rarity = 'common',
  String quantity = '1',
  String manaBoxId = '10001',
  String scryfallId = boltId,
  String purchasePrice = '1.50',
  String condition = 'near_mint',
  String language = 'en',
}) {
  return '$name,$setCode,$setName,$collectorNumber,$foil,$rarity,$quantity,'
      '$manaBoxId,$scryfallId,$purchasePrice,false,false,$condition,'
      '$language,USD';
}

void main() {
  late CorpusDatabase db;
  late ManaBoxParser parser;

  setUp(() async {
    db = CorpusDatabase(NativeDatabase.memory());
    parser = ManaBoxParser(db);

    await db.batch((b) {
      b.insertAll(db.cards, [
        _makeCard(
          scryfallId: boltId,
          name: 'Lightning Bolt',
          typeLine: 'Instant',
          setCode: 'lea',
          collectorNumber: '161',
          finishes: 'nonfoil',
          priceUsd: 2.50,
        ),
        _makeCard(
          scryfallId: helixId,
          name: 'Lightning Helix',
          typeLine: 'Instant',
          setCode: 'rav',
          collectorNumber: '213',
          finishes: 'nonfoil,foil',
          priceUsd: 1.00,
        ),
        _makeCard(
          scryfallId: goyfId,
          name: 'Tarmogoyf',
          typeLine: 'Creature — Lhurgoyf',
          setCode: 'mh2',
          collectorNumber: '204',
          finishes: 'nonfoil,foil,etched',
          priceUsd: 15.00,
        ),
        _makeCard(
          scryfallId: borrowId,
          name: 'Borrowing 100,000 Arrows',
          typeLine: 'Sorcery',
          setCode: 'c13',
          collectorNumber: '32',
          finishes: 'nonfoil',
          priceUsd: 0.10,
        ),
      ]);
    });
  });

  tearDown(() async {
    await db.close();
  });

  MatchedStackRow matchedFor(ManaBoxParseResult result, CardIdentity id) {
    return result.matched.singleWhere((m) => m.identity == id);
  }

  group('ManaBoxParser — fixture file', () {
    late ManaBoxParseResult result;

    setUp(() async {
      final bytes =
          await File('test/fixtures/manabox_sample.csv').readAsBytes();
      result = await parser.parseBytes(Uint8List.fromList(bytes));
    });

    test('counts all data rows', () {
      expect(result.totalDataRows, 10);
    });

    test('matches valid rows and merges duplicates', () {
      expect(result.matched, hasLength(4));

      final bolt =
          matchedFor(result, const CardIdentity(boltId, Finish.nonfoil));
      // Rows 2 (qty 3, NM, en) and 9 (qty 2, LP, ja) merge.
      expect(bolt.quantity, 5);
      expect(bolt.condition, 'near_mint');
      expect(bolt.language, 'en');
      expect(bolt.corpusCard.name, 'Lightning Bolt');

      final helix =
          matchedFor(result, const CardIdentity(helixId, Finish.foil));
      expect(helix.quantity, 1);
      expect(helix.condition, 'good');

      final goyf =
          matchedFor(result, const CardIdentity(goyfId, Finish.etched));
      expect(goyf.quantity, 2);
    });

    test('parses quoted names containing commas', () {
      final borrow =
          matchedFor(result, const CardIdentity(borrowId, Finish.nonfoil));
      expect(borrow.quantity, 1);
      expect(borrow.corpusCard.name, 'Borrowing 100,000 Arrows');
      // Empty condition cell becomes null.
      expect(borrow.condition, isNull);
    });

    test('queues unmatched rows with the right reasons, in file order', () {
      expect(result.unmatched, hasLength(5));
      expect(
        result.unmatched.map((u) => u.reason).toList(),
        [
          UnmatchReason.unknownScryfallId,
          UnmatchReason.missingScryfallId,
          UnmatchReason.finishUnavailable,
          UnmatchReason.invalidQuantity,
          UnmatchReason.invalidFinish,
        ],
      );
      expect(
        result.unmatched.map((u) => u.lineNumber).toList(),
        [6, 7, 8, 10, 11],
      );
    });

    test('unmatched rows keep raw cell values keyed by header', () {
      final missing = result.unmatched
          .singleWhere((u) => u.reason == UnmatchReason.missingScryfallId);
      expect(missing.raw['Name'], 'No ID Card');
      expect(missing.raw['Scryfall ID'], '');
      expect(missing.ignored, isFalse);
    });

    test('resolvable unmatched rows carry a resolved identity', () {
      final unknown = result.unmatched
          .singleWhere((u) => u.reason == UnmatchReason.unknownScryfallId);
      expect(unknown.resolvedIdentity,
          const CardIdentity(unknownId, Finish.nonfoil));

      final unavailable = result.unmatched
          .singleWhere((u) => u.reason == UnmatchReason.finishUnavailable);
      expect(unavailable.resolvedIdentity,
          const CardIdentity(helixId, Finish.etched));

      final noId = result.unmatched
          .singleWhere((u) => u.reason == UnmatchReason.missingScryfallId);
      expect(noId.resolvedIdentity, isNull);
    });
  });

  group('ManaBoxParser — header handling', () {
    test('locates columns by header name, not position', () async {
      // Shuffled column order relative to the authoritative export.
      final csv = [
        'Scryfall ID,Quantity,Name,Foil,Condition,Language,Set code',
        '$boltId,2,Lightning Bolt,normal,near_mint,en,lea',
        '$helixId,1,Lightning Helix,foil,good,en,rav',
      ].join('\n');

      final result = await parser.parseString(csv);

      expect(result.matched, hasLength(2));
      final bolt =
          matchedFor(result, const CardIdentity(boltId, Finish.nonfoil));
      expect(bolt.quantity, 2);
      expect(bolt.condition, 'near_mint');
    });

    test('header matching is case-insensitive and trimmed', () async {
      final csv = [
        ' SCRYFALL id , QUANTITY , FOIL ',
        '$boltId,1,normal',
      ].join('\n');

      final result = await parser.parseString(csv);
      expect(result.matched, hasLength(1));
    });

    test('strips a UTF-8 BOM and handles CRLF line endings', () async {
      final csv = [_header, _row(quantity: '2')].join('\r\n');
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

      final result = await parser.parseBytes(bytes);

      expect(result.totalDataRows, 1);
      expect(result.matched, hasLength(1));
      expect(result.matched.single.quantity, 2);
    });

    test('throws FormatException when required headers are missing', () async {
      final csv = ['Name,Set code,Quantity', 'Lightning Bolt,lea,1'].join('\n');

      expect(
        () => parser.parseString(csv),
        throwsA(isA<FormatException>()),
      );
    });

    test('returns an empty result for an empty file', () async {
      final result = await parser.parseBytes(Uint8List(0));

      expect(result.totalDataRows, 0);
      expect(result.matched, isEmpty);
      expect(result.unmatched, isEmpty);
    });
  });

  group('ManaBoxParser — finish mapping', () {
    test('maps normal/foil/etched Foil values', () async {
      final csv = [
        _header,
        _row(scryfallId: goyfId, foil: 'normal'),
        _row(scryfallId: goyfId, foil: 'foil'),
        _row(scryfallId: goyfId, foil: 'etched'),
      ].join('\n');

      final result = await parser.parseString(csv);

      expect(result.matched, hasLength(3));
      expect(
        result.matched.map((m) => m.identity.finish).toSet(),
        {Finish.nonfoil, Finish.foil, Finish.etched},
      );
    });

    test('rejects a claimed finish the printing lacks', () async {
      // Helix is nonfoil,foil — etched is unavailable.
      final csv = [
        _header,
        _row(scryfallId: helixId, foil: 'etched'),
      ].join('\n');

      final result = await parser.parseString(csv);

      expect(result.matched, isEmpty);
      expect(result.unmatched.single.reason, UnmatchReason.finishUnavailable);
      expect(result.unmatched.single.resolvedIdentity,
          const CardIdentity(helixId, Finish.etched));
    });

    test('coerces finish when printing only has one available finish', () async {
      // Bolt is nonfoil-only; a foil row should be accepted as nonfoil.
      final csv = [
        _header,
        _row(scryfallId: boltId, foil: 'foil', quantity: '1'),
        _row(scryfallId: boltId, foil: 'normal', quantity: '2'),
      ].join('\n');

      final result = await parser.parseString(csv);

      expect(result.unmatched, isEmpty);
      expect(result.matched, hasLength(1));
      final bolt = result.matched.single;
      expect(bolt.identity, const CardIdentity(boltId, Finish.nonfoil));
      expect(bolt.quantity, 3);
    });

    test('rejects unrecognised Foil values', () async {
      final csv = [_header, _row(foil: 'shiny')].join('\n');

      final result = await parser.parseString(csv);

      expect(result.unmatched.single.reason, UnmatchReason.invalidFinish);
    });
  });

  group('ManaBoxParser — row validation', () {
    test('rejects zero, negative, and non-numeric quantities', () async {
      final csv = [
        _header,
        _row(quantity: '0'),
        _row(quantity: '-3'),
        _row(quantity: 'abc'),
      ].join('\n');

      final result = await parser.parseString(csv);

      expect(result.matched, isEmpty);
      expect(result.unmatched, hasLength(3));
      expect(
        result.unmatched.every(
            (u) => u.reason == UnmatchReason.invalidQuantity),
        isTrue,
      );
    });

    test('rejects rows too short to carry the required cells', () async {
      final csv = [_header, 'Lightning Bolt,lea'].join('\n');

      final result = await parser.parseString(csv);

      expect(result.unmatched.single.reason, UnmatchReason.malformedRow);
    });

    test('skips fully empty rows without counting them', () async {
      final csv = [_header, _row(), '', _row(scryfallId: helixId, foil: 'foil')]
          .join('\n');

      final result = await parser.parseString(csv);

      expect(result.totalDataRows, 2);
      expect(result.matched, hasLength(2));
    });

    test('flags Scryfall IDs absent from the corpus', () async {
      final csv = [_header, _row(scryfallId: unknownId)].join('\n');

      final result = await parser.parseString(csv);

      expect(result.unmatched.single.reason, UnmatchReason.unknownScryfallId);
    });
  });
}

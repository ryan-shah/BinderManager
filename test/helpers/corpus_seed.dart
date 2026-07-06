import 'package:drift/drift.dart';

import 'package:binder_manager/core/database/corpus_database.dart';

/// A [CardsCompanion] with sensible defaults, for seeding in-memory corpus
/// databases in widget tests.
CardsCompanion seedCard({
  required String scryfallId,
  String name = 'Test Card',
  String typeLine = 'Creature',
  String colorIdentity = 'R',
  String setCode = 'tst',
  String rarity = 'common',
  String finishes = 'nonfoil,foil',
  double? priceUsd,
  double? priceUsdFoil,
}) {
  return CardsCompanion(
    scryfallId: Value(scryfallId),
    oracleId: Value('oracle-$scryfallId'),
    name: Value(name),
    cmc: const Value(1.0),
    typeLine: Value(typeLine),
    colorIdentity: Value(colorIdentity),
    setCode: Value(setCode),
    setName: Value('Set $setCode'),
    collectorNumber: const Value('1'),
    rarity: Value(rarity),
    finishes: Value(finishes),
    priceUsd: Value(priceUsd),
    priceUsdFoil: Value(priceUsdFoil),
    isFullart: const Value(false),
    isPromo: const Value(false),
    layout: const Value('normal'),
    releasedAt: const Value('2023-01-01'),
  );
}

Future<void> seedCorpusCards(
  CorpusDatabase corpus,
  List<CardsCompanion> cards,
) {
  return corpus.batch((b) => b.insertAll(corpus.cards, cards));
}

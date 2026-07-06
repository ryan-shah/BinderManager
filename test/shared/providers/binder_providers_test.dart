import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/binders/binder_repository.dart';
import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/shared/providers/binder_providers.dart';
import 'package:binder_manager/shared/providers/change_staging_provider.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';
import 'package:binder_manager/shared/providers/user_database_provider.dart';

final _t = DateTime.utc(2026, 7, 1);

void main() {
  late CorpusDatabase corpus;
  late UserDatabase userDb;
  late ProviderContainer container;
  late BinderRepository repository;

  setUp(() async {
    corpus = CorpusDatabase(NativeDatabase.memory());
    userDb = UserDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      corpusDatabaseProvider.overrideWithValue(corpus),
      userDatabaseProvider.overrideWithValue(userDb),
    ]);
    repository = container.read(binderRepositoryProvider);

    await corpus.into(corpus.cards).insert(CardsCompanion(
          scryfallId: const Value('bolt'),
          oracleId: const Value('oracle-bolt'),
          name: const Value('Lightning Bolt'),
          cmc: const Value(1.0),
          typeLine: const Value('Instant'),
          colorIdentity: const Value('R'),
          setCode: const Value('lea'),
          setName: const Value('Alpha'),
          collectorNumber: const Value('161'),
          rarity: const Value('common'),
          finishes: const Value('nonfoil'),
          priceUsd: const Value(2.0),
          isFullart: const Value(false),
          isPromo: const Value(false),
          layout: const Value('normal'),
          releasedAt: const Value('1993-08-05'),
        ));
    await userDb.into(userDb.stacks).insert(StacksCompanion.insert(
          id: 's1',
          scryfallId: 'bolt',
          finish: Finish.nonfoil,
          quantity: 4,
          provenance: 'test',
          createdAt: _t,
          updatedAt: _t,
        ));
  });

  tearDown(() async {
    container.dispose();
    await corpus.close();
    await userDb.close();
  });

  Future<String> makeBinder({bool isVirtual = false}) {
    return repository.createBinder(
      name: 'Binder',
      query: 't:instant',
      layoutRows: 3,
      layoutCols: 3,
      pageCount: 2,
      doubleSided: false,
      isVirtual: isVirtual,
    );
  }

  test('stage() computes planned placements and stages the diff', () async {
    final binderId = await makeBinder();

    await container
        .read(binderChangeStagerProvider)
        .stage(ChangeTrigger.collectionImport);

    final diff = container.read(changeStagingProvider);
    expect(diff, isNotNull);
    expect(diff!.trigger, ChangeTrigger.collectionImport);
    expect(diff.entries, hasLength(1));
    expect(diff.entries.single.type, DiffType.add);
    expect(diff.entries.single.binderId, binderId);
    expect(diff.entries.single.quantity, 4);
  });

  test('virtual binders never enter the staged diff', () async {
    await makeBinder(isVirtual: true);

    await container
        .read(binderChangeStagerProvider)
        .stage(ChangeTrigger.ruleEdit);

    expect(container.read(changeStagingProvider), isNull);
  });

  test('staging with no binders stages nothing', () async {
    await container
        .read(binderChangeStagerProvider)
        .stage(ChangeTrigger.deckChange);

    expect(container.read(changeStagingProvider), isNull);
  });
}

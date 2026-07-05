import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/binders/binder_repository.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/ordering.dart';

void main() {
  late UserDatabase db;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  var idCounter = 0;
  BinderRepository repo({DateTime Function()? now}) => BinderRepository(
        db,
        newId: () => 'binder-${idCounter++}',
        now: now ?? () => DateTime.utc(2026, 7, 1),
      );

  Future<String> create(
    BinderRepository repository, {
    String name = 'Trade binder',
    String query = 'usd>=5 unused:true',
    BinderAxis? groupBy,
    bool isVirtual = false,
  }) {
    return repository.createBinder(
      name: name,
      query: query,
      layoutRows: 3,
      layoutCols: 3,
      pageCount: 10,
      doubleSided: true,
      groupBy: groupBy,
      isVirtual: isVirtual,
    );
  }

  group('createBinder', () {
    test('persists the full definition with defaults and timestamps',
        () async {
      final repository = repo();
      final id = await create(repository, groupBy: BinderAxis.cardType);

      final binder = await db.select(db.binders).getSingle();
      expect(binder.id, id);
      expect(binder.name, 'Trade binder');
      expect(binder.query, 'usd>=5 unused:true');
      expect(binder.priorityIndex, 0);
      expect(binder.layoutRows, 3);
      expect(binder.layoutCols, 3);
      expect(binder.pageCount, 10);
      expect(binder.doubleSided, isTrue);
      expect(binder.groupBy, BinderAxis.cardType);
      expect(binder.sortBy, BinderAxis.price);
      expect(binder.sortDir, SortDirection.desc);
      expect(binder.isVirtual, isFalse);
      expect(binder.createdAt.toUtc(), DateTime.utc(2026, 7, 1));
      expect(binder.updatedAt.toUtc(), DateTime.utc(2026, 7, 1));
    });

    test('appends to the end of the priority list', () async {
      final repository = repo();
      await create(repository, name: 'First');
      await create(repository, name: 'Second');
      await create(repository, name: 'Third');

      final binders = await repository.listBinders();
      expect(binders.map((b) => b.name), ['First', 'Second', 'Third']);
      expect(binders.map((b) => b.priorityIndex), [0, 1, 2]);
    });

    test('null groupBy means no grouping', () async {
      final repository = repo();
      await create(repository);
      final binder = await db.select(db.binders).getSingle();
      expect(binder.groupBy, isNull);
    });
  });

  group('updateBinder', () {
    test('rewrites the definition and bumps updatedAt', () async {
      var t = DateTime.utc(2026, 7, 1);
      final repository = repo(now: () => t);
      final id = await create(repository, groupBy: BinderAxis.cardType);

      t = DateTime.utc(2026, 7, 2);
      await repository.updateBinder(
        id: id,
        name: 'Showcase',
        query: 'is:fullart',
        layoutRows: 4,
        layoutCols: 4,
        pageCount: 5,
        doubleSided: false,
        groupBy: null,
        sortBy: BinderAxis.name,
        sortDir: SortDirection.asc,
        isVirtual: true,
      );

      final binder = await db.select(db.binders).getSingle();
      expect(binder.name, 'Showcase');
      expect(binder.query, 'is:fullart');
      expect(binder.layoutRows, 4);
      expect(binder.pageCount, 5);
      expect(binder.doubleSided, isFalse);
      expect(binder.groupBy, isNull, reason: 'groupBy null clears grouping');
      expect(binder.sortBy, BinderAxis.name);
      expect(binder.sortDir, SortDirection.asc);
      expect(binder.isVirtual, isTrue);
      expect(binder.createdAt.toUtc(), DateTime.utc(2026, 7, 1));
      expect(binder.updatedAt.toUtc(), DateTime.utc(2026, 7, 2));
    });

    test('does not change the priority index', () async {
      final repository = repo();
      await create(repository, name: 'First');
      final id = await create(repository, name: 'Second');

      await repository.updateBinder(
        id: id,
        name: 'Second v2',
        query: '',
        layoutRows: 2,
        layoutCols: 2,
        pageCount: 1,
        doubleSided: true,
        groupBy: null,
        sortBy: BinderAxis.price,
        sortDir: SortDirection.desc,
        isVirtual: false,
      );

      final binders = await repository.listBinders();
      expect(binders.map((b) => b.name), ['First', 'Second v2']);
    });
  });

  group('deleteBinder', () {
    test('removes the binder and compacts priority indexes', () async {
      final repository = repo();
      final first = await create(repository, name: 'First');
      await create(repository, name: 'Second');
      await create(repository, name: 'Third');

      await repository.deleteBinder(first);

      final binders = await repository.listBinders();
      expect(binders.map((b) => b.name), ['Second', 'Third']);
      expect(binders.map((b) => b.priorityIndex), [0, 1]);
    });

    test('cascades committed slots', () async {
      final repository = repo();
      final id = await create(repository);
      await db.into(db.binderSlots).insert(BinderSlotsCompanion.insert(
            id: 'slot-1',
            binderId: id,
            scryfallId: 'bolt',
            finish: Finish.nonfoil,
            quantity: 1,
            page: 1,
            side: PageSide.front,
            pocket: 1,
            createdAt: DateTime.utc(2026, 7, 1),
            updatedAt: DateTime.utc(2026, 7, 1),
          ));

      await repository.deleteBinder(id);

      expect(await db.select(db.binderSlots).get(), isEmpty);
    });
  });

  group('reorderBinders', () {
    test('rewrites priority to match the given order', () async {
      final repository = repo();
      final a = await create(repository, name: 'A');
      final b = await create(repository, name: 'B');
      final c = await create(repository, name: 'C');

      await repository.reorderBinders([c, a, b]);

      final binders = await repository.listBinders();
      expect(binders.map((binder) => binder.name), ['C', 'A', 'B']);
      expect(binders.map((binder) => binder.priorityIndex), [0, 1, 2]);
    });
  });

  group('watchBinders', () {
    test('emits in priority order and re-emits on change', () async {
      final repository = repo();
      final a = await create(repository, name: 'A');
      final b = await create(repository, name: 'B');

      final emissions = <List<String>>[];
      final sub = repository
          .watchBinders()
          .listen((binders) => emissions.add([for (final x in binders) x.name]));
      await pumpEventQueue();
      expect(emissions.last, ['A', 'B']);

      await repository.reorderBinders([b, a]);
      await pumpEventQueue();
      expect(emissions.last, ['B', 'A']);

      await sub.cancel();
    });
  });

  group('getBinder', () {
    test('returns the binder or null', () async {
      final repository = repo();
      final id = await create(repository);
      expect((await repository.getBinder(id))?.id, id);
      expect(await repository.getBinder('missing'), isNull);
    });
  });

  group('watchAllSlots', () {
    test('emits committed slots across binders', () async {
      final repository = repo();
      final id = await create(repository);
      await db.into(db.binderSlots).insert(BinderSlotsCompanion.insert(
            id: 'slot-1',
            binderId: id,
            scryfallId: 'bolt',
            finish: Finish.foil,
            quantity: 2,
            page: 3,
            side: PageSide.back,
            pocket: 5,
            isPinned: const Value(true),
            createdAt: DateTime.utc(2026, 7, 1),
            updatedAt: DateTime.utc(2026, 7, 1),
          ));

      final slots = await repository.watchAllSlots().first;
      expect(slots, hasLength(1));
      expect(slots.single.scryfallId, 'bolt');
      expect(slots.single.isPinned, isTrue);
    });
  });

  group('BinderGeometryX', () {
    test('derives geometry from the row', () async {
      final repository = repo();
      final id = await create(repository);
      final binder = (await repository.getBinder(id))!;

      expect(
        binder.geometry,
        const BinderGeometry(
          rows: 3,
          cols: 3,
          pageCount: 10,
          doubleSided: true,
        ),
      );
      expect(binder.geometry.capacity, 180);
    });
  });
}

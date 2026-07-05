import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/state/binder_state_codec.dart';
import 'package:binder_manager/core/state/change_staging_service.dart';

void main() {
  late UserDatabase db;
  late ChangeStagingService service;
  final fixedNow = DateTime.utc(2026, 7, 4, 12);

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    service = ChangeStagingService(db, clock: () => fixedNow);
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  Future<void> insertBinder({
    String id = 'binder-a',
    String query = 'unused:true',
    int priorityIndex = 0,
  }) {
    return db.into(db.binders).insert(BindersCompanion.insert(
          id: id,
          name: 'Binder $id',
          query: query,
          priorityIndex: priorityIndex,
          layoutRows: 3,
          layoutCols: 3,
          pageCount: 20,
          createdAt: fixedNow,
          updatedAt: fixedNow,
        ));
  }

  Future<void> insertSlot({
    String id = 'slot-1',
    String binderId = 'binder-a',
    String scryfallId = 'bolt',
    Finish finish = Finish.nonfoil,
    int quantity = 4,
    int page = 1,
    PageSide side = PageSide.front,
    int pocket = 1,
    bool isPinned = false,
  }) {
    return db.into(db.binderSlots).insert(BinderSlotsCompanion.insert(
          id: id,
          binderId: binderId,
          scryfallId: scryfallId,
          finish: finish,
          quantity: quantity,
          page: page,
          side: side,
          pocket: pocket,
          isPinned: Value(isPinned),
          createdAt: fixedNow,
          updatedAt: fixedNow,
        ));
  }

  PlannedPlacement plan({
    String binderId = 'binder-a',
    String scryfallId = 'bolt',
    Finish finish = Finish.nonfoil,
    int quantity = 4,
    int page = 1,
    PageSide side = PageSide.front,
    int pocket = 1,
  }) =>
      PlannedPlacement(
        binderId: binderId,
        identity: CardIdentity(scryfallId, finish),
        quantity: quantity,
        position: BinderPosition(page: page, side: side, pocket: pocket),
      );

  Future<List<BinderSlotRow>> allSlots() => db.select(db.binderSlots).get();
  Future<List<SnapshotRow>> allSnapshots() => db.select(db.snapshots).get();

  group('stage', () {
    test('computes a diff against committed slots and exposes it as state',
        () async {
      await insertBinder();
      await insertSlot(scryfallId: 'opt', pocket: 2);

      await service.stage(
        trigger: ChangeTrigger.ruleEdit,
        planned: [plan()],
      );

      final diff = service.state!;
      expect(diff.trigger, ChangeTrigger.ruleEdit);
      expect(diff.addCount, 1); // bolt planned
      expect(diff.removeCount, 1); // opt committed but not planned
      expect(service.staged, same(diff));
    });

    test('stages null when planned matches committed exactly', () async {
      await insertBinder();
      await insertSlot();

      await service.stage(
        trigger: ChangeTrigger.priceRefresh,
        planned: [plan()],
      );

      expect(service.state, isNull);
    });

    test('orders entries by binder priority from the binders table',
        () async {
      await insertBinder(id: 'binder-low', priorityIndex: 5);
      await insertBinder(id: 'binder-top', priorityIndex: 0);

      await service.stage(
        trigger: ChangeTrigger.ruleEdit,
        planned: [
          plan(binderId: 'binder-low', scryfallId: 'a'),
          plan(binderId: 'binder-top', scryfallId: 'b'),
        ],
      );

      expect(
        service.state!.entries.map((e) => e.binderId).toList(),
        ['binder-top', 'binder-low'],
      );
    });

    test('restaging replaces the previous staged diff', () async {
      await insertBinder();

      await service.stage(
        trigger: ChangeTrigger.ruleEdit,
        planned: [plan()],
      );
      await service.stage(
        trigger: ChangeTrigger.deckChange,
        planned: [plan(), plan(scryfallId: 'opt', pocket: 2)],
      );

      expect(service.state!.trigger, ChangeTrigger.deckChange);
      expect(service.state!.addCount, 2);
    });

    test('passes overflow through to the staged diff', () async {
      await insertBinder();

      await service.stage(
        trigger: ChangeTrigger.collectionImport,
        planned: [],
        overflow: const [
          OverflowEntry(
            binderId: 'binder-a',
            identity: CardIdentity('urza', Finish.foil),
            quantity: 2,
          ),
        ],
      );

      expect(service.state!.entries, isEmpty);
      expect(service.state!.overflowChanges, hasLength(1));
    });
  });

  group('commit', () {
    test('throws StateError when nothing is staged', () {
      expect(() => service.commit(), throwsStateError);
    });

    test('applies adds with uuid v4 ids and timestamps', () async {
      await insertBinder();
      await service.stage(
        trigger: ChangeTrigger.collectionImport,
        planned: [plan(page: 2, side: PageSide.back, pocket: 3)],
      );

      await service.commit();

      final slot = (await allSlots()).single;
      expect(slot.binderId, 'binder-a');
      expect(slot.scryfallId, 'bolt');
      expect(slot.quantity, 4);
      expect(slot.page, 2);
      expect(slot.side, PageSide.back);
      expect(slot.pocket, 3);
      expect(slot.isPinned, isFalse);
      // uuid v4 shape: 8-4-4-4-12 hex with version nibble 4.
      expect(
        slot.id,
        matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$')),
      );
      expect(slot.createdAt.toUtc(), fixedNow);
      expect(slot.updatedAt.toUtc(), fixedNow);
      expect(service.state, isNull);
    });

    test('applies removes by deleting the slot row', () async {
      await insertBinder();
      await insertSlot();
      await service.stage(trigger: ChangeTrigger.deckChange, planned: []);

      await service.commit();

      expect(await allSlots(), isEmpty);
    });

    test('applies moves in place, updating position and updatedAt only',
        () async {
      await insertBinder();
      await insertSlot();
      await service.stage(
        trigger: ChangeTrigger.priorityReorder,
        planned: [plan(page: 5, side: PageSide.back, pocket: 7)],
      );

      final later = DateTime.utc(2026, 7, 5);
      final movingService = ChangeStagingService(db, clock: () => later);
      addTearDown(movingService.dispose);
      await movingService.stage(
        trigger: ChangeTrigger.priorityReorder,
        planned: [plan(page: 5, side: PageSide.back, pocket: 7)],
      );
      await movingService.commit();

      final slot = (await allSlots()).single;
      expect(slot.id, 'slot-1'); // row survives — stable id (D12)
      expect(slot.page, 5);
      expect(slot.side, PageSide.back);
      expect(slot.pocket, 7);
      expect(slot.createdAt.toUtc(), fixedNow);
      expect(slot.updatedAt.toUtc(), later);
    });

    test(
        'coalesces a quantity change (Remove+Add) into an update that '
        'preserves the slot id and pin', () async {
      await insertBinder();
      await insertSlot(quantity: 4, isPinned: true);
      await service.stage(
        trigger: ChangeTrigger.collectionImport,
        planned: [plan(quantity: 2, page: 9, pocket: 9)],
      );

      final diff = service.state!;
      expect(diff.removeCount, 1);
      expect(diff.addCount, 1);

      await service.commit();

      final slot = (await allSlots()).single;
      expect(slot.id, 'slot-1'); // not delete+insert
      expect(slot.quantity, 2);
      expect(slot.isPinned, isTrue); // pin survives the quantity adjust
      expect(slot.page, 1); // pinned: position unchanged
      expect(slot.pocket, 1);
    });

    test('cross-binder migration deletes from one binder, inserts in the '
        'other', () async {
      await insertBinder(id: 'binder-a', priorityIndex: 0);
      await insertBinder(id: 'binder-b', priorityIndex: 1);
      await insertSlot(binderId: 'binder-a');
      await service.stage(
        trigger: ChangeTrigger.ruleEdit,
        planned: [plan(binderId: 'binder-b', page: 2)],
      );

      await service.commit();

      final slot = (await allSlots()).single;
      expect(slot.binderId, 'binder-b');
      expect(slot.page, 2);
      expect(slot.id, isNot('slot-1'));
    });

    test('writes a snapshot of the resulting state with the trigger label',
        () async {
      await insertBinder();
      await service.stage(
        trigger: ChangeTrigger.ruleEdit,
        planned: [plan()],
      );

      await service.commit();

      final snapshot = (await allSnapshots()).single;
      expect(snapshot.triggerLabel, 'Rule edit');
      expect(snapshot.createdAt.toUtc(), fixedNow);

      final decoded = decodeBinderState(snapshot.state);
      expect(decoded.binders.single.id, 'binder-a');
      // Post-apply: the snapshot contains the newly committed placement.
      expect(decoded.slots.single.scryfallId, 'bolt');
    });

    test('prunes snapshot history beyond maxSnapshots', () async {
      await insertBinder();

      for (var i = 0; i < maxSnapshots + 3; i++) {
        final tick = fixedNow.add(Duration(minutes: i));
        final tickService = ChangeStagingService(db, clock: () => tick);
        addTearDown(tickService.dispose);
        // Alternate the planned pocket so every stage yields a real diff.
        await tickService.stage(
          trigger: ChangeTrigger.manual,
          planned: [plan(pocket: (i % 2) + 1)],
        );
        await tickService.commit();
      }

      final snapshots = await allSnapshots();
      expect(snapshots, hasLength(maxSnapshots));
      // The newest snapshots survive.
      final newest = snapshots.map((s) => s.createdAt.toUtc()).toList()
        ..sort((a, b) => b.compareTo(a));
      expect(newest.first, fixedNow.add(Duration(minutes: maxSnapshots + 2)));
    });
  });

  group('rollback', () {
    test('discardStagedDiff clears state without touching the database',
        () async {
      await insertBinder();
      await insertSlot();
      await service.stage(trigger: ChangeTrigger.deckChange, planned: []);
      expect(service.state, isNotNull);

      service.discardStagedDiff();

      expect(service.state, isNull);
      expect(await allSlots(), hasLength(1));
    });

    test('restoreLatestSnapshot returns false when nothing was committed',
        () async {
      expect(await service.restoreLatestSnapshot(), isFalse);
    });

    test('rollback with no snapshot just discards the staged diff', () async {
      await insertBinder();
      await service.stage(
        trigger: ChangeTrigger.ruleEdit,
        planned: [plan()],
      );

      await service.rollback();

      expect(service.state, isNull);
      expect(await allSlots(), isEmpty);
      // The binder definition itself is untouched (no checkpoint existed).
      expect(await db.select(db.binders).get(), hasLength(1));
    });

    test('acceptance flow: commit → rule edit mutates binders → rollback '
        'restores rule AND placements → re-commit works', () async {
      // Commit an initial placement.
      await insertBinder(query: 'usd>5');
      await service.stage(
        trigger: ChangeTrigger.manual,
        planned: [plan()],
      );
      await service.commit();
      expect(await allSlots(), hasLength(1));

      // A rule edit mutates the binder definition immediately...
      await (db.update(db.binders)
            ..where((b) => b.id.equals('binder-a')))
          .write(const BindersCompanion(query: Value('usd>50')));
      // ...and the integrator stages the resulting placement diff.
      await service.stage(trigger: ChangeTrigger.ruleEdit, planned: []);
      expect(service.state!.removeCount, 1);

      // Roll back: rule AND placements return to the committed state.
      await service.rollback();

      expect(service.state, isNull);
      final binder = await db.select(db.binders).getSingle();
      expect(binder.query, 'usd>5');
      final slot = (await allSlots()).single;
      expect(slot.scryfallId, 'bolt');

      // Re-commit: the same edit staged again commits cleanly.
      await (db.update(db.binders)
            ..where((b) => b.id.equals('binder-a')))
          .write(const BindersCompanion(query: Value('usd>50')));
      await service.stage(trigger: ChangeTrigger.ruleEdit, planned: []);
      await service.commit();

      expect(await allSlots(), isEmpty);
      expect((await allSnapshots()), hasLength(2));
    });

    test('restoreLatestSnapshot restores deleted binders and slots',
        () async {
      await insertBinder(id: 'binder-a');
      await insertBinder(id: 'binder-b', priorityIndex: 1);
      await service.stage(
        trigger: ChangeTrigger.manual,
        planned: [plan(), plan(binderId: 'binder-b', scryfallId: 'opt')],
      );
      await service.commit();

      // A destructive event wipes a whole binder (cascade takes its slots).
      await (db.delete(db.binders)..where((b) => b.id.equals('binder-b')))
          .go();
      expect(await allSlots(), hasLength(1));

      expect(await service.restoreLatestSnapshot(), isTrue);

      expect(await db.select(db.binders).get(), hasLength(2));
      final slots = await allSlots();
      expect(slots, hasLength(2));
      expect(
        slots.map((s) => s.scryfallId).toSet(),
        {'bolt', 'opt'},
      );
    });
  });
}

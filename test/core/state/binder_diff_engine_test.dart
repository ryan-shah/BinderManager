import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/state/binder_diff_engine.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 7, 4, 12);

  BinderPosition pos(int page, PageSide side, int pocket) =>
      BinderPosition(page: page, side: side, pocket: pocket);

  PlannedPlacement plan({
    String binderId = 'binder-a',
    String scryfallId = 'bolt',
    Finish finish = Finish.nonfoil,
    int quantity = 4,
    required BinderPosition position,
  }) =>
      PlannedPlacement(
        binderId: binderId,
        identity: CardIdentity(scryfallId, finish),
        quantity: quantity,
        position: position,
      );

  BinderSlotRow slot({
    String id = 'slot-1',
    String binderId = 'binder-a',
    String scryfallId = 'bolt',
    Finish finish = Finish.nonfoil,
    int quantity = 4,
    required BinderPosition position,
    bool isPinned = false,
  }) =>
      BinderSlotRow(
        id: id,
        binderId: binderId,
        scryfallId: scryfallId,
        finish: finish,
        quantity: quantity,
        page: position.page,
        side: position.side,
        pocket: position.pocket,
        isPinned: isPinned,
        createdAt: fixedNow,
        updatedAt: fixedNow,
      );

  StagedDiff diffOf({
    List<PlannedPlacement> planned = const [],
    List<BinderSlotRow> committed = const [],
    List<OverflowEntry> overflow = const [],
    List<String> priority = const [],
  }) =>
      computeBinderDiff(
        trigger: ChangeTrigger.ruleEdit,
        planned: planned,
        committed: committed,
        overflow: overflow,
        binderPriorityOrder: priority,
        now: fixedNow,
      );

  group('computeBinderDiff basics', () {
    test('empty planned and committed yields an empty diff', () {
      final diff = diffOf();

      expect(diff.isEmpty, isTrue);
      expect(diff.entries, isEmpty);
      expect(diff.trigger, ChangeTrigger.ruleEdit);
      expect(diff.createdAt, fixedNow);
    });

    test('planned-only stack becomes an Add at the planned position', () {
      final target = pos(1, PageSide.front, 1);
      final diff = diffOf(planned: [plan(position: target)]);

      expect(diff.entries, hasLength(1));
      final entry = diff.entries.single;
      expect(entry.type, DiffType.add);
      expect(entry.binderId, 'binder-a');
      expect(entry.identity, const CardIdentity('bolt', Finish.nonfoil));
      expect(entry.quantity, 4);
      expect(entry.from, isNull);
      expect(entry.to, target);
    });

    test('committed-only stack becomes a Remove from the committed position',
        () {
      final source = pos(2, PageSide.back, 3);
      final diff = diffOf(committed: [slot(position: source)]);

      expect(diff.entries, hasLength(1));
      final entry = diff.entries.single;
      expect(entry.type, DiffType.remove);
      expect(entry.quantity, 4);
      expect(entry.from, source);
      expect(entry.to, isNull);
    });

    test('identical stack on both sides yields no entry', () {
      final position = pos(1, PageSide.front, 5);
      final diff = diffOf(
        planned: [plan(position: position)],
        committed: [slot(position: position)],
      );

      expect(diff.entries, isEmpty);
    });

    test('same stack at a different position becomes a Move', () {
      final from = pos(1, PageSide.front, 1);
      final to = pos(3, PageSide.back, 5);
      final diff = diffOf(
        planned: [plan(position: to)],
        committed: [slot(position: from)],
      );

      expect(diff.entries, hasLength(1));
      final entry = diff.entries.single;
      expect(entry.type, DiffType.move);
      expect(entry.from, from);
      expect(entry.to, to);
      expect(entry.instruction('Ragavan'),
          'Move Ragavan → page 3, back, pocket 5');
    });

    test('different finishes of one printing are independent stacks', () {
      final position = pos(1, PageSide.front, 1);
      final diff = diffOf(
        planned: [
          plan(finish: Finish.foil, position: pos(1, PageSide.front, 2)),
        ],
        committed: [slot(finish: Finish.nonfoil, position: position)],
      );

      expect(diff.entries, hasLength(2));
      expect(diff.removeCount, 1);
      expect(diff.addCount, 1);
    });
  });

  group('quantity changes (Remove+Add convention)', () {
    test('same position, different quantity emits Remove+Add at that position',
        () {
      final position = pos(2, PageSide.front, 4);
      final diff = diffOf(
        planned: [plan(quantity: 2, position: position)],
        committed: [slot(quantity: 4, position: position)],
      );

      expect(diff.entries, hasLength(2));
      final remove = diff.entries[0];
      final add = diff.entries[1];
      expect(remove.type, DiffType.remove);
      expect(remove.quantity, 4);
      expect(remove.from, position);
      expect(add.type, DiffType.add);
      expect(add.quantity, 2);
      expect(add.to, position);
    });

    test('quantity and position change emits Remove(old pos)+Add(new pos)',
        () {
      final oldPos = pos(1, PageSide.front, 1);
      final newPos = pos(2, PageSide.back, 2);
      final diff = diffOf(
        planned: [plan(quantity: 3, position: newPos)],
        committed: [slot(quantity: 4, position: oldPos)],
      );

      expect(diff.entries, hasLength(2));
      expect(diff.entries[0].type, DiffType.remove);
      expect(diff.entries[0].from, oldPos);
      expect(diff.entries[0].quantity, 4);
      expect(diff.entries[1].type, DiffType.add);
      expect(diff.entries[1].to, newPos);
      expect(diff.entries[1].quantity, 3);
    });
  });

  group('pinned slots (D7: never removed, never moved)', () {
    test('pinned committed-only stack yields no Remove — it stays', () {
      final diff = diffOf(
        committed: [slot(position: pos(1, PageSide.front, 1), isPinned: true)],
      );

      expect(diff.entries, isEmpty);
    });

    test('pinned stack planned at a different position yields no Move', () {
      final diff = diffOf(
        planned: [plan(position: pos(5, PageSide.back, 9))],
        committed: [slot(position: pos(1, PageSide.front, 1), isPinned: true)],
      );

      expect(diff.entries, isEmpty);
    });

    test('pinned stack with a quantity change adjusts at the pinned position',
        () {
      final pinnedPos = pos(1, PageSide.front, 1);
      final diff = diffOf(
        planned: [plan(quantity: 2, position: pos(5, PageSide.back, 9))],
        committed: [slot(quantity: 4, position: pinnedPos, isPinned: true)],
      );

      expect(diff.entries, hasLength(2));
      expect(diff.entries[0].type, DiffType.remove);
      expect(diff.entries[0].from, pinnedPos);
      expect(diff.entries[1].type, DiffType.add);
      // The pin protects position: the add lands back in the pinned pocket,
      // not the planned one.
      expect(diff.entries[1].to, pinnedPos);
      expect(diff.entries[1].quantity, 2);
    });

    test('unpinned committed-only stack in same binder as pinned one removes',
        () {
      final diff = diffOf(
        committed: [
          slot(id: 's1', position: pos(1, PageSide.front, 1), isPinned: true),
          slot(
            id: 's2',
            scryfallId: 'opt',
            position: pos(1, PageSide.front, 2),
          ),
        ],
      );

      expect(diff.entries, hasLength(1));
      expect(diff.entries.single.identity.scryfallId, 'opt');
      expect(diff.entries.single.type, DiffType.remove);
    });
  });

  group('cross-binder migration', () {
    test('stack moving binders yields Remove from old + Add to new', () {
      final oldPos = pos(1, PageSide.front, 1);
      final newPos = pos(2, PageSide.front, 3);
      final diff = diffOf(
        planned: [plan(binderId: 'binder-b', position: newPos)],
        committed: [slot(binderId: 'binder-a', position: oldPos)],
        priority: ['binder-a', 'binder-b'],
      );

      expect(diff.entries, hasLength(2));
      expect(diff.entries[0].type, DiffType.remove);
      expect(diff.entries[0].binderId, 'binder-a');
      expect(diff.entries[0].from, oldPos);
      expect(diff.entries[1].type, DiffType.add);
      expect(diff.entries[1].binderId, 'binder-b');
      expect(diff.entries[1].to, newPos);
    });

    test('pinned stack never migrates binders — planned add still lands', () {
      final diff = diffOf(
        planned: [
          plan(binderId: 'binder-b', position: pos(1, PageSide.front, 1)),
        ],
        committed: [
          slot(
            binderId: 'binder-a',
            position: pos(1, PageSide.front, 1),
            isPinned: true,
          ),
        ],
      );

      // The pinned slot in A stays; the planned copy in B is still an Add.
      // (Preventing the allocator from re-planning a pinned stack elsewhere
      // is the allocator's job — the diff engine only protects the pin.)
      expect(diff.entries, hasLength(1));
      expect(diff.entries.single.type, DiffType.add);
      expect(diff.entries.single.binderId, 'binder-b');
    });
  });

  group('ordering', () {
    test('entries group by binder priority order, then position', () {
      final diff = diffOf(
        planned: [
          plan(
            binderId: 'binder-low',
            scryfallId: 'card-z',
            position: pos(1, PageSide.front, 1),
          ),
          plan(
            binderId: 'binder-top',
            scryfallId: 'card-b',
            position: pos(2, PageSide.front, 1),
          ),
          plan(
            binderId: 'binder-top',
            scryfallId: 'card-a',
            position: pos(1, PageSide.back, 3),
          ),
        ],
        committed: [
          slot(
            binderId: 'binder-top',
            scryfallId: 'card-c',
            position: pos(1, PageSide.front, 2),
          ),
        ],
        priority: ['binder-top', 'binder-low'],
      );

      expect(diff.entries.map((e) => e.binderId).toList(),
          ['binder-top', 'binder-top', 'binder-top', 'binder-low']);
      // Within binder-top: front p1 pocket 2 (remove) < back p1 pocket 3
      // (add) < front p2 (add) per D9 fill order.
      expect(diff.entries[0].identity.scryfallId, 'card-c');
      expect(diff.entries[1].identity.scryfallId, 'card-a');
      expect(diff.entries[2].identity.scryfallId, 'card-b');
    });

    test('binders missing from the priority list sort last by id', () {
      final diff = diffOf(
        planned: [
          plan(binderId: 'zz-unknown', position: pos(1, PageSide.front, 1)),
          plan(
            binderId: 'aa-unknown',
            scryfallId: 'opt',
            position: pos(1, PageSide.front, 1),
          ),
          plan(
            binderId: 'known',
            scryfallId: 'ragavan',
            position: pos(1, PageSide.front, 1),
          ),
        ],
        priority: ['known'],
      );

      expect(diff.entries.map((e) => e.binderId).toList(),
          ['known', 'aa-unknown', 'zz-unknown']);
    });

    test('same-pocket Remove+Add pairs list the remove first', () {
      final position = pos(1, PageSide.front, 1);
      final diff = diffOf(
        planned: [plan(quantity: 1, position: position)],
        committed: [slot(quantity: 4, position: position)],
      );

      expect(diff.entries[0].type, DiffType.remove);
      expect(diff.entries[1].type, DiffType.add);
    });

    test('is deterministic regardless of input order', () {
      final plannedA = [
        plan(scryfallId: 'a', position: pos(1, PageSide.front, 1)),
        plan(scryfallId: 'b', position: pos(1, PageSide.front, 2)),
        plan(binderId: 'binder-b', scryfallId: 'c',
            position: pos(1, PageSide.front, 1)),
      ];
      final committed = [
        slot(id: 's1', scryfallId: 'd', position: pos(2, PageSide.back, 1)),
      ];

      final forward = diffOf(planned: plannedA, committed: committed);
      final reversed = diffOf(
        planned: plannedA.reversed.toList(),
        committed: committed,
      );

      expect(forward.entries, reversed.entries);
    });
  });

  group('overflow and counts', () {
    test('overflow entries pass through and count summaries add up', () {
      final diff = diffOf(
        planned: [plan(position: pos(1, PageSide.front, 1))],
        committed: [
          slot(scryfallId: 'opt', position: pos(1, PageSide.front, 2)),
          slot(
            scryfallId: 'ragavan',
            position: pos(1, PageSide.front, 3),
          ),
        ],
        overflow: const [
          OverflowEntry(
            binderId: 'binder-a',
            identity: CardIdentity('urza', Finish.foil),
            quantity: 2,
          ),
        ],
      );

      expect(diff.addCount, 1);
      expect(diff.removeCount, 2);
      expect(diff.moveCount, 0);
      expect(diff.overflowChanges, hasLength(1));
      expect(diff.isEmpty, isFalse);
    });

    test('overflow-only diff is not empty', () {
      final diff = diffOf(
        overflow: const [
          OverflowEntry(
            binderId: 'binder-a',
            identity: CardIdentity('urza', Finish.foil),
            quantity: 2,
          ),
        ],
      );

      expect(diff.entries, isEmpty);
      expect(diff.isEmpty, isFalse);
    });
  });
}

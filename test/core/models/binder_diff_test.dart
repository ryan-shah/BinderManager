import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';

void main() {
  const bolt = CardIdentity('bolt-1', Finish.nonfoil);
  const ragavan = CardIdentity('ragavan-1', Finish.foil);
  const p1 = BinderPosition(page: 2, side: PageSide.front, pocket: 1);
  const p2 = BinderPosition(page: 3, side: PageSide.back, pocket: 5);

  group('BinderDiffEntry', () {
    test('add/remove/move produce the exact D7 instructions', () {
      const add = BinderDiffEntry(
        type: DiffType.add,
        binderId: 'binder-1',
        identity: bolt,
        quantity: 4,
        to: p2,
      );
      const remove = BinderDiffEntry(
        type: DiffType.remove,
        binderId: 'binder-1',
        identity: bolt,
        quantity: 1,
        from: p1,
      );
      const move = BinderDiffEntry(
        type: DiffType.move,
        binderId: 'binder-1',
        identity: ragavan,
        quantity: 1,
        from: p1,
        to: p2,
      );

      expect(add.instruction('Lightning Bolt'),
          'Add Lightning Bolt → page 3, back, pocket 5');
      expect(remove.instruction('Lightning Bolt'),
          'Pull Lightning Bolt from page 2, front, pocket 1');
      expect(move.instruction('Ragavan'),
          'Move Ragavan → page 3, back, pocket 5');
    });

    test('asserts location shape per type', () {
      expect(
        () => BinderDiffEntry(
          type: DiffType.add,
          binderId: 'b',
          identity: bolt,
          quantity: 1,
          from: p1, // adds have no source
          to: p2,
        ),
        throwsAssertionError,
      );
      expect(
        () => BinderDiffEntry(
          type: DiffType.move,
          binderId: 'b',
          identity: bolt,
          quantity: 1,
          to: p2, // moves need both
        ),
        throwsAssertionError,
      );
    });
  });

  group('StagedDiff', () {
    final diff = StagedDiff(
      trigger: ChangeTrigger.priceRefresh,
      createdAt: DateTime.utc(2026, 7, 4),
      entries: const [
        BinderDiffEntry(
          type: DiffType.add,
          binderId: 'binder-1',
          identity: bolt,
          quantity: 4,
          to: p1,
        ),
        BinderDiffEntry(
          type: DiffType.add,
          binderId: 'binder-2',
          identity: ragavan,
          quantity: 1,
          to: p1,
        ),
        BinderDiffEntry(
          type: DiffType.move,
          binderId: 'binder-1',
          identity: ragavan,
          quantity: 1,
          from: p1,
          to: p2,
        ),
      ],
      overflowChanges: const [
        OverflowEntry(binderId: 'binder-1', identity: bolt, quantity: 2),
      ],
    );

    test('summary counts by type', () {
      expect(diff.addCount, 2);
      expect(diff.removeCount, 0);
      expect(diff.moveCount, 1);
      expect(diff.isEmpty, isFalse);
    });

    test('entriesByBinder groups preserving order', () {
      final grouped = diff.entriesByBinder;
      expect(grouped.keys, ['binder-1', 'binder-2']);
      expect(grouped['binder-1'], hasLength(2));
      expect(grouped['binder-1']!.first.type, DiffType.add);
      expect(grouped['binder-1']!.last.type, DiffType.move);
    });

    test('empty diff reports isEmpty', () {
      final empty = StagedDiff(
        trigger: ChangeTrigger.manual,
        createdAt: DateTime.utc(2026, 7, 4),
        entries: const [],
      );
      expect(empty.isEmpty, isTrue);
    });

    test('triggers carry review-header labels', () {
      expect(ChangeTrigger.priceRefresh.label, 'Price refresh');
      expect(ChangeTrigger.collectionImport.label, 'Collection import');
    });
  });
}

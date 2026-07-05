/// Pure diff computation between planned and committed binder state (D7).
///
/// Given the allocator's planned placements and the committed `binder_slots`
/// rows, produce the [StagedDiff] the change-review screen displays and the
/// commit engine applies. No database access here — this is pure Dart so the
/// semantics below are exhaustively unit-testable.
///
/// ## Diff semantics
///
/// A *stack* is keyed by `(binderId, CardIdentity)`. For each key:
///
/// - **Planned only** → `Add` (to = planned position).
/// - **Committed only** → `Remove` (from = committed position) — unless the
///   committed slot is **pinned**: a pinned slot is never removed and never
///   moved; it simply stays (D7: "the engine never proposes moving it").
/// - **Both, different position, same quantity** → `Move` (from committed,
///   to planned) — unless pinned, in which case no entry is emitted and the
///   card stays where it is.
/// - **Both, different quantity** → modeled as `Remove` (the old stack) +
///   `Add` (the new quantity). The shared diff model has no quantity-adjust
///   type, and a Move with equal from/to would be wrong, so Remove+Add is
///   the consistent v1 encoding. The physical reading is "pull the stack,
///   re-sleeve N copies". For a **pinned** slot the pin protects *position*,
///   not quantity: the pair is emitted at the **committed** position so the
///   card never moves. The commit engine coalesces a Remove+Add of the same
///   key back into a single row UPDATE, preserving the slot's id and pin.
/// - **Binder changed** (planned in binder B, committed in binder A) → the
///   keys differ, so this naturally yields `Remove` from A + `Add` to B.
///   A pinned slot in A still refuses its Remove (it stays), so a pinned
///   stack never migrates binders until unpinned.
///
/// Entries are grouped by binder — in binder priority order when
/// [binderPriorityOrder] is given (unknown binders after, sorted by id) —
/// and ordered within a binder by position (destination for adds/moves,
/// source for removes), with removes before moves before adds at the same
/// pocket so instructions read in physical order ("pull, then add").
library;

import '../models/binder_diff.dart';
import '../models/binder_position.dart';
import '../models/card_identity.dart';

import '../database/user_database.dart' show BinderSlotRow;

/// Computes the staged diff between [planned] and [committed] state across
/// all binders. See the library docs for the exact semantics.
///
/// [committed] is expected to contain at most one slot per
/// `(binderId, identity)` — stacks are atomic (D6), so all copies of a
/// stack share one pocket row. Duplicate keys are a data error; the last
/// row wins here.
StagedDiff computeBinderDiff({
  required ChangeTrigger trigger,
  required List<PlannedPlacement> planned,
  required List<BinderSlotRow> committed,
  List<OverflowEntry> overflow = const [],
  List<String> binderPriorityOrder = const [],
  DateTime? now,
}) {
  final plannedByKey = <_StackKey, PlannedPlacement>{};
  for (final placement in planned) {
    plannedByKey[_StackKey(placement.binderId, placement.identity)] =
        placement;
  }

  final committedByKey = <_StackKey, BinderSlotRow>{};
  for (final slot in committed) {
    committedByKey[_StackKey(
      slot.binderId,
      CardIdentity(slot.scryfallId, slot.finish),
    )] = slot;
  }

  final entries = <BinderDiffEntry>[];

  // Committed-side walk: removes, moves, and quantity adjustments.
  for (final MapEntry(key: key, value: slot) in committedByKey.entries) {
    final position =
        BinderPosition(page: slot.page, side: slot.side, pocket: slot.pocket);
    final plannedMatch = plannedByKey[key];

    if (plannedMatch == null) {
      // Committed but no longer planned. Pinned slots are never removed —
      // they simply stay (D7).
      if (!slot.isPinned) {
        entries.add(BinderDiffEntry(
          type: DiffType.remove,
          binderId: key.binderId,
          identity: key.identity,
          quantity: slot.quantity,
          from: position,
        ));
      }
      continue;
    }

    if (plannedMatch.quantity != slot.quantity) {
      // Quantity changed: Remove old stack + Add new quantity. The pin
      // protects position, not quantity, so a pinned slot keeps its
      // committed position for both halves of the pair.
      final target = slot.isPinned ? position : plannedMatch.position;
      entries
        ..add(BinderDiffEntry(
          type: DiffType.remove,
          binderId: key.binderId,
          identity: key.identity,
          quantity: slot.quantity,
          from: position,
        ))
        ..add(BinderDiffEntry(
          type: DiffType.add,
          binderId: key.binderId,
          identity: key.identity,
          quantity: plannedMatch.quantity,
          to: target,
        ));
      continue;
    }

    if (plannedMatch.position != position && !slot.isPinned) {
      entries.add(BinderDiffEntry(
        type: DiffType.move,
        binderId: key.binderId,
        identity: key.identity,
        quantity: slot.quantity,
        from: position,
        to: plannedMatch.position,
      ));
    }
    // Same position + same quantity (or pinned): no entry.
  }

  // Planned-side walk: pure adds.
  for (final MapEntry(key: key, value: placement) in plannedByKey.entries) {
    if (committedByKey.containsKey(key)) continue;
    entries.add(BinderDiffEntry(
      type: DiffType.add,
      binderId: key.binderId,
      identity: key.identity,
      quantity: placement.quantity,
      to: placement.position,
    ));
  }

  entries.sort(_entryComparator(binderPriorityOrder));

  return StagedDiff(
    trigger: trigger,
    entries: entries,
    overflowChanges: overflow,
    createdAt: now ?? DateTime.now(),
  );
}

/// Orders entries by binder (priority order first, unknown binders after by
/// id), then by position, then removes < moves < adds so same-pocket pairs
/// read in physical order, then by identity for full determinism.
Comparator<BinderDiffEntry> _entryComparator(List<String> priorityOrder) {
  final priorityOf = <String, int>{
    for (var i = 0; i < priorityOrder.length; i++) priorityOrder[i]: i,
  };

  int binderRank(String binderId) =>
      priorityOf[binderId] ?? priorityOrder.length;

  const typeRank = {DiffType.remove: 0, DiffType.move: 1, DiffType.add: 2};

  return (a, b) {
    final byPriority = binderRank(a.binderId).compareTo(binderRank(b.binderId));
    if (byPriority != 0) return byPriority;
    final byBinder = a.binderId.compareTo(b.binderId);
    if (byBinder != 0) return byBinder;

    final positionA = a.to ?? a.from!;
    final positionB = b.to ?? b.from!;
    final byPosition = positionA.compareTo(positionB);
    if (byPosition != 0) return byPosition;

    final byType = typeRank[a.type]!.compareTo(typeRank[b.type]!);
    if (byType != 0) return byType;

    final byCard = a.identity.scryfallId.compareTo(b.identity.scryfallId);
    if (byCard != 0) return byCard;
    return a.identity.finish.index.compareTo(b.identity.finish.index);
  };
}

class _StackKey {
  const _StackKey(this.binderId, this.identity);

  final String binderId;
  final CardIdentity identity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StackKey &&
          binderId == other.binderId &&
          identity == other.identity;

  @override
  int get hashCode => Object.hash(binderId, identity);
}

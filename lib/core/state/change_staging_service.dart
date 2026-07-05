/// The D7 staging + commit/rollback engine over the durable user database.
///
/// The staged diff is held **in memory only** ([StateNotifier] state):
/// planned state is always recomputable from the collection + binder rules,
/// so only committed state needs to persist. Committed state lives in
/// `binder_slots`; checkpoints live in `snapshots`.
///
/// ## Snapshot & rollback semantics
///
/// [commit] applies the staged diff and — in the same transaction — writes a
/// snapshot of the **resulting** committed binder state (definitions,
/// priority order, placements), labeled with the staged diff's trigger. The
/// invariant is: *the newest snapshot always equals the committed state as
/// of the last commit.*
///
/// That invariant is what makes "Roll back restores" work after a change
/// event has already mutated binder definitions (e.g. a rule edit writes the
/// new query to `binders` before the placement diff is committed):
/// [rollback] discards the staged diff and restores the newest snapshot,
/// returning both the binder definitions AND the placements to the last
/// committed state. Snapshotting the *pre*-apply state instead would make
/// restore undo the previous commit's placements — wrong per the D7
/// acceptance flow (commit → edit rule → roll back → re-commit).
///
/// History is capped at [maxSnapshots]; older checkpoints are pruned inside
/// the commit transaction.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/user_database.dart';
import '../models/binder_diff.dart';
import '../models/card_identity.dart';
import 'binder_diff_engine.dart';
import 'binder_state_codec.dart';

/// Maximum retained snapshots (D7: history is capped/pruned).
const int maxSnapshots = 20;

/// Stages, commits, and rolls back binder changes (D7), exposing the staged
/// diff reactively as its [state] (`null` = nothing pending).
///
/// This service does not compute planned placements — the allocator does.
/// The integrator wires change events (imports, deck commits, rule edits,
/// reorders, refresh) to call [stage] with the allocator's output.
class ChangeStagingService extends StateNotifier<StagedDiff?> {
  ChangeStagingService(this._db, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(null);

  final UserDatabase _db;
  final DateTime Function() _clock;
  final Uuid _uuid = const Uuid();

  /// The currently staged diff, if any.
  StagedDiff? get staged => state;

  /// Computes and stages the diff between [planned] and the committed
  /// `binder_slots` state. Replaces any previously staged diff (planned
  /// state is recomputed per change event, so the newest diff is always the
  /// whole truth). Stages `null` when there is nothing to change.
  Future<void> stage({
    required ChangeTrigger trigger,
    required List<PlannedPlacement> planned,
    List<OverflowEntry> overflow = const [],
  }) async {
    final binders = await (_db.select(_db.binders)
          ..orderBy([(b) => OrderingTerm.asc(b.priorityIndex)]))
        .get();
    final committed = await _db.select(_db.binderSlots).get();

    final diff = computeBinderDiff(
      trigger: trigger,
      planned: planned,
      committed: committed,
      overflow: overflow,
      binderPriorityOrder: [for (final binder in binders) binder.id],
      now: _clock(),
    );

    state = diff.isEmpty ? null : diff;
  }

  /// Applies the staged diff to `binder_slots` and checkpoints the resulting
  /// committed state, all in one transaction. Clears the staged diff on
  /// success; on failure the transaction rolls back and the diff stays
  /// staged.
  ///
  /// A Remove+Add pair for the same `(binderId, identity)` — the diff
  /// engine's encoding of a quantity change — is applied as a single row
  /// UPDATE so the slot keeps its id (stable IDs, D12) and its pin.
  ///
  /// Throws a [StateError] when nothing is staged.
  Future<void> commit() async {
    final diff = state;
    if (diff == null) {
      throw StateError('commit() called with no staged diff');
    }

    final now = _clock();

    await _db.transaction(() async {
      await _applyEntries(diff.entries, now);

      // Checkpoint the resulting committed state (see library docs for why
      // post-apply: the newest snapshot must equal the last committed
      // state so rollback can restore it).
      final binders = await (_db.select(_db.binders)
            ..orderBy([(b) => OrderingTerm.asc(b.priorityIndex)]))
          .get();
      final slots = await _db.select(_db.binderSlots).get();
      await _db.into(_db.snapshots).insert(SnapshotsCompanion.insert(
            id: _uuid.v4(),
            triggerLabel: diff.trigger.label,
            state: encodeBinderState(binders: binders, slots: slots),
            createdAt: now,
          ));

      await _pruneSnapshots();
    });

    state = null;
  }

  /// Discards the staged diff without touching the database. Sufficient
  /// when the triggering event did not mutate binder definitions.
  void discardStagedDiff() {
    state = null;
  }

  /// Restores the newest snapshot — binder definitions AND committed
  /// placements — transactionally, and discards any staged diff. Returns
  /// false when no snapshot exists (nothing has ever been committed; the
  /// empty initial state has no checkpoint).
  Future<bool> restoreLatestSnapshot() async {
    final snapshot = await (_db.select(_db.snapshots)
          ..orderBy([
            (s) => OrderingTerm.desc(s.createdAt),
            (s) => OrderingTerm.desc(s.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (snapshot == null) return false;

    final decoded = decodeBinderState(snapshot.state);

    await _db.transaction(() async {
      // Slots first (FK to binders), then binders; re-insert in the same
      // order. The snapshot is internally consistent, so cascades are moot,
      // but the ordering keeps the FK checker happy either way.
      await _db.delete(_db.binderSlots).go();
      await _db.delete(_db.binders).go();
      for (final binder in decoded.binders) {
        await _db.into(_db.binders).insert(binder);
      }
      for (final slot in decoded.slots) {
        await _db.into(_db.binderSlots).insert(slot);
      }
    });

    state = null;
    return true;
  }

  /// The review screen's Roll back: discard the staged diff and restore the
  /// last committed state (undoing any binder-definition mutations the
  /// triggering event already wrote — e.g. a rule edit). A no-op restore
  /// when the event touched nothing snapshot-scoped.
  Future<void> rollback() async {
    await restoreLatestSnapshot();
    state = null; // Also cleared when no snapshot existed.
  }

  // --- diff application ----------------------------------------------------

  Future<void> _applyEntries(List<BinderDiffEntry> entries, DateTime now) async {
    // Coalesce Remove+Add pairs of the same stack into quantity updates.
    final byKey = <(String, String, Finish), List<BinderDiffEntry>>{};
    for (final entry in entries) {
      byKey
          .putIfAbsent(
            (entry.binderId, entry.identity.scryfallId, entry.identity.finish),
            () => [],
          )
          .add(entry);
    }

    for (final group in byKey.values) {
      final removes = group.where((e) => e.type == DiffType.remove);
      final adds = group.where((e) => e.type == DiffType.add);

      if (removes.isNotEmpty && adds.isNotEmpty) {
        // Quantity adjustment: keep the row (id + pin), update in place.
        final add = adds.single;
        await (_db.update(_db.binderSlots)
              ..where((s) =>
                  s.binderId.equals(add.binderId) &
                  s.scryfallId.equals(add.identity.scryfallId) &
                  s.finish.equalsValue(add.identity.finish)))
            .write(BinderSlotsCompanion(
          quantity: Value(add.quantity),
          page: Value(add.to!.page),
          side: Value(add.to!.side),
          pocket: Value(add.to!.pocket),
          updatedAt: Value(now),
        ));
        continue;
      }

      for (final entry in group) {
        switch (entry.type) {
          case DiffType.add:
            await _db.into(_db.binderSlots).insert(
                  BinderSlotsCompanion.insert(
                    id: _uuid.v4(),
                    binderId: entry.binderId,
                    scryfallId: entry.identity.scryfallId,
                    finish: entry.identity.finish,
                    quantity: entry.quantity,
                    page: entry.to!.page,
                    side: entry.to!.side,
                    pocket: entry.to!.pocket,
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
          case DiffType.remove:
            await (_db.delete(_db.binderSlots)
                  ..where((s) =>
                      s.binderId.equals(entry.binderId) &
                      s.scryfallId.equals(entry.identity.scryfallId) &
                      s.finish.equalsValue(entry.identity.finish)))
                .go();
          case DiffType.move:
            await (_db.update(_db.binderSlots)
                  ..where((s) =>
                      s.binderId.equals(entry.binderId) &
                      s.scryfallId.equals(entry.identity.scryfallId) &
                      s.finish.equalsValue(entry.identity.finish)))
                .write(BinderSlotsCompanion(
              page: Value(entry.to!.page),
              side: Value(entry.to!.side),
              pocket: Value(entry.to!.pocket),
              updatedAt: Value(now),
            ));
        }
      }
    }
  }

  Future<void> _pruneSnapshots() async {
    final stale = await (_db.select(_db.snapshots)
          ..orderBy([
            (s) => OrderingTerm.desc(s.createdAt),
            (s) => OrderingTerm.desc(s.id),
          ])
          ..limit(-1, offset: maxSnapshots))
        .get();
    if (stale.isEmpty) return;
    await (_db.delete(_db.snapshots)
          ..where((s) => s.id.isIn([for (final row in stale) row.id])))
        .go();
  }
}

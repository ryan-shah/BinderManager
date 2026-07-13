import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/user_database.dart';
import '../models/card_identity.dart';
import 'manabox_parser.dart';

/// How an import interacts with the existing ManaBox-provenance snapshot.
enum ImportMode {
  /// Swap the ManaBox snapshot to match the incoming file exactly (D8 —
  /// the external app is the source of truth).
  replace,

  /// Merge by canonical identity: existing stacks gain quantity, new
  /// identities create stacks.
  append,
}

/// Card metadata resolved from the corpus for removed stacks (whose info is
/// not stored on the stack row itself). Unresolved IDs may be omitted.
typedef NameResolver
    = Future<Map<String, ({String name, String setCode, String collectorNumber})>>
        Function(List<String> scryfallIds);

/// One row of an [ImportDiff]: the quantity transition for a single
/// (printing, finish) identity.
class DiffEntry {
  const DiffEntry({
    required this.identity,
    required this.qtyBefore,
    required this.qtyAfter,
    required this.cardName,
    required this.setCode,
    required this.collectorNumber,
  });

  final CardIdentity identity;
  final int qtyBefore;
  final int qtyAfter;
  final String cardName;
  final String setCode;
  final String collectorNumber;
}

/// What a commit will change, computed against ManaBox-provenance stacks
/// only — other provenances are never touched (D8).
class ImportDiff {
  const ImportDiff({
    required this.adds,
    required this.removes,
    required this.changes,
  });

  /// Identities not currently in the ManaBox snapshot.
  final List<DiffEntry> adds;

  /// Existing ManaBox stacks absent from the incoming file (replace only).
  final List<DiffEntry> removes;

  /// Existing ManaBox stacks whose quantity will change.
  final List<DiffEntry> changes;

  bool get isEmpty => adds.isEmpty && removes.isEmpty && changes.isEmpty;
}

/// Writes parsed ManaBox stacks into the [UserDatabase].
///
/// Only rows with `provenance = 'manabox'` are ever read or written, so
/// snapshots from other sources (e.g. `deck-import`) are never stomped (D8).
class CollectionImporter {
  CollectionImporter(this._db);

  final UserDatabase _db;

  /// Provenance value owned by this importer.
  static const String provenanceManaBox = 'manabox';

  static const Uuid _uuid = Uuid();

  /// Computes the diff a [commit] with the same arguments would apply.
  ///
  /// [resolveNames] labels removes (their names are not stored on stacks);
  /// without it, removed entries fall back to the scryfall ID.
  Future<ImportDiff> computeDiff(
    List<MatchedStackRow> incoming,
    ImportMode mode, {
    NameResolver? resolveNames,
  }) async {
    final existing = await _existingStacks();
    final existingByIdentity = {
      for (final stack in existing)
        CardIdentity(stack.scryfallId, stack.finish): stack,
    };
    final incomingIdentities = incoming.map((r) => r.identity).toSet();

    final adds = <DiffEntry>[];
    final changes = <DiffEntry>[];
    for (final row in incoming) {
      final current = existingByIdentity[row.identity];
      if (current == null) {
        adds.add(DiffEntry(
          identity: row.identity,
          qtyBefore: 0,
          qtyAfter: row.quantity,
          cardName: row.corpusCard.name,
          setCode: row.corpusCard.setCode,
          collectorNumber: row.corpusCard.collectorNumber,
        ));
        continue;
      }
      final qtyAfter = mode == ImportMode.append
          ? current.quantity + row.quantity
          : row.quantity;
      if (qtyAfter != current.quantity) {
        changes.add(DiffEntry(
          identity: row.identity,
          qtyBefore: current.quantity,
          qtyAfter: qtyAfter,
          cardName: row.corpusCard.name,
          setCode: row.corpusCard.setCode,
          collectorNumber: row.corpusCard.collectorNumber,
        ));
      }
    }

    final removes = <DiffEntry>[];
    if (mode == ImportMode.replace) {
      final removedStacks = existing
          .where((s) =>
              !incomingIdentities.contains(CardIdentity(s.scryfallId, s.finish)))
          .toList();
      var names =
          const <String, ({String name, String setCode, String collectorNumber})>{};
      if (removedStacks.isNotEmpty && resolveNames != null) {
        names = await resolveNames(
          removedStacks.map((s) => s.scryfallId).toSet().toList(),
        );
      }
      for (final stack in removedStacks) {
        final info = names[stack.scryfallId];
        removes.add(DiffEntry(
          identity: CardIdentity(stack.scryfallId, stack.finish),
          qtyBefore: stack.quantity,
          qtyAfter: 0,
          cardName: info?.name ?? stack.scryfallId,
          setCode: info?.setCode ?? '',
          collectorNumber: info?.collectorNumber ?? '',
        ));
      }
    }

    return ImportDiff(adds: adds, removes: removes, changes: changes);
  }

  /// Applies [incoming] to the ManaBox snapshot in a single transaction.
  ///
  /// Replace is an ID-preserving snapshot swap (D12 — stable stack IDs):
  /// overlapping identities keep their row `id` and `createdAt` and are
  /// updated in place; stale rows are deleted; new identities are inserted
  /// with fresh UUIDs. Append upserts per identity, summing quantities.
  Future<void> commit(List<MatchedStackRow> incoming, ImportMode mode) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      switch (mode) {
        case ImportMode.replace:
          await _commitReplace(incoming, now);
        case ImportMode.append:
          await _commitAppend(incoming, now);
      }
    });
  }

  Future<void> _commitReplace(
      List<MatchedStackRow> incoming, DateTime now) async {
    final existing = await _existingStacks();
    final existingByIdentity = {
      for (final stack in existing)
        CardIdentity(stack.scryfallId, stack.finish): stack,
    };
    final incomingIdentities = incoming.map((r) => r.identity).toSet();

    // Delete ManaBox stacks absent from the incoming snapshot.
    final staleIds = existing
        .where((s) =>
            !incomingIdentities.contains(CardIdentity(s.scryfallId, s.finish)))
        .map((s) => s.id)
        .toList();
    if (staleIds.isNotEmpty) {
      await (_db.delete(_db.stacks)..where((s) => s.id.isIn(staleIds))).go();
    }

    for (final row in incoming) {
      final current = existingByIdentity[row.identity];
      if (current == null) {
        await _db.into(_db.stacks).insert(_freshCompanion(row, now));
      } else if (current.quantity != row.quantity ||
          current.condition != row.condition ||
          current.language != row.language) {
        // Keep id/createdAt — update in place.
        await (_db.update(_db.stacks)
              ..where((s) => s.id.equals(current.id)))
            .write(StacksCompanion(
          quantity: Value(row.quantity),
          condition: Value(row.condition),
          language: Value(row.language),
          updatedAt: Value(now),
        ));
      }
    }
  }

  Future<void> _commitAppend(
      List<MatchedStackRow> incoming, DateTime now) async {
    for (final row in incoming) {
      await _db.into(_db.stacks).insert(
            _freshCompanion(row, now),
            onConflict: DoUpdate(
              (old) => StacksCompanion.custom(
                quantity: old.quantity + Constant(row.quantity),
                updatedAt: Constant(now),
              ),
              target: [
                _db.stacks.scryfallId,
                _db.stacks.finish,
                _db.stacks.provenance,
              ],
            ),
          );
    }
  }

  Future<List<StackRow>> _existingStacks() {
    return (_db.select(_db.stacks)
          ..where((s) => s.provenance.equals(provenanceManaBox)))
        .get();
  }

  StacksCompanion _freshCompanion(MatchedStackRow row, DateTime now) {
    return StacksCompanion.insert(
      id: _uuid.v4(),
      scryfallId: row.identity.scryfallId,
      finish: row.identity.finish,
      quantity: row.quantity,
      condition: Value(row.condition),
      language: Value(row.language),
      provenance: provenanceManaBox,
      createdAt: now,
      updatedAt: now,
    );
  }
}

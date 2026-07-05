import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/user_database.dart';
import '../models/binder_position.dart';
import '../models/ordering.dart';

/// Derives the D9 pocket geometry from a binder row.
extension BinderGeometryX on Binder {
  BinderGeometry get geometry => BinderGeometry(
        rows: layoutRows,
        cols: layoutCols,
        pageCount: pageCount,
        doubleSided: doubleSided,
      );
}

/// Repository for binder definitions in the user database (D5/D6).
///
/// Owns the `binders` table: CRUD, the user-ordered allocation priority
/// (`priorityIndex`, 0 = filled first), and read access to committed
/// `binder_slots` rows for allocation input. Slot *writes* belong to the
/// commit engine.
///
/// [newId] and [now] are injectable for tests (drift stores datetimes at
/// second precision, so tests inject a controllable clock).
class BinderRepository {
  BinderRepository(
    this._db, {
    String Function()? newId,
    DateTime Function()? now,
  })  : _newId = newId ?? (() => const Uuid().v4()),
        _now = now ?? DateTime.now;

  final UserDatabase _db;
  final String Function() _newId;
  final DateTime Function() _now;

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Creates a binder at the END of the priority list (a new binder must
  /// not silently steal stacks from existing binders). Returns the new id.
  Future<String> createBinder({
    required String name,
    required String query,
    required int layoutRows,
    required int layoutCols,
    required int pageCount,
    required bool doubleSided,
    BinderAxis? groupBy,
    BinderAxis sortBy = BinderAxis.price,
    SortDirection sortDir = SortDirection.desc,
    bool isVirtual = false,
  }) async {
    final id = _newId();
    final now = _now();

    await _db.transaction(() async {
      final maxIndexExpr = _db.binders.priorityIndex.max();
      final maxQuery = _db.selectOnly(_db.binders)
        ..addColumns([maxIndexExpr]);
      final maxIndex = (await maxQuery.getSingle()).read(maxIndexExpr);

      await _db.into(_db.binders).insert(BindersCompanion.insert(
            id: id,
            name: name,
            query: query,
            priorityIndex: (maxIndex ?? -1) + 1,
            layoutRows: layoutRows,
            layoutCols: layoutCols,
            pageCount: pageCount,
            doubleSided: Value(doubleSided),
            groupBy: Value(groupBy),
            sortBy: Value(sortBy),
            sortDir: Value(sortDir),
            isVirtual: Value(isVirtual),
            createdAt: now,
            updatedAt: now,
          ));
    });

    return id;
  }

  /// Rewrites a binder's full definition (the editor always saves the whole
  /// form, so `groupBy: null` unambiguously means "no grouping"). Priority
  /// is managed separately via [reorderBinders].
  Future<void> updateBinder({
    required String id,
    required String name,
    required String query,
    required int layoutRows,
    required int layoutCols,
    required int pageCount,
    required bool doubleSided,
    required BinderAxis? groupBy,
    required BinderAxis sortBy,
    required SortDirection sortDir,
    required bool isVirtual,
  }) {
    return (_db.update(_db.binders)..where((b) => b.id.equals(id))).write(
      BindersCompanion(
        name: Value(name),
        query: Value(query),
        layoutRows: Value(layoutRows),
        layoutCols: Value(layoutCols),
        pageCount: Value(pageCount),
        doubleSided: Value(doubleSided),
        groupBy: Value(groupBy),
        sortBy: Value(sortBy),
        sortDir: Value(sortDir),
        isVirtual: Value(isVirtual),
        updatedAt: Value(_now()),
      ),
    );
  }

  /// Deletes the binder (slots cascade — PRAGMA foreign_keys is ON) and
  /// compacts the remaining priority indexes to 0..n-1.
  Future<void> deleteBinder(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.binders)..where((b) => b.id.equals(id))).go();
      final remaining = await _orderedBinders().get();
      for (var i = 0; i < remaining.length; i++) {
        if (remaining[i].priorityIndex == i) continue;
        await (_db.update(_db.binders)
              ..where((b) => b.id.equals(remaining[i].id)))
            .write(BindersCompanion(priorityIndex: Value(i)));
      }
    });
  }

  /// Persists a new priority order: [orderedIds] must be the FULL binder id
  /// list, top priority first. Rewrites `priorityIndex` to the list index,
  /// transactionally.
  Future<void> reorderBinders(List<String> orderedIds) {
    final now = _now();
    return _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.binders)
              ..where((b) => b.id.equals(orderedIds[i])))
            .write(BindersCompanion(
          priorityIndex: Value(i),
          updatedAt: Value(now),
        ));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  SimpleSelectStatement<$BindersTable, Binder> _orderedBinders() {
    return _db.select(_db.binders)
      ..orderBy([
        (b) => OrderingTerm.asc(b.priorityIndex),
        // Stable order even if priority indexes ever collide.
        (b) => OrderingTerm.asc(b.id),
      ]);
  }

  /// All binders in priority order (0 = filled first), live.
  Stream<List<Binder>> watchBinders() => _orderedBinders().watch();

  /// All binders in priority order, once.
  Future<List<Binder>> listBinders() => _orderedBinders().get();

  /// One binder by id, or null.
  Future<Binder?> getBinder(String id) {
    return (_db.select(_db.binders)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
  }

  /// All committed placements across binders, live — allocation input.
  Stream<List<BinderSlotRow>> watchAllSlots() =>
      _db.select(_db.binderSlots).watch();
}

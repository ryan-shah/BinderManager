import 'package:drift/drift.dart';

import '../../models/binder_position.dart';
import '../../models/card_identity.dart';
import '../../models/ordering.dart';

/// A binder definition: saved query + capacity + organization (D5/D6/D9).
///
/// `priorityIndex` is the binder's position in the user-ordered allocation
/// priority list (0 = filled first, D6). Capacity derives from
/// layoutRows×layoutCols × pageCount × sides — see `BinderGeometry`.
class Binders extends Table {
  /// Client-generated UUID v4 — stable across devices for later sync (D12).
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// The contents rule: a D5 query string through the shared engine.
  TextColumn get query => text()();

  /// Allocation priority position; lower fills first (D6).
  IntColumn get priorityIndex => integer()();

  /// Pocket grid per side: 2×2 / 3×3 / 4×4 (D9).
  IntColumn get layoutRows => integer()();
  IntColumn get layoutCols => integer()();

  /// Number of sheets; a double-sided sheet has pockets on both sides.
  IntColumn get pageCount => integer()();

  BoolColumn get doubleSided => boolean().withDefault(const Constant(true))();

  /// Grouping axis, or null for no grouping (D6).
  TextColumn get groupBy => textEnum<BinderAxis>().nullable()();

  /// Sort axis + direction; price-desc is the trade-binder default (D6).
  TextColumn get sortBy =>
      textEnum<BinderAxis>().withDefault(const Constant('price'))();
  TextColumn get sortDir =>
      textEnum<SortDirection>().withDefault(const Constant('desc'))();

  /// Virtual binders are non-consuming views (D6 overlap toggle).
  BoolColumn get isVirtual => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'binders';
}

/// A committed placement: quantity copies of one (printing, finish) stack
/// physically sleeved at an exact (page, side, pocket) (D7/D9).
///
/// Stacks are atomic (D6), so all copies of a stack share one pocket row.
@DataClassName('BinderSlotRow')
@TableIndex(name: 'idx_binder_slots_binder_id', columns: {#binderId})
@TableIndex(name: 'idx_binder_slots_scryfall_id', columns: {#scryfallId})
class BinderSlots extends Table {
  /// Client-generated UUID v4 (D12).
  TextColumn get id => text()();

  TextColumn get binderId =>
      text().references(Binders, #id, onDelete: KeyAction.cascade)();

  TextColumn get scryfallId => text()();
  TextColumn get finish => textEnum<Finish>()();
  IntColumn get quantity => integer()();

  /// 1-based sheet number.
  IntColumn get page => integer()();
  TextColumn get side => textEnum<PageSide>()();

  /// 1-based pocket within the side, reading order.
  IntColumn get pocket => integer()();

  /// Pinned cards are never moved by the engine (D7).
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'binder_slots';
}

/// D7 snapshot history: a checkpoint of the full committed binder state,
/// taken before each change event applies. Retention is capped/pruned by
/// the commit engine.
@DataClassName('SnapshotRow')
class Snapshots extends Table {
  /// Client-generated UUID v4 (D12).
  TextColumn get id => text()();

  /// Human label for what triggered the checkpoint (a `ChangeTrigger`
  /// label, e.g. "Price refresh").
  TextColumn get triggerLabel => text()();

  /// The serialized committed state (JSON) — binder definitions, priority
  /// order, and committed placements. Binder state is small (D12).
  TextColumn get state => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'snapshots';
}

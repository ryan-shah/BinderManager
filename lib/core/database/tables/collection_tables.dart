import 'package:drift/drift.dart';

import '../../models/card_identity.dart';

/// A stack of physical copies of one (printing, finish) identity.
///
/// The canonical identity is (scryfall_id, finish) per D2; condition and
/// language are soft attributes carried on the stack, not identity keys.
/// Provenance records which import source owns the stack (D8) so snapshots
/// from different apps never stomp each other — hence the composite unique
/// key includes it.
@DataClassName('StackRow')
@TableIndex(name: 'idx_stacks_scryfall_id', columns: {#scryfallId})
@TableIndex(name: 'idx_stacks_provenance', columns: {#provenance})
class Stacks extends Table {
  /// Client-generated UUID v4 — stable across devices for later sync (D12).
  TextColumn get id => text()();

  TextColumn get scryfallId => text()();
  TextColumn get finish => textEnum<Finish>()();
  IntColumn get quantity => integer()();

  /// ManaBox condition string (e.g. `near_mint`), if known.
  TextColumn get condition => text().nullable()();

  /// Two-letter language code (e.g. `en`), if known.
  TextColumn get language => text().nullable()();

  /// Import source that owns this stack, e.g. `manabox`, `deck-import`.
  TextColumn get provenance => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {scryfallId, finish, provenance},
      ];

  @override
  String get tableName => 'stacks';
}

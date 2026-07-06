import 'package:drift/drift.dart';

import '../models/binder_position.dart';
import '../models/card_identity.dart';
import '../models/ordering.dart';
import 'tables/binder_tables.dart';
import 'tables/collection_tables.dart';
import 'tables/deck_tables.dart';

part 'user_database.g.dart';

/// The durable user database: collection stacks, decks, deck entries,
/// binders, committed placements, and snapshot history.
///
/// Kept separate from the replaceable corpus database (D12) — the corpus
/// can be wiped and re-downloaded at any time without touching user data.
/// Domain queries live in feature-owned repository classes, not here.
@DriftDatabase(
  tables: [Stacks, Decks, DeckEntries, Binders, BinderSlots, Snapshots],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2 (Phase 4): binder definitions, committed placements, and
            // D7 snapshot history.
            await m.createTable(binders);
            await m.createTable(binderSlots);
            await m.createTable(snapshots);
            await m.createIndex(idxBinderSlotsBinderId);
            await m.createIndex(idxBinderSlotsScryfallId);
          }
        },
        beforeOpen: (details) async {
          // Off by default per connection; without it, cascade deletes on
          // deck_entries and binder_slots silently no-op.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

import 'package:drift/drift.dart';

import '../models/card_identity.dart';
import 'tables/collection_tables.dart';
import 'tables/deck_tables.dart';

part 'user_database.g.dart';

/// The durable user database: collection stacks, decks, and deck entries.
///
/// Kept separate from the replaceable corpus database (D12) — the corpus
/// can be wiped and re-downloaded at any time without touching user data.
/// Domain queries live in feature-owned repository classes, not here.
@DriftDatabase(tables: [Stacks, Decks, DeckEntries])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Off by default per connection; without it, cascade deletes on
          // deck_entries silently no-op.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

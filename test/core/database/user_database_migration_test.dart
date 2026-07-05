import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/models/ordering.dart';

/// Hand-written snapshot of the schema UserDatabase shipped at v1
/// (Phase 3): stacks, decks, deck_entries and their indexes. The v1→v2
/// migration must run against exactly this starting point.
void _createV1Schema(sqlite3.Database db) {
  db.execute('''
CREATE TABLE stacks (
  id TEXT NOT NULL PRIMARY KEY,
  scryfall_id TEXT NOT NULL,
  finish TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  condition TEXT NULL,
  language TEXT NULL,
  provenance TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (scryfall_id, finish, provenance)
);
CREATE INDEX idx_stacks_scryfall_id ON stacks (scryfall_id);
CREATE INDEX idx_stacks_provenance ON stacks (provenance);
CREATE TABLE decks (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  format TEXT NULL,
  is_assembled INTEGER NOT NULL DEFAULT 1,
  is_shared INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE deck_entries (
  id TEXT NOT NULL PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES decks (id) ON DELETE CASCADE,
  scryfall_id TEXT NOT NULL,
  finish TEXT NULL,
  card_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  section TEXT NOT NULL,
  is_shared INTEGER NOT NULL DEFAULT 0,
  is_unowned INTEGER NOT NULL DEFAULT 0,
  printing_specified INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_deck_entries_deck_id ON deck_entries (deck_id);
CREATE INDEX idx_deck_entries_scryfall_id ON deck_entries (scryfall_id);
''');

  // Existing user data that must survive the migration.
  db.execute('''
INSERT INTO stacks (id, scryfall_id, finish, quantity, provenance,
  created_at, updated_at)
VALUES ('stack-1', 'bolt-1', 'foil', 4, 'manabox', 1780000000, 1780000000);
''');

  db.execute('PRAGMA user_version = 1;');
}

void main() {
  late UserDatabase db;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory(setup: _createV1Schema));
  });

  tearDown(() async {
    await db.close();
  });

  group('v1 → v2 migration', () {
    test('bumps user_version to 2', () async {
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data.values.first, 2);
    });

    test('preserves existing v1 data', () async {
      final stacks = await db.select(db.stacks).get();
      expect(stacks, hasLength(1));
      expect(stacks.first.scryfallId, 'bolt-1');
      expect(stacks.first.finish, Finish.foil);
      expect(stacks.first.quantity, 4);
    });

    test('creates usable binders, binder_slots, and snapshots tables',
        () async {
      final now = DateTime.utc(2026, 7, 4);

      await db.into(db.binders).insert(BindersCompanion.insert(
            id: 'binder-1',
            name: 'Trade binder',
            query: 'unused:true usd>5',
            priorityIndex: 0,
            layoutRows: 3,
            layoutCols: 3,
            pageCount: 20,
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.binderSlots).insert(BinderSlotsCompanion.insert(
            id: 'slot-1',
            binderId: 'binder-1',
            scryfallId: 'bolt-1',
            finish: Finish.foil,
            quantity: 4,
            page: 3,
            side: PageSide.back,
            pocket: 5,
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.snapshots).insert(SnapshotsCompanion.insert(
            id: 'snap-1',
            triggerLabel: 'Rule edit',
            state: '{"binders":[]}',
            createdAt: now,
          ));

      final binder = await db.select(db.binders).getSingle();
      expect(binder.doubleSided, isTrue);
      expect(binder.sortBy, BinderAxis.price);
      expect(binder.sortDir, SortDirection.desc);
      expect(binder.groupBy, isNull);
      expect(binder.isVirtual, isFalse);

      final slot = await db.select(db.binderSlots).getSingle();
      expect(slot.side, PageSide.back);
      expect(slot.isPinned, isFalse);

      final snapshot = await db.select(db.snapshots).getSingle();
      expect(snapshot.triggerLabel, 'Rule edit');
    });

    test('creates the binder_slots indexes', () async {
      final rows = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND tbl_name = 'binder_slots'",
      ).get();
      final names = rows.map((r) => r.data.values.first).toSet();
      expect(names, containsAll(['idx_binder_slots_binder_id',
          'idx_binder_slots_scryfall_id']));
    });

    test('binder deletion cascades to its slots after migration', () async {
      final now = DateTime.utc(2026, 7, 4);
      await db.into(db.binders).insert(BindersCompanion.insert(
            id: 'binder-1',
            name: 'Trade binder',
            query: 'unused:true',
            priorityIndex: 0,
            layoutRows: 2,
            layoutCols: 2,
            pageCount: 10,
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.binderSlots).insert(BinderSlotsCompanion.insert(
            id: 'slot-1',
            binderId: 'binder-1',
            scryfallId: 'bolt-1',
            finish: Finish.foil,
            quantity: 4,
            page: 1,
            side: PageSide.front,
            pocket: 1,
            createdAt: now,
            updatedAt: now,
          ));

      await (db.delete(db.binders)..where((b) => b.id.equals('binder-1')))
          .go();

      expect(await db.select(db.binderSlots).get(), isEmpty);
    });
  });
}

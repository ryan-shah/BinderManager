import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';

import '../database/tables/deck_tables.dart';
import '../database/user_database.dart';

/// Owned/reserved/idle quantities per printing (scryfallId).
///
/// Finishes POOL: owned quantities sum across finishes and provenances,
/// because v1 decklists carry no finish (D3) so any physical copy of the
/// printing can fill a deck slot.
class ReservationSummary {
  ReservationSummary({
    required Map<String, int> ownedByPrinting,
    required Map<String, int> reservedByPrinting,
  })  : ownedByPrinting = Map.unmodifiable(ownedByPrinting),
        reservedByPrinting = Map.unmodifiable(reservedByPrinting);

  final Map<String, int> ownedByPrinting;
  final Map<String, int> reservedByPrinting;

  int ownedOf(String scryfallId) => ownedByPrinting[scryfallId] ?? 0;

  int reservedOf(String scryfallId) => reservedByPrinting[scryfallId] ?? 0;

  /// Copies free for binders: `max(0, owned - reserved)` — clamped so
  /// over-reservation (decks wanting more than owned) never goes negative.
  int idleOf(String scryfallId) =>
      max(0, ownedOf(scryfallId) - reservedOf(scryfallId));

  /// Printings with at least one owned copy.
  Set<String> get ownedIds => {
        for (final entry in ownedByPrinting.entries)
          if (entry.value > 0) entry.key,
      };

  /// Printings with at least one idle (unreserved) copy.
  Set<String> get idleIds => {
        for (final id in ownedByPrinting.keys)
          if (idleOf(id) > 0) id,
      };
}

/// Computes reservations per printing (D3 semantics, LOCKED):
///
/// - Only entries whose deck is **assembled** count; maybeboard never
///   reserves; sideboard reserves like main.
/// - Effective shared = `deck.isShared || entry.isShared`.
/// - A deck's multiple entries of the same printing sum (within their
///   shared/non-shared bucket) before pooling.
/// - Per printing: `reserved = Σ(per-deck non-shared qty) +
///   max(per-deck shared qty)` — union-max across the shared pool.
/// - `isUnowned` entries ARE included (conservative; the idle clamp keeps
///   the excess harmless).
ReservationSummary computeReservations({
  required List<StackRow> stacks,
  required List<Deck> decks,
  required List<DeckEntryRow> entries,
}) {
  final owned = <String, int>{};
  for (final stack in stacks) {
    owned[stack.scryfallId] = (owned[stack.scryfallId] ?? 0) + stack.quantity;
  }

  final deckById = {for (final d in decks) d.id: d};

  // printing → deckId → summed qty, split by effective shared-ness.
  final nonSharedByDeck = <String, Map<String, int>>{};
  final sharedByDeck = <String, Map<String, int>>{};

  for (final entry in entries) {
    final deck = deckById[entry.deckId];
    if (deck == null || !deck.isAssembled) continue;
    if (entry.section == DeckSection.maybeboard) continue;

    final isShared = deck.isShared || entry.isShared;
    final bucket = isShared ? sharedByDeck : nonSharedByDeck;
    final perDeck = bucket.putIfAbsent(entry.scryfallId, () => {});
    perDeck[entry.deckId] = (perDeck[entry.deckId] ?? 0) + entry.quantity;
  }

  final reserved = <String, int>{};
  final printings = {...nonSharedByDeck.keys, ...sharedByDeck.keys};
  for (final printing in printings) {
    final nonSharedSum = (nonSharedByDeck[printing]?.values ?? const [])
        .fold<int>(0, (a, b) => a + b);
    final sharedMax = (sharedByDeck[printing]?.values ?? const [])
        .fold<int>(0, max);
    reserved[printing] = nonSharedSum + sharedMax;
  }

  return ReservationSummary(
    ownedByPrinting: owned,
    reservedByPrinting: reserved,
  );
}

/// Emits a fresh [ReservationSummary] immediately and again whenever the
/// stacks, decks, or deck_entries tables change.
///
/// Implemented with an explicit controller (not `async*`): a generator
/// suspended waiting on the table-update stream would only observe a
/// cancellation at its next event, so cancelling it could hang forever on
/// a quiet database.
Stream<ReservationSummary> watchReservations(UserDatabase db) {
  Future<ReservationSummary> load() async {
    final stacks = await db.select(db.stacks).get();
    final decks = await db.select(db.decks).get();
    final entries = await db.select(db.deckEntries).get();
    return computeReservations(stacks: stacks, decks: decks, entries: entries);
  }

  late final StreamController<ReservationSummary> controller;
  StreamSubscription<void>? updates;
  var loading = false;
  var dirty = false;

  // Serializes loads: a notification arriving mid-load flags a re-run
  // instead of interleaving queries, keeping emissions in order.
  Future<void> reload() async {
    if (loading) {
      dirty = true;
      return;
    }
    loading = true;
    try {
      do {
        dirty = false;
        final summary = await load();
        if (!controller.isClosed) controller.add(summary);
      } while (dirty);
    } catch (e, s) {
      if (!controller.isClosed) controller.addError(e, s);
    } finally {
      loading = false;
    }
  }

  controller = StreamController<ReservationSummary>(
    onListen: () {
      reload();
      updates = db
          .tableUpdates(
            TableUpdateQuery.onAllTables(
              [db.stacks, db.decks, db.deckEntries],
            ),
          )
          .listen((_) => reload());
    },
    onCancel: () async {
      await updates?.cancel();
      await controller.close();
    },
  );

  return controller.stream;
}

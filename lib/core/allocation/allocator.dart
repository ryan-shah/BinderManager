/// The D6/D7/D9 allocation engine: walks binders in priority order, claims
/// atomic (printing, finish) stacks from the idle pool, ranks against
/// capacity, and assigns exact (page, side, pocket) positions.
///
/// Pure Dart — no database access. The caller supplies each binder's match
/// set (corpus rows from the query engine), the D13 per-stack idle pool
/// ([StackIdleSummary]), and existing committed slots.
///
/// ## Semantics (normative decisions, D6/D7/D9)
///
/// - **Priority walk:** binders are processed in list order (the caller
///   orders by `priorityIndex`). Each consuming binder claims the stacks it
///   *places* from the remaining pool; a stack lands in exactly one binder.
/// - **Atomic stacks:** all idle copies of one (printing, finish) stack
///   travel together and occupy ONE pocket. Different printings/finishes of
///   the same card may split across binders.
/// - **Overflow does not consume:** a stack that matched but didn't fit
///   stays in the pool for lower-priority binders (it is not physically in
///   this binder). A stack consumed by a higher-priority binder is simply
///   absent here — it is neither placed nor overflow.
/// - **Virtual binders** are non-consuming views: they draw placements from
///   the FULL idle pool (ignoring consumption by higher-priority binders)
///   and remove nothing from it.
/// - **Selection:** pinned committed stacks that are still eligible get
///   guaranteed seats first (a physically locked pocket can't be evicted by
///   rank); remaining capacity goes to the top-ranked candidates by the
///   binder's sort. Everything else is overflow, ranked by the same sort.
/// - **Pinning:** a pinned slot keeps its exact committed position in both
///   append and reflow modes. Pinning prevents *moving* — a pinned stack
///   whose identity no longer matches the query, or has no idle copies
///   left, is dropped like any other. A pinned slot whose position falls
///   outside the current geometry (the binder shrank) cannot keep it and is
///   ignored as a committed anchor.
/// - **Append-within-group (default):** committed stacks that are still
///   selected keep their exact committed positions — never repositioned.
///   Newcomers go to the first free pocket strictly after their group's
///   last occupied pocket (the group's committed anchor, advancing as
///   newcomers are placed); a group with no members yet starts after the
///   last pocket occupied by earlier canonical groups. When no free pocket
///   exists after the anchor (tail full / region fragmented), placement
///   wraps to the earliest free pocket in the binder. Removed stacks leave
///   holes; append never backfills them mid-group — Reflow does.
/// - **Reflow (opt-in, per binder):** all positions are recomputed in
///   perfect (group canonical order, in-group sort) order in D9 fill order,
///   flowing around pinned slots, which keep their exact positions.
/// - **Determinism:** every ordering ends with a fixed
///   (scryfallId asc, finish enum order) tie-break, so equal sort keys
///   still produce a total order.
///
/// ## Canonical group orders (documented per axis)
///
/// - `cardType`: creature, planeswalker, instant, sorcery, artifact,
///   enchantment, land, battle, other. The bucket derives from the
///   card-type portion of the type line (left of the em dash, per face) —
///   first match in that same order wins, so "Artifact Creature" buckets as
///   creature and "Artifact Land" as artifact.
/// - `color`: W, U, B, R, G, multicolor, colorless (from color identity).
/// - `setCode`: alphabetical ascending.
/// - `rarity`: mythic, rare, uncommon, common, other (value order).
/// - `price`: descending value bands — $100+, $20–100, $5–20, $1–5, <$1
///   (finish-specific price, null = 0).
/// - `name`: first letter A–Z, then # for non-alphabetic.
/// - `finish`: nonfoil, foil, etched (enum order).
///
/// Group order is canonical and independent of `sortDir`, which only
/// affects the sort *within* groups (and capacity/overflow ranking).
library;

import 'dart:collection';
import 'dart:math';

import '../database/corpus_database.dart';
import '../database/user_database.dart';
import '../models/binder_diff.dart';
import '../models/binder_position.dart';
import '../models/card_identity.dart';
import '../models/ordering.dart';
import 'reservation.dart';

// ---------------------------------------------------------------------------
// Card-type buckets (D5/D6 "card type" axis)
// ---------------------------------------------------------------------------

/// The card-type grouping/sorting buckets, in canonical order.
enum CardTypeBucket {
  creature,
  planeswalker,
  instant,
  sorcery,
  artifact,
  enchantment,
  land,
  battle,
  other;

  String get label => switch (this) {
        CardTypeBucket.creature => 'Creature',
        CardTypeBucket.planeswalker => 'Planeswalker',
        CardTypeBucket.instant => 'Instant',
        CardTypeBucket.sorcery => 'Sorcery',
        CardTypeBucket.artifact => 'Artifact',
        CardTypeBucket.enchantment => 'Enchantment',
        CardTypeBucket.land => 'Land',
        CardTypeBucket.battle => 'Battle',
        CardTypeBucket.other => 'Other',
      };
}

/// Derives the [CardTypeBucket] for a type line.
///
/// Only the card-type portion counts: for each face (split on `//`), the
/// text left of the em dash — subtypes like "Island" never match. The first
/// bucket in enum order present among those words wins ("Artifact Creature"
/// → creature; "Artifact Land" → artifact).
CardTypeBucket cardTypeBucketOf(String typeLine) {
  final words = <String>{};
  for (final face in typeLine.split('//')) {
    final typePart = face.split('—').first;
    for (final word in typePart.trim().toLowerCase().split(RegExp(r'\s+'))) {
      if (word.isNotEmpty) words.add(word);
    }
  }
  for (final bucket in CardTypeBucket.values) {
    if (bucket == CardTypeBucket.other) break;
    if (words.contains(bucket.name)) return bucket;
  }
  return CardTypeBucket.other;
}

// ---------------------------------------------------------------------------
// Color groups
// ---------------------------------------------------------------------------

const _colorOrder = ['W', 'U', 'B', 'R', 'G'];

/// Canonical color-group index from a comma-separated color identity:
/// W=0, U=1, B=2, R=3, G=4, multicolor=5, colorless=6.
int colorGroupIndexOf(String colorIdentity) {
  final colors = colorIdentity
      .split(',')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();
  if (colors.isEmpty) return 6;
  if (colors.length > 1) return 5;
  final index = _colorOrder.indexOf(colors.first.toUpperCase());
  return index >= 0 ? index : 6;
}

// ---------------------------------------------------------------------------
// Request / result types
// ---------------------------------------------------------------------------

/// One binder's inputs to [allocate]. Build these in priority order.
class BinderAllocationRequest {
  const BinderAllocationRequest({
    required this.binderId,
    required this.geometry,
    this.groupBy,
    this.sortBy = BinderAxis.price,
    this.sortDir = SortDirection.desc,
    this.isVirtual = false,
    this.matches = const [],
    this.committedSlots = const [],
    this.reflow = false,
  });

  final String binderId;
  final BinderGeometry geometry;

  /// Grouping axis; null = no grouping (one section).
  final BinderAxis? groupBy;

  final BinderAxis sortBy;
  final SortDirection sortDir;

  /// Non-consuming view (D6 overlap toggle).
  final bool isVirtual;

  /// Corpus rows matching this binder's query (the caller runs the query
  /// engine). Cards without idle stacks are ignored, so pre-restricting the
  /// query to owned cards is a pure optimization.
  final List<Card> matches;

  /// This binder's committed placements, for append-within-group anchoring
  /// and pin handling.
  final List<BinderSlotRow> committedSlots;

  /// Opt-in: recompute all positions in perfect group+sort order (pinned
  /// slots keep their exact positions).
  final bool reflow;
}

/// One binder's allocation outcome.
class BinderAllocation {
  BinderAllocation({
    required this.binderId,
    required List<PlannedPlacement> placements,
    required List<OverflowEntry> overflow,
  })  : placements = List.unmodifiable(placements),
        overflow = List.unmodifiable(overflow);

  final String binderId;

  /// Planned placements in D9 fill order (page → front-then-back → pocket).
  final List<PlannedPlacement> placements;

  /// Stacks that matched but didn't fit, ranked by the binder's sort.
  final List<OverflowEntry> overflow;

  /// Eligible stacks at this binder's turn (placed + overflow).
  int get matchCount => placements.length + overflow.length;
}

/// The outcome of one allocation pass across all binders.
class AllocationResult {
  AllocationResult({required List<BinderAllocation> allocations})
      : allocations = List.unmodifiable(allocations);

  static final empty = AllocationResult(allocations: const []);

  /// Per-binder allocations, in the walked (priority) order.
  final List<BinderAllocation> allocations;

  late final Map<String, BinderAllocation> byBinder = Map.unmodifiable({
    for (final allocation in allocations) allocation.binderId: allocation,
  });

  BinderAllocation? forBinder(String binderId) => byBinder[binderId];
}

// ---------------------------------------------------------------------------
// Allocation
// ---------------------------------------------------------------------------

/// Runs the D6 priority walk over [binders] (already in priority order)
/// against the D13 per-stack [idle] pool.
AllocationResult allocate({
  required List<BinderAllocationRequest> binders,
  required StackIdleSummary idle,
}) {
  // Stacks still unclaimed by consuming binders.
  final remaining = <CardIdentity, int>{
    for (final entry in idle.idleByStack.entries)
      if (entry.value > 0) entry.key: entry.value,
  };

  final allocations = <BinderAllocation>[];
  for (final request in binders) {
    final allocation = _allocateBinder(
      request,
      poolOf: request.isVirtual
          ? idle.idleOf
          : (identity) => remaining[identity] ?? 0,
    );
    if (!request.isVirtual) {
      for (final placement in allocation.placements) {
        remaining.remove(placement.identity);
      }
    }
    allocations.add(allocation);
  }

  return AllocationResult(allocations: allocations);
}

BinderAllocation _allocateBinder(
  BinderAllocationRequest request, {
  required int Function(CardIdentity) poolOf,
}) {
  final geometry = request.geometry;
  final capacity = geometry.capacity;

  // -- Candidates: matched stacks with idle copies. The pool (not the
  // corpus finishes column) decides which finishes exist — only owned
  // finishes can be idle.
  final seenPrintings = <String>{};
  final candidates = <_Candidate>[];
  for (final card in request.matches) {
    if (!seenPrintings.add(card.scryfallId)) continue;
    for (final finish in Finish.values) {
      final identity = CardIdentity(card.scryfallId, finish);
      final quantity = poolOf(identity);
      if (quantity > 0) {
        candidates.add(_Candidate(card, identity, quantity));
      }
    }
  }

  final rank = _rankComparator(request.sortBy, request.sortDir);
  candidates.sort(rank);
  final candidateIdentities = {for (final c in candidates) c.identity};

  // -- Committed anchors: exact ordinals per identity, restricted to
  // positions that exist in the current geometry. Defensive dedupe: one
  // ordinal per identity (stacks are atomic) and one identity per ordinal —
  // first in fill order wins.
  final committedOrdinals = <CardIdentity, int>{};
  final pinnedIdentities = <CardIdentity>{};
  final claimedOrdinals = <int>{};
  final validSlots = request.committedSlots
      .map((slot) {
        final position =
            BinderPosition(page: slot.page, side: slot.side, pocket: slot.pocket);
        return geometry.contains(position)
            ? (slot: slot, ordinal: geometry.ordinalOf(position))
            : null;
      })
      .nonNulls
      .toList()
    ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
  for (final entry in validSlots) {
    final identity = CardIdentity(entry.slot.scryfallId, entry.slot.finish);
    if (committedOrdinals.containsKey(identity)) continue;
    if (!claimedOrdinals.add(entry.ordinal)) continue;
    committedOrdinals[identity] = entry.ordinal;
    if (entry.slot.isPinned && candidateIdentities.contains(identity)) {
      pinnedIdentities.add(identity);
    }
  }

  // -- Selection: pinned stacks get guaranteed seats, then rank fills the
  // rest. Overflow is everything left, ranked by the binder's sort.
  final selected = <_Candidate>[];
  final overflow = <_Candidate>[];
  for (final pinnedFirst in [true, false]) {
    for (final candidate in candidates) {
      if (pinnedIdentities.contains(candidate.identity) != pinnedFirst) {
        continue;
      }
      (selected.length < capacity ? selected : overflow).add(candidate);
    }
  }
  overflow.sort(rank);

  // -- Position assignment.
  final placedOrdinals = request.reflow
      ? _assignReflow(request, selected, committedOrdinals, pinnedIdentities)
      : _assignAppend(request, selected, committedOrdinals);

  final placements = [
    for (final entry in placedOrdinals.entries)
      PlannedPlacement(
        binderId: request.binderId,
        identity: entry.key.identity,
        quantity: entry.key.quantity,
        position: geometry.positionAt(entry.value),
      ),
  ]..sort((a, b) => a.position.compareTo(b.position));

  return BinderAllocation(
    binderId: request.binderId,
    placements: placements,
    overflow: [
      for (final candidate in overflow)
        OverflowEntry(
          binderId: request.binderId,
          identity: candidate.identity,
          quantity: candidate.quantity,
        ),
    ],
  );
}

/// Append-within-group (D7 default): retained committed stacks keep their
/// exact ordinals; newcomers append after their group's last occupied
/// pocket, wrapping to the earliest free pocket when the tail is full.
Map<_Candidate, int> _assignAppend(
  BinderAllocationRequest request,
  List<_Candidate> selected,
  Map<CardIdentity, int> committedOrdinals,
) {
  final capacity = request.geometry.capacity;
  final placed = <_Candidate, int>{};
  final occupied = <int>{};

  // Group members in canonical order; newcomers stay in rank order within
  // each group (selection order preserves it).
  final groups = SplayTreeMap<_GroupKey, _Group>();
  for (final candidate in selected) {
    final key = _groupKeyOf(candidate, request.groupBy);
    final group = groups.putIfAbsent(key, _Group.new);
    final ordinal = committedOrdinals[candidate.identity];
    if (ordinal != null) {
      // Retained: keeps its exact committed position, always.
      placed[candidate] = ordinal;
      occupied.add(ordinal);
      group.retainedOrdinals.add(ordinal);
    } else {
      group.newcomers.add(candidate);
    }
  }

  // Highest ordinal placed by groups processed so far — the starting anchor
  // for a group with no committed members.
  var lastPlacedSoFar = -1;
  for (final group in groups.values) {
    var anchor = group.retainedOrdinals.isNotEmpty
        ? group.retainedOrdinals.reduce(max)
        : lastPlacedSoFar;
    for (final candidate in group.newcomers) {
      final ordinal = _nextFree(occupied, anchor + 1, capacity) ??
          _nextFree(occupied, 0, capacity)!;
      placed[candidate] = ordinal;
      occupied.add(ordinal);
      anchor = ordinal;
    }
    lastPlacedSoFar = max(
      lastPlacedSoFar,
      [anchor, ...group.retainedOrdinals].reduce(max),
    );
  }

  return placed;
}

/// Reflow (opt-in): perfect (group canonical, in-group sort) order in D9
/// fill order, flowing around pinned slots which keep exact positions.
Map<_Candidate, int> _assignReflow(
  BinderAllocationRequest request,
  List<_Candidate> selected,
  Map<CardIdentity, int> committedOrdinals,
  Set<CardIdentity> pinnedIdentities,
) {
  final capacity = request.geometry.capacity;
  final placed = <_Candidate, int>{};
  final occupied = <int>{};

  final flowing = <_Candidate>[];
  for (final candidate in selected) {
    if (pinnedIdentities.contains(candidate.identity)) {
      final ordinal = committedOrdinals[candidate.identity]!;
      placed[candidate] = ordinal;
      occupied.add(ordinal);
    } else {
      flowing.add(candidate);
    }
  }

  final rank = _rankComparator(request.sortBy, request.sortDir);
  flowing.sort((a, b) {
    final byGroup = _groupKeyOf(a, request.groupBy)
        .compareTo(_groupKeyOf(b, request.groupBy));
    if (byGroup != 0) return byGroup;
    return rank(a, b);
  });

  var cursor = 0;
  for (final candidate in flowing) {
    final ordinal = _nextFree(occupied, cursor, capacity)!;
    placed[candidate] = ordinal;
    occupied.add(ordinal);
    cursor = ordinal + 1;
  }

  return placed;
}

/// First free ordinal in `[from, capacity)`, or null.
int? _nextFree(Set<int> occupied, int from, int capacity) {
  for (var ordinal = max(0, from); ordinal < capacity; ordinal++) {
    if (!occupied.contains(ordinal)) return ordinal;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Candidates, group keys, comparators
// ---------------------------------------------------------------------------

class _Candidate {
  _Candidate(this.card, this.identity, this.quantity);

  final Card card;
  final CardIdentity identity;

  /// Idle copies at claim time — the whole stack travels together.
  final int quantity;
}

class _Group {
  final List<int> retainedOrdinals = [];
  final List<_Candidate> newcomers = [];
}

/// A group's canonical position: an int bucket plus a text key (only the
/// set axis uses text). Natural ascending order = canonical order.
class _GroupKey implements Comparable<_GroupKey> {
  const _GroupKey(this.bucket, [this.text = '']);

  final int bucket;
  final String text;

  @override
  int compareTo(_GroupKey other) {
    final byBucket = bucket.compareTo(other.bucket);
    if (byBucket != 0) return byBucket;
    return text.compareTo(other.text);
  }

  @override
  bool operator ==(Object other) =>
      other is _GroupKey && bucket == other.bucket && text == other.text;

  @override
  int get hashCode => Object.hash(bucket, text);
}

_GroupKey _groupKeyOf(_Candidate candidate, BinderAxis? axis) {
  final card = candidate.card;
  return switch (axis) {
    null => const _GroupKey(0),
    BinderAxis.cardType => _GroupKey(cardTypeBucketOf(card.typeLine).index),
    BinderAxis.color => _GroupKey(colorGroupIndexOf(card.colorIdentity)),
    BinderAxis.setCode => _GroupKey(0, card.setCode.toLowerCase()),
    BinderAxis.rarity => _GroupKey(_rarityRankOf(card.rarity)),
    BinderAxis.price =>
      _GroupKey(_priceBandOf(_priceOf(card, candidate.identity.finish))),
    BinderAxis.name => _GroupKey(_nameGroupOf(card.name)),
    BinderAxis.finish => _GroupKey(candidate.identity.finish.index),
  };
}

/// Finish-specific D4 price; null = 0.
double _priceOf(Card card, Finish finish) =>
    switch (finish) {
      Finish.nonfoil => card.priceUsd,
      Finish.foil => card.priceUsdFoil,
      Finish.etched => card.priceUsdEtched,
    } ??
    0;

/// Mythic ranks first (value order), matching the engine's rarity ORDER BY.
int _rarityRankOf(String rarity) => switch (rarity.toLowerCase()) {
      'mythic' => 0,
      'rare' => 1,
      'uncommon' => 2,
      'common' => 3,
      _ => 4,
    };

/// Descending value bands: $100+, $20–100, $5–20, $1–5, <$1.
int _priceBandOf(double price) {
  if (price >= 100) return 0;
  if (price >= 20) return 1;
  if (price >= 5) return 2;
  if (price >= 1) return 3;
  return 4;
}

/// A–Z → 0–25; anything else → 26 ('#').
int _nameGroupOf(String name) {
  if (name.isEmpty) return 26;
  final code = name[0].toUpperCase().codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5A) ? code - 0x41 : 26;
}

int _compareOnAxis(_Candidate a, _Candidate b, BinderAxis axis) {
  switch (axis) {
    case BinderAxis.cardType:
      return cardTypeBucketOf(a.card.typeLine)
          .index
          .compareTo(cardTypeBucketOf(b.card.typeLine).index);
    case BinderAxis.color:
      return colorGroupIndexOf(a.card.colorIdentity)
          .compareTo(colorGroupIndexOf(b.card.colorIdentity));
    case BinderAxis.setCode:
      final bySet =
          a.card.setCode.toLowerCase().compareTo(b.card.setCode.toLowerCase());
      if (bySet != 0) return bySet;
      return _compareCollector(a.card.collectorNumber, b.card.collectorNumber);
    case BinderAxis.rarity:
      return _rarityRankOf(a.card.rarity)
          .compareTo(_rarityRankOf(b.card.rarity));
    case BinderAxis.price:
      return _priceOf(a.card, a.identity.finish)
          .compareTo(_priceOf(b.card, b.identity.finish));
    case BinderAxis.name:
      return a.card.name.toLowerCase().compareTo(b.card.name.toLowerCase());
    case BinderAxis.finish:
      return a.identity.finish.index.compareTo(b.identity.finish.index);
  }
}

/// Collector numbers compare numerically first ("2" before "10"), then as
/// text (suffixes like "146a").
int _compareCollector(String a, String b) {
  final numA = int.tryParse(RegExp(r'^\d+').firstMatch(a)?.group(0) ?? '');
  final numB = int.tryParse(RegExp(r'^\d+').firstMatch(b)?.group(0) ?? '');
  if (numA != null && numB != null && numA != numB) {
    return numA.compareTo(numB);
  }
  return a.compareTo(b);
}

/// The binder's sort with the fixed deterministic tail: sortBy/sortDir,
/// then (scryfallId asc, finish enum order asc) regardless of direction.
Comparator<_Candidate> _rankComparator(
  BinderAxis sortBy,
  SortDirection sortDir,
) {
  return (a, b) {
    var byAxis = _compareOnAxis(a, b, sortBy);
    if (sortDir == SortDirection.desc) byAxis = -byAxis;
    if (byAxis != 0) return byAxis;
    final byId = a.identity.scryfallId.compareTo(b.identity.scryfallId);
    if (byId != 0) return byId;
    return a.identity.finish.index.compareTo(b.identity.finish.index);
  };
}

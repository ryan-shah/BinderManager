/// The shared diff data model where allocation (Agent G) and the commit
/// engine (Agent H) meet (D7).
///
/// The allocator emits [PlannedPlacement]s and [OverflowEntry]s; the commit
/// engine diffs planned placements against committed `binder_slots` rows and
/// stages [BinderDiffEntry]s for the change-review screen.
library;

import 'card_identity.dart';
import 'binder_position.dart';

/// What kind of change a diff row describes (D7).
enum DiffType { add, remove, move }

/// The mutating event that staged a diff (D7).
///
/// Every trigger checkpoints a snapshot before its changes apply; the label
/// is what the snapshots table and the change-review header display.
enum ChangeTrigger {
  collectionImport,
  deckChange,
  priceRefresh,
  priorityReorder,
  ruleEdit,
  manual;

  String get label => switch (this) {
        ChangeTrigger.collectionImport => 'Collection import',
        ChangeTrigger.deckChange => 'Deck change',
        ChangeTrigger.priceRefresh => 'Price refresh',
        ChangeTrigger.priorityReorder => 'Priority reorder',
        ChangeTrigger.ruleEdit => 'Rule edit',
        ChangeTrigger.manual => 'Manual change',
      };
}

/// One (printing, finish) stack planned into one pocket of one binder —
/// the allocator's output unit (D6: stacks are atomic, so all [quantity]
/// copies share the pocket).
class PlannedPlacement {
  const PlannedPlacement({
    required this.binderId,
    required this.identity,
    required this.quantity,
    required this.position,
  });

  final String binderId;
  final CardIdentity identity;
  final int quantity;
  final BinderPosition position;

  String get scryfallId => identity.scryfallId;
  Finish get finish => identity.finish;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannedPlacement &&
          runtimeType == other.runtimeType &&
          binderId == other.binderId &&
          identity == other.identity &&
          quantity == other.quantity &&
          position == other.position;

  @override
  int get hashCode => Object.hash(binderId, identity, quantity, position);

  @override
  String toString() =>
      'PlannedPlacement($binderId, $identity ×$quantity, ${position.describe()})';
}

/// A stack that matched a binder's query but did not fit (D6 overflow).
class OverflowEntry {
  const OverflowEntry({
    required this.binderId,
    required this.identity,
    required this.quantity,
  });

  final String binderId;
  final CardIdentity identity;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverflowEntry &&
          runtimeType == other.runtimeType &&
          binderId == other.binderId &&
          identity == other.identity &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(binderId, identity, quantity);

  @override
  String toString() => 'OverflowEntry($binderId, $identity ×$quantity)';
}

/// One row of a staged diff: Add / Remove / Move with exact locations (D7).
///
/// [from] is set for remove/move; [to] is set for add/move.
class BinderDiffEntry {
  const BinderDiffEntry({
    required this.type,
    required this.binderId,
    required this.identity,
    required this.quantity,
    this.from,
    this.to,
  })  : assert(
          type != DiffType.add || (from == null && to != null),
          'add has only a destination',
        ),
        assert(
          type != DiffType.remove || (from != null && to == null),
          'remove has only a source',
        ),
        assert(
          type != DiffType.move || (from != null && to != null),
          'move has both locations',
        );

  final DiffType type;
  final String binderId;
  final CardIdentity identity;
  final int quantity;
  final BinderPosition? from;
  final BinderPosition? to;

  String get scryfallId => identity.scryfallId;
  Finish get finish => identity.finish;

  /// The physically-followable instruction for this row (D7), e.g.
  /// `Move Ragavan → page 3, back, pocket 5`. [cardName] is resolved from
  /// the corpus by the caller — the diff model stores only identities.
  String instruction(String cardName) => switch (type) {
        DiffType.add => 'Add $cardName → ${to!.describe()}',
        DiffType.remove => 'Pull $cardName from ${from!.describe()}',
        DiffType.move => 'Move $cardName → ${to!.describe()}',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BinderDiffEntry &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          binderId == other.binderId &&
          identity == other.identity &&
          quantity == other.quantity &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(type, binderId, identity, quantity, from, to);

  @override
  String toString() =>
      'BinderDiffEntry(${type.name}, $binderId, $identity ×$quantity, '
      'from: $from, to: $to)';
}

/// A staged, not-yet-committed set of changes across binders (D7).
class StagedDiff {
  StagedDiff({
    required this.trigger,
    required List<BinderDiffEntry> entries,
    List<OverflowEntry> overflowChanges = const [],
    required this.createdAt,
  })  : entries = List.unmodifiable(entries),
        overflowChanges = List.unmodifiable(overflowChanges);

  final ChangeTrigger trigger;
  final List<BinderDiffEntry> entries;

  /// Overflow after this change, for the review screen's overflow section.
  final List<OverflowEntry> overflowChanges;

  final DateTime createdAt;

  bool get isEmpty => entries.isEmpty && overflowChanges.isEmpty;

  int get addCount => _count(DiffType.add);
  int get removeCount => _count(DiffType.remove);
  int get moveCount => _count(DiffType.move);

  int _count(DiffType type) => entries.where((e) => e.type == type).length;

  /// Entries grouped by binder id, preserving entry order (§10 groups the
  /// diff list by binder).
  Map<String, List<BinderDiffEntry>> get entriesByBinder {
    final grouped = <String, List<BinderDiffEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.binderId, () => []).add(entry);
    }
    return grouped;
  }
}

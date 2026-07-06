/// Computes the current planned allocation from live database state.
///
/// Bridges the pure [allocate] engine to the app: loads binder definitions
/// and committed slots from the user DB, computes the D13 per-stack idle
/// pool (reservations + finish-specific corpus prices), resolves each
/// binder's match set through the query engine, and runs the D6 priority
/// walk. Change events call [AllocationPlanner.plan] to recompute planned
/// state before staging a diff; the binder editor calls it with a [draft]
/// for the live match/fit/overflow preview (§8).
library;

import '../binders/binder_repository.dart';
import '../database/corpus_database.dart';
import '../database/user_database.dart';
import '../import/manabox_parser.dart';
import '../models/binder_position.dart';
import '../models/card_identity.dart';
import '../models/ordering.dart';
import '../query/query_engine.dart';
import 'allocator.dart';
import 'reservation.dart';

/// An unsaved binder definition for the editor's live preview (§8).
///
/// With [id] set the draft replaces that persisted binder in place (same
/// priority slot, same committed anchors); with [id] null it is appended at
/// the END of the priority list under [BinderDraft.draftBinderId] — exactly
/// where [BinderRepository.createBinder] would put it.
class BinderDraft {
  const BinderDraft({
    this.id,
    required this.query,
    required this.geometry,
    this.groupBy,
    this.sortBy = BinderAxis.price,
    this.sortDir = SortDirection.desc,
    this.isVirtual = false,
  });

  /// The binder id in [AllocationResult] for a new (id-less) draft.
  static const draftBinderId = '__draft__';

  final String? id;
  final String query;
  final BinderGeometry geometry;
  final BinderAxis? groupBy;
  final BinderAxis sortBy;
  final SortDirection sortDir;
  final bool isVirtual;

  String get effectiveId => id ?? draftBinderId;
}

/// Loads live state and runs one allocation pass (D6/D13).
class AllocationPlanner {
  AllocationPlanner({
    required UserDatabase userDb,
    required CorpusDatabase corpus,
    required QueryEngine engine,
  })  : _userDb = userDb,
        _corpus = corpus,
        _engine = engine,
        _repository = BinderRepository(userDb);

  final UserDatabase _userDb;
  final CorpusDatabase _corpus;
  final QueryEngine _engine;
  final BinderRepository _repository;

  /// Match sets are collection-bounded (the query is restricted to idle
  /// printings), so one page comfortably holds everything.
  static const int _matchLimit = 100000;

  /// Runs one allocation pass over the persisted binders (priority order),
  /// optionally with [draft] substituted in (editor preview).
  ///
  /// [reflowBinderIds] opts individual binders into a full D7 reflow for
  /// this pass; everything else uses append-within-group.
  Future<AllocationResult> plan({
    BinderDraft? draft,
    Set<String> reflowBinderIds = const {},
  }) async {
    final definitions = _effectiveDefinitions(
      await _repository.listBinders(),
      draft,
    );
    if (definitions.isEmpty) return AllocationResult.empty;

    final idle = await _loadStackIdle();
    final slotsByBinder = await _loadSlotsByBinder();

    final requests = <BinderAllocationRequest>[];
    for (final definition in definitions) {
      requests.add(BinderAllocationRequest(
        binderId: definition.id,
        geometry: definition.geometry,
        groupBy: definition.groupBy,
        sortBy: definition.sortBy,
        sortDir: definition.sortDir,
        isVirtual: definition.isVirtual,
        matches: await _matchesFor(definition.query),
        committedSlots: slotsByBinder[definition.id] ?? const [],
        reflow: reflowBinderIds.contains(definition.id),
      ));
    }

    return allocate(binders: requests, idle: idle);
  }

  // ---------------------------------------------------------------------------
  // Inputs
  // ---------------------------------------------------------------------------

  List<_BinderDefinition> _effectiveDefinitions(
    List<Binder> binders,
    BinderDraft? draft,
  ) {
    final definitions = [
      for (final binder in binders)
        _BinderDefinition(
          id: binder.id,
          query: binder.query,
          geometry: binder.geometry,
          groupBy: binder.groupBy,
          sortBy: binder.sortBy,
          sortDir: binder.sortDir,
          isVirtual: binder.isVirtual,
        ),
    ];
    if (draft == null) return definitions;

    final fromDraft = _BinderDefinition(
      id: draft.effectiveId,
      query: draft.query,
      geometry: draft.geometry,
      groupBy: draft.groupBy,
      sortBy: draft.sortBy,
      sortDir: draft.sortDir,
      isVirtual: draft.isVirtual,
    );
    final index = definitions.indexWhere((d) => d.id == draft.id);
    if (index >= 0) {
      definitions[index] = fromDraft;
    } else {
      definitions.add(fromDraft);
    }
    return definitions;
  }

  /// The D13 per-stack idle pool: printing-level reservations distributed
  /// cheapest-finish-first using corpus prices.
  Future<StackIdleSummary> _loadStackIdle() async {
    final stacks = await _userDb.select(_userDb.stacks).get();
    final decks = await _userDb.select(_userDb.decks).get();
    final entries = await _userDb.select(_userDb.deckEntries).get();

    final reservations = computeReservations(
      stacks: stacks,
      decks: decks,
      entries: entries,
    );

    final cardById = await _loadCards({for (final s in stacks) s.scryfallId});
    return computeStackIdle(
      stacks: stacks,
      reservations: reservations,
      priceOf: (identity) {
        final card = cardById[identity.scryfallId];
        if (card == null) return null;
        return switch (identity.finish) {
          Finish.nonfoil => card.priceUsd,
          Finish.foil => card.priceUsdFoil,
          Finish.etched => card.priceUsdEtched,
        };
      },
    );
  }

  Future<Map<String, Card>> _loadCards(Set<String> scryfallIds) async {
    final ids = scryfallIds.toList();
    final cardById = <String, Card>{};
    const chunkSize = ManaBoxParser.lookupChunkSize;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
        i,
        i + chunkSize > ids.length ? ids.length : i + chunkSize,
      );
      final rows = await (_corpus.select(_corpus.cards)
            ..where((c) => c.scryfallId.isIn(chunk)))
          .get();
      for (final row in rows) {
        cardById[row.scryfallId] = row;
      }
    }
    return cardById;
  }

  Future<Map<String, List<BinderSlotRow>>> _loadSlotsByBinder() async {
    final slots = await _userDb.select(_userDb.binderSlots).get();
    final byBinder = <String, List<BinderSlotRow>>{};
    for (final slot in slots) {
      byBinder.putIfAbsent(slot.binderId, () => []).add(slot);
    }
    return byBinder;
  }

  /// A binder's match set: its query restricted to printings with idle
  /// copies. Only owned, idle printings can be placed (the allocator
  /// ignores everything else), and the restriction keeps broad queries
  /// ("r:common") collection-sized instead of corpus-sized.
  Future<List<Card>> _matchesFor(String query) async {
    if (query.trim().isEmpty) return const [];
    final result = await _engine.search(
      '(${query.trim()}) unused:true',
      limit: _matchLimit,
    );
    // A stored query that no longer parses simply matches nothing; the
    // editor surfaces parse errors before saving.
    return result.cards;
  }
}

class _BinderDefinition {
  const _BinderDefinition({
    required this.id,
    required this.query,
    required this.geometry,
    required this.groupBy,
    required this.sortBy,
    required this.sortDir,
    required this.isVirtual,
  });

  final String id;
  final String query;
  final BinderGeometry geometry;
  final BinderAxis? groupBy;
  final BinderAxis sortBy;
  final SortDirection sortDir;
  final bool isVirtual;
}

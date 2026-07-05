import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/allocation/reservation.dart';
import '../../core/database/corpus_database.dart';
import '../../core/database/user_database.dart';
import '../../core/decks/deck_repository.dart';
import '../../core/import/decklist_parser.dart';
import '../../core/models/card_identity.dart';
import 'corpus_provider.dart';
import 'search_provider.dart';
import 'user_database_provider.dart';

// ---------------------------------------------------------------------------
// Repository / stream providers
// ---------------------------------------------------------------------------

/// The deck repository, bound to the singleton user database.
final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(ref.watch(userDatabaseProvider));
});

/// All decks with aggregate counts, live.
final decksListProvider = StreamProvider<List<DeckListItem>>((ref) {
  return ref.watch(deckRepositoryProvider).watchDecks();
});

/// One deck with its entries, live. Emits null when the deck is missing
/// (e.g. after deletion).
final deckDetailProvider =
    StreamProvider.family<DeckDetail?, String>((ref, deckId) {
  return ref.watch(deckRepositoryProvider).watchDeck(deckId);
});

/// Live reservation summary across stacks, decks, and entries (D3).
final reservationProvider = StreamProvider<ReservationSummary>((ref) {
  return watchReservations(ref.watch(userDatabaseProvider));
});

/// Corpus cards for a deck's entries, keyed by scryfallId — used by the
/// detail screen to show printing set/collector info.
final deckCardsProvider =
    FutureProvider.family<Map<String, Card>, String>((ref, deckId) async {
  final detail = await ref.watch(deckDetailProvider(deckId).future);
  if (detail == null || detail.entries.isEmpty) return const {};
  final corpus = ref.watch(corpusDatabaseProvider);
  final ids = detail.entries.map((e) => e.scryfallId).toSet().toList();
  final cards = await (corpus.select(corpus.cards)
        ..where((c) => c.scryfallId.isIn(ids)))
      .get();
  return {for (final c in cards) c.scryfallId: c};
});

/// All printings of one oracle identity, newest first — candidates for the
/// deck-detail printing editor (D13 correction path).
final printingsOfOracleProvider =
    FutureProvider.family<List<Card>, String>((ref, oracleId) {
  return ref.watch(corpusDatabaseProvider).printingsOfOracle(oracleId);
});

// ---------------------------------------------------------------------------
// Decklist import state machine
// ---------------------------------------------------------------------------

enum DeckImportPhase { idle, parsing, preview, committing, done, error }

/// D3 printing-fidelity choice for lines that resolved to multiple printings.
enum FidelityMode { cheapestFirst, pickManually }

/// D10 unowned-card prompt choices.
enum UnownedChoice { addToCollection, importUnowned, backOut }

/// One deck entry planned for commit. A single decklist line can split into
/// several planned entries (cheapest-first over multiple owned printings,
/// or an owned part + unowned remainder).
class PlannedEntry {
  const PlannedEntry({
    required this.card,
    required this.quantity,
    this.isUnowned = false,
  });

  final Card card;
  final int quantity;
  final bool isUnowned;

  PlannedEntry copyWith({int? quantity, bool? isUnowned}) => PlannedEntry(
        card: card,
        quantity: quantity ?? this.quantity,
        isUnowned: isUnowned ?? this.isUnowned,
      );
}

/// A parsed decklist line plus the user's per-line choices.
class DeckImportLine {
  const DeckImportLine({
    required this.raw,
    required this.resolution,
    this.shared = false,
    this.planned = const [],
  });

  final RawDeckLine raw;
  final LineResolution resolution;

  /// Per-card shared toggle (entry-level D3 override).
  final bool shared;

  /// Resolved entries for commit; empty while a printing pick is pending.
  final List<PlannedEntry> planned;

  bool get isPendingPick => resolution is ResolvedByName && planned.isEmpty;

  bool get hasUnowned => planned.any((e) => e.isUnowned);

  DeckImportLine copyWith({bool? shared, List<PlannedEntry>? planned}) =>
      DeckImportLine(
        raw: raw,
        resolution: resolution,
        shared: shared ?? this.shared,
        planned: planned ?? this.planned,
      );
}

/// One printing the user lacks copies of, for the unowned prompt (D10).
class UnownedShortfall {
  const UnownedShortfall({required this.card, required this.missing});

  final Card card;
  final int missing;
}

/// Immutable state for the decklist import flow.
class DeckImportState {
  const DeckImportState({
    this.phase = DeckImportPhase.idle,
    this.sourceText = '',
    this.deckName = '',
    this.format = '',
    this.assembled = true,
    this.shared = false,
    this.lines = const [],
    this.errors = const [],
    this.needsFidelity = false,
    this.fidelityMode,
    this.unowned = const [],
    this.error,
    this.createdDeckId,
  });

  final DeckImportPhase phase;

  /// The raw pasted/loaded text (kept for back-out editing).
  final String sourceText;

  final String deckName;
  final String format;
  final bool assembled;
  final bool shared;

  final List<DeckImportLine> lines;
  final List<DecklistLineError> errors;

  /// True while the printing-fidelity prompt is pending.
  final bool needsFidelity;
  final FidelityMode? fidelityMode;

  /// Non-empty while the unowned prompt is pending.
  final List<UnownedShortfall> unowned;

  final String? error;
  final String? createdDeckId;

  bool get hasPendingPicks => lines.any((l) => l.isPendingPick);

  bool get canCommit =>
      phase == DeckImportPhase.preview &&
      !needsFidelity &&
      unowned.isEmpty &&
      !hasPendingPicks &&
      lines.any((l) => l.planned.isNotEmpty);

  DeckImportState copyWith({
    DeckImportPhase? phase,
    String? sourceText,
    String? deckName,
    String? format,
    bool? assembled,
    bool? shared,
    List<DeckImportLine>? lines,
    List<DecklistLineError>? errors,
    bool? needsFidelity,
    FidelityMode? fidelityMode,
    List<UnownedShortfall>? unowned,
    String? error,
    String? createdDeckId,
  }) {
    return DeckImportState(
      phase: phase ?? this.phase,
      sourceText: sourceText ?? this.sourceText,
      deckName: deckName ?? this.deckName,
      format: format ?? this.format,
      assembled: assembled ?? this.assembled,
      shared: shared ?? this.shared,
      lines: lines ?? this.lines,
      errors: errors ?? this.errors,
      needsFidelity: needsFidelity ?? this.needsFidelity,
      fidelityMode: fidelityMode ?? this.fidelityMode,
      unowned: unowned ?? this.unowned,
      // Errors don't survive transitions unless re-passed (matches the
      // copyWith convention in search_provider.dart).
      error: error,
      createdDeckId: createdDeckId ?? this.createdDeckId,
    );
  }
}

/// Drives the decklist import flow: parse → preview → fidelity/unowned
/// prompts → commit.
class DeckImportNotifier extends StateNotifier<DeckImportState> {
  DeckImportNotifier(this._parser, this._repository, this._db,
      {this.onCommitted})
      : super(const DeckImportState());

  final DecklistParser _parser;
  final DeckRepository _repository;
  final UserDatabase _db;

  /// Invoked after a successful commit — reservations changed, so
  /// anything derived from them (e.g. `unused:` search results) should
  /// refresh.
  final void Function()? onCommitted;

  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  Future<void> parseText(String text) async {
    if (text.trim().isEmpty) {
      state = DeckImportState(
        deckName: state.deckName,
        format: state.format,
        assembled: state.assembled,
        shared: state.shared,
      );
      return;
    }

    // Fresh state keeps metadata but drops previous resolution results.
    state = DeckImportState(
      phase: DeckImportPhase.parsing,
      sourceText: text,
      deckName: state.deckName,
      format: state.format,
      assembled: state.assembled,
      shared: state.shared,
    );

    try {
      final result = await _parser.parse(text);
      final lines = [
        for (final parsed in result.lines)
          DeckImportLine(
            raw: parsed.raw,
            resolution: parsed.resolution,
            planned: switch (parsed.resolution) {
              ResolvedExact(:final card) => [
                  PlannedEntry(card: card, quantity: parsed.raw.quantity),
                ],
              _ => const [],
            },
          ),
      ];

      var unowned = const <UnownedShortfall>[];
      if (!result.needsFidelityChoice) {
        unowned = await _detectShortfalls(lines);
      }

      state = state.copyWith(
        phase: DeckImportPhase.preview,
        lines: lines,
        errors: result.errors,
        needsFidelity: result.needsFidelityChoice,
        unowned: unowned,
      );
    } catch (e) {
      state = state.copyWith(
        phase: DeckImportPhase.error,
        error: e.toString(),
      );
    }
  }

  /// Decodes [bytes] as UTF-8 and parses. Defaults the deck name to the
  /// file name (minus extension) when no name is set yet.
  Future<void> loadFile(String name, Uint8List bytes) async {
    if (state.deckName.trim().isEmpty) {
      state = state.copyWith(deckName: p.basenameWithoutExtension(name));
    }
    await parseText(utf8.decode(bytes, allowMalformed: true));
  }

  // ---------------------------------------------------------------------------
  // Metadata & per-line toggles
  // ---------------------------------------------------------------------------

  void setMetadata({
    String? name,
    String? format,
    bool? assembled,
    bool? shared,
  }) {
    state = state.copyWith(
      deckName: name,
      format: format,
      assembled: assembled,
      shared: shared,
    );
  }

  void toggleEntryShared(int lineIndex) {
    if (lineIndex < 0 || lineIndex >= state.lines.length) return;
    final lines = [...state.lines];
    lines[lineIndex] =
        lines[lineIndex].copyWith(shared: !lines[lineIndex].shared);
    state = state.copyWith(lines: lines);
  }

  // ---------------------------------------------------------------------------
  // Printing fidelity (D3)
  // ---------------------------------------------------------------------------

  Future<void> chooseFidelity(FidelityMode mode) async {
    if (state.phase != DeckImportPhase.preview) return;

    if (mode == FidelityMode.pickManually) {
      state = state.copyWith(needsFidelity: false, fidelityMode: mode);
      return;
    }

    // Cheapest-first: greedily fill each multi-printing line from the
    // user's OWNED printings of that name, cheapest priceUsd first;
    // any remainder becomes the overall-cheapest corpus printing, marked
    // unowned.
    final remaining = await _ownedQuantities();

    // Copies already claimed by exact-printing lines aren't available.
    for (final line in state.lines) {
      if (line.resolution is ResolvedByName) continue;
      for (final planned in line.planned) {
        final id = planned.card.scryfallId;
        remaining[id] = max(0, (remaining[id] ?? 0) - planned.quantity);
      }
    }

    final newLines = state.lines.map((line) {
      final resolution = line.resolution;
      if (resolution is! ResolvedByName) return line;

      var needed = line.raw.quantity;
      final planned = <PlannedEntry>[];

      final ownedCandidates = resolution.candidates
          .where((c) => (remaining[c.scryfallId] ?? 0) > 0)
          .toList()
        ..sort(_byPriceAsc);
      for (final candidate in ownedCandidates) {
        if (needed == 0) break;
        final take = min(needed, remaining[candidate.scryfallId]!);
        planned.add(PlannedEntry(card: candidate, quantity: take));
        remaining[candidate.scryfallId] =
            remaining[candidate.scryfallId]! - take;
        needed -= take;
      }

      if (needed > 0) {
        final cheapest = [...resolution.candidates]..sort(_byPriceAsc);
        planned.add(PlannedEntry(
          card: cheapest.first,
          quantity: needed,
          isUnowned: true,
        ));
      }

      return line.copyWith(planned: planned);
    }).toList();

    final unowned = await _detectShortfalls(newLines);
    state = state.copyWith(
      lines: newLines,
      needsFidelity: false,
      fidelityMode: mode,
      unowned: unowned,
    );
  }

  /// Resolves a pending multi-printing line to [printing]. Once every line
  /// is resolved, unowned detection runs (asynchronously).
  void pickPrinting(int lineIndex, Card printing) {
    if (lineIndex < 0 || lineIndex >= state.lines.length) return;
    final line = state.lines[lineIndex];
    if (line.resolution is! ResolvedByName) return;

    final lines = [...state.lines];
    lines[lineIndex] = line.copyWith(
      planned: [PlannedEntry(card: printing, quantity: line.raw.quantity)],
    );
    state = state.copyWith(lines: lines);

    if (!state.hasPendingPicks) {
      _refreshShortfalls();
    }
  }

  Future<void> _refreshShortfalls() async {
    final unowned = await _detectShortfalls(state.lines);
    if (!mounted) return;
    state = state.copyWith(unowned: unowned);
  }

  static int _byPriceAsc(Card a, Card b) {
    final pa = a.priceUsd ?? double.infinity;
    final pb = b.priceUsd ?? double.infinity;
    return pa.compareTo(pb);
  }

  // ---------------------------------------------------------------------------
  // Unowned cards (D10)
  // ---------------------------------------------------------------------------

  Future<void> resolveUnowned(UnownedChoice choice) async {
    switch (choice) {
      case UnownedChoice.backOut:
        // Back to an editable state — text and metadata survive.
        state = DeckImportState(
          sourceText: state.sourceText,
          deckName: state.deckName,
          format: state.format,
          assembled: state.assembled,
          shared: state.shared,
        );

      case UnownedChoice.importUnowned:
        final owned = await _ownedQuantities();
        state = state.copyWith(
          lines: _markUnowned(state.lines, owned),
          unowned: const [],
        );

      case UnownedChoice.addToCollection:
        final shortfalls = state.unowned;
        final now = DateTime.now();
        await _db.transaction(() async {
          for (final shortfall in shortfalls) {
            await _db.into(_db.stacks).insert(
                  StacksCompanion.insert(
                    id: _uuid.v4(),
                    scryfallId: shortfall.card.scryfallId,
                    finish: Finish.nonfoil,
                    quantity: shortfall.missing,
                    provenance: 'deck-import',
                    createdAt: now,
                    updatedAt: now,
                  ),
                  onConflict: DoUpdate(
                    (old) => StacksCompanion.custom(
                      quantity: old.quantity + Constant(shortfall.missing),
                      updatedAt: Constant(now),
                    ),
                    target: [
                      _db.stacks.scryfallId,
                      _db.stacks.finish,
                      _db.stacks.provenance,
                    ],
                  ),
                );
          }
        });

        // The shortfall printings are owned now — clear unowned marks.
        final added = {for (final s in shortfalls) s.card.scryfallId};
        final lines = state.lines
            .map((line) => line.copyWith(
                  planned: [
                    for (final planned in line.planned)
                      added.contains(planned.card.scryfallId)
                          ? planned.copyWith(isUnowned: false)
                          : planned,
                  ],
                ))
            .toList();
        state = state.copyWith(lines: lines, unowned: const []);
    }
  }

  /// Needed quantity per printing (over planned entries) vs stacks summed
  /// across finishes/provenances. Entries already marked unowned count as
  /// shortfall directly.
  Future<List<UnownedShortfall>> _detectShortfalls(
    List<DeckImportLine> lines,
  ) async {
    if (lines.any((l) => l.isPendingPick)) return const [];

    final owned = await _ownedQuantities();
    final needed = <String, int>{};
    final preMarked = <String, int>{};
    final cardById = <String, Card>{};

    for (final line in lines) {
      for (final planned in line.planned) {
        final id = planned.card.scryfallId;
        cardById[id] = planned.card;
        final bucket = planned.isUnowned ? preMarked : needed;
        bucket[id] = (bucket[id] ?? 0) + planned.quantity;
      }
    }

    final shortfalls = <UnownedShortfall>[];
    for (final id in {...needed.keys, ...preMarked.keys}) {
      final missing =
          max(0, (needed[id] ?? 0) - (owned[id] ?? 0)) + (preMarked[id] ?? 0);
      if (missing > 0) {
        shortfalls.add(UnownedShortfall(card: cardById[id]!, missing: missing));
      }
    }
    return shortfalls;
  }

  /// Marks (splitting where needed) planned entries beyond the owned
  /// quantity as unowned, allocating owned copies in line order.
  static List<DeckImportLine> _markUnowned(
    List<DeckImportLine> lines,
    Map<String, int> owned,
  ) {
    final remaining = Map.of(owned);
    return lines.map((line) {
      final planned = <PlannedEntry>[];
      for (final entry in line.planned) {
        if (entry.isUnowned) {
          planned.add(entry);
          continue;
        }
        final id = entry.card.scryfallId;
        final available = remaining[id] ?? 0;
        final take = min(entry.quantity, available);
        remaining[id] = available - take;
        if (take == entry.quantity) {
          planned.add(entry);
        } else if (take == 0) {
          planned.add(entry.copyWith(isUnowned: true));
        } else {
          planned.add(entry.copyWith(quantity: take));
          planned.add(PlannedEntry(
            card: entry.card,
            quantity: entry.quantity - take,
            isUnowned: true,
          ));
        }
      }
      return line.copyWith(planned: planned);
    }).toList();
  }

  Future<Map<String, int>> _ownedQuantities() async {
    final rows = await _db.select(_db.stacks).get();
    final owned = <String, int>{};
    for (final row in rows) {
      owned[row.scryfallId] = (owned[row.scryfallId] ?? 0) + row.quantity;
    }
    return owned;
  }

  // ---------------------------------------------------------------------------
  // Commit
  // ---------------------------------------------------------------------------

  Future<void> commit() async {
    if (!state.canCommit) return;

    final drafts = <DeckEntryDraft>[
      for (final line in state.lines)
        for (final planned in line.planned)
          DeckEntryDraft(
            scryfallId: planned.card.scryfallId,
            cardName: line.raw.name,
            quantity: planned.quantity,
            section: line.raw.section,
            isShared: line.shared,
            isUnowned: planned.isUnowned,
            printingSpecified: line.raw.setCode != null,
          ),
    ];

    state = state.copyWith(phase: DeckImportPhase.committing);
    try {
      final name = state.deckName.trim();
      final format = state.format.trim();
      final deckId = await _repository.createDeck(
        name: name.isEmpty ? 'Imported deck' : name,
        format: format.isEmpty ? null : format,
        isAssembled: state.assembled,
        isShared: state.shared,
        entries: drafts,
      );
      state = state.copyWith(
        phase: DeckImportPhase.done,
        createdDeckId: deckId,
      );
      onCommitted?.call();
    } catch (e) {
      state = state.copyWith(
        phase: DeckImportPhase.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const DeckImportState();
  }
}

/// Provides the [DeckImportNotifier] and its current [DeckImportState].
final deckImportProvider =
    StateNotifierProvider<DeckImportNotifier, DeckImportState>((ref) {
  return DeckImportNotifier(
    DecklistParser(ref.watch(corpusDatabaseProvider)),
    ref.watch(deckRepositoryProvider),
    ref.watch(userDatabaseProvider),
    onCommitted: () => ref.read(searchProvider.notifier).refresh(),
  );
});

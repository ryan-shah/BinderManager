import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/corpus_database.dart';
import '../../core/database/user_database.dart';
import '../../core/import/collection_importer.dart';
import '../../core/import/manabox_parser.dart';
import '../../core/models/card_identity.dart';
import 'corpus_provider.dart';
import 'search_provider.dart';
import 'user_database_provider.dart';

/// Where the import flow currently is.
enum CollectionImportPhase { idle, parsing, review, committing, done, error }

/// Immutable state for the ManaBox collection import flow.
class CollectionImportState {
  const CollectionImportState({
    this.phase = CollectionImportPhase.idle,
    this.fileName,
    this.mode = ImportMode.append,
    this.parseResult,
    this.diff,
    this.previousStackCount = 0,
    this.error,
  });

  final CollectionImportPhase phase;

  /// Name of the loaded CSV file, if any.
  final String? fileName;

  final ImportMode mode;

  final ManaBoxParseResult? parseResult;

  /// What a commit would change, for the current [mode].
  final ImportDiff? diff;

  /// Number of manabox-provenance stacks that existed when the file was
  /// parsed — feeds the replace warning ("was M").
  final int previousStackCount;

  final String? error;

  CollectionImportState copyWith({
    CollectionImportPhase? phase,
    String? fileName,
    ImportMode? mode,
    ManaBoxParseResult? parseResult,
    ImportDiff? diff,
    int? previousStackCount,
    String? error,
  }) {
    return CollectionImportState(
      phase: phase ?? this.phase,
      fileName: fileName ?? this.fileName,
      mode: mode ?? this.mode,
      parseResult: parseResult ?? this.parseResult,
      diff: diff ?? this.diff,
      previousStackCount: previousStackCount ?? this.previousStackCount,
      error: error,
    );
  }
}

/// Drives the ManaBox CSV import flow:
/// pick file → parse → review (map/ignore unmatched, choose mode) → commit.
class CollectionImportNotifier extends StateNotifier<CollectionImportState> {
  CollectionImportNotifier(this._corpus, this._userDb, {this.onCommitted})
      : super(const CollectionImportState());

  final CorpusDatabase _corpus;
  final UserDatabase _userDb;

  /// Invoked after a successful commit — the collection changed, so
  /// anything derived from it (e.g. `have:`/`unused:` search results)
  /// should refresh.
  final void Function()? onCommitted;

  late final ManaBoxParser _parser = ManaBoxParser(_corpus);
  late final CollectionImporter _importer = CollectionImporter(_userDb);

  /// Parses [bytes] and moves to review with a computed diff.
  Future<void> loadFile(String fileName, Uint8List bytes) async {
    if (state.phase == CollectionImportPhase.parsing ||
        state.phase == CollectionImportPhase.committing) {
      return;
    }

    state = CollectionImportState(
      phase: CollectionImportPhase.parsing,
      fileName: fileName,
      mode: state.mode,
    );

    try {
      final parseResult = await _parser.parseBytes(bytes);
      final diff = await _computeDiff(parseResult, state.mode);
      final previousStackCount = await _manaBoxStackCount();
      state = CollectionImportState(
        phase: CollectionImportPhase.review,
        fileName: fileName,
        mode: state.mode,
        parseResult: parseResult,
        diff: diff,
        previousStackCount: previousStackCount,
      );
    } catch (e) {
      state = CollectionImportState(
        phase: CollectionImportPhase.error,
        fileName: fileName,
        mode: state.mode,
        error: e.toString(),
      );
    }
  }

  /// Switches Replace/Append and recomputes the diff.
  Future<void> setMode(ImportMode mode) async {
    if (mode == state.mode) return;
    final parseResult = state.parseResult;
    if (parseResult == null) {
      state = state.copyWith(mode: mode);
      return;
    }
    final diff = await _computeDiff(parseResult, mode);
    state = state.copyWith(mode: mode, diff: diff);
  }

  /// Manually maps unmatched row [index] to [identity], re-validates it
  /// against the corpus, merges it into the matched list, and recomputes
  /// the diff.
  ///
  /// Throws [ArgumentError] if [identity] does not resolve to a corpus
  /// printing available in that finish (the map dialog constrains choices,
  /// so this only fires on programmer error).
  Future<void> mapUnmatched(int index, CardIdentity identity) async {
    final parseResult = state.parseResult;
    if (parseResult == null ||
        index < 0 ||
        index >= parseResult.unmatched.length) {
      return;
    }

    final card = await _corpus.getCard(identity.scryfallId);
    if (card == null) {
      throw ArgumentError('Unknown scryfall id: ${identity.scryfallId}');
    }
    final available = card.finishes.split(',').map((f) => f.trim());
    if (!available.contains(identity.finish.name)) {
      throw ArgumentError(
          '${card.name} is not available in ${identity.finish.name}');
    }

    final row = parseResult.unmatched[index];
    final quantity =
        math.max(1, int.tryParse(_rawCell(row.raw, 'quantity')) ?? 1);
    final mapped = MatchedStackRow(
      identity: identity,
      quantity: quantity,
      condition: _nullIfEmpty(_rawCell(row.raw, 'condition')),
      language: _nullIfEmpty(_rawCell(row.raw, 'language')),
      corpusCard: card,
    );

    // Merge with an existing matched stack of the same identity, mirroring
    // the parser's duplicate handling.
    final matched = List<MatchedStackRow>.of(parseResult.matched);
    final existingIndex =
        matched.indexWhere((m) => m.identity == identity);
    if (existingIndex >= 0) {
      final existing = matched[existingIndex];
      matched[existingIndex] = MatchedStackRow(
        identity: identity,
        quantity: existing.quantity + mapped.quantity,
        condition: existing.condition ?? mapped.condition,
        language: existing.language ?? mapped.language,
        corpusCard: existing.corpusCard,
      );
    } else {
      matched.add(mapped);
    }

    final unmatched = List<UnmatchedRow>.of(parseResult.unmatched)
      ..removeAt(index);
    final updated = ManaBoxParseResult(
      matched: matched,
      unmatched: unmatched,
      totalDataRows: parseResult.totalDataRows,
    );
    final diff = await _computeDiff(updated, state.mode);
    state = state.copyWith(parseResult: updated, diff: diff);
  }

  /// Marks unmatched row [index] as intentionally skipped (token/proxy).
  void ignoreUnmatched(int index) {
    final parseResult = state.parseResult;
    if (parseResult == null ||
        index < 0 ||
        index >= parseResult.unmatched.length) {
      return;
    }
    final unmatched = List<UnmatchedRow>.of(parseResult.unmatched);
    unmatched[index] = unmatched[index].copyWith(ignored: true);
    state = state.copyWith(
      parseResult: ManaBoxParseResult(
        matched: parseResult.matched,
        unmatched: unmatched,
        totalDataRows: parseResult.totalDataRows,
      ),
    );
  }

  /// Applies the reviewed import to the user database.
  Future<void> commit() async {
    final parseResult = state.parseResult;
    if (state.phase != CollectionImportPhase.review || parseResult == null) {
      return;
    }

    state = state.copyWith(phase: CollectionImportPhase.committing);
    try {
      await _importer.commit(parseResult.matched, state.mode);
      state = state.copyWith(phase: CollectionImportPhase.done);
      onCommitted?.call();
    } catch (e) {
      state = state.copyWith(
        phase: CollectionImportPhase.error,
        error: e.toString(),
      );
    }
  }

  /// Returns to a pristine idle state.
  void reset() {
    state = const CollectionImportState();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<ImportDiff> _computeDiff(
      ManaBoxParseResult parseResult, ImportMode mode) {
    return _importer.computeDiff(
      parseResult.matched,
      mode,
      resolveNames: _resolveNames,
    );
  }

  /// Batch-resolves card names from the corpus for diff remove labels.
  Future<Map<String, String>> _resolveNames(List<String> scryfallIds) async {
    final names = <String, String>{};
    const chunkSize = ManaBoxParser.lookupChunkSize;
    for (var i = 0; i < scryfallIds.length; i += chunkSize) {
      final chunk = scryfallIds.sublist(
        i,
        math.min(i + chunkSize, scryfallIds.length),
      );
      final cards = await (_corpus.select(_corpus.cards)
            ..where((c) => c.scryfallId.isIn(chunk)))
          .get();
      for (final card in cards) {
        names[card.scryfallId] = card.name;
      }
    }
    return names;
  }

  Future<int> _manaBoxStackCount() async {
    final count = countAll();
    final query = _userDb.selectOnly(_userDb.stacks)
      ..addColumns([count])
      ..where(_userDb.stacks.provenance
          .equals(CollectionImporter.provenanceManaBox));
    final row = await query.getSingle();
    return row.read(count)!;
  }

  static String _rawCell(Map<String, String> raw, String header) {
    for (final entry in raw.entries) {
      if (entry.key.toLowerCase() == header) return entry.value.trim();
    }
    return '';
  }

  static String? _nullIfEmpty(String value) => value.isEmpty ? null : value;
}

/// Provides the [CollectionImportNotifier] and its current state.
final collectionImportProvider =
    StateNotifierProvider<CollectionImportNotifier, CollectionImportState>(
        (ref) {
  final corpus = ref.watch(corpusDatabaseProvider);
  final userDb = ref.watch(userDatabaseProvider);
  return CollectionImportNotifier(
    corpus,
    userDb,
    onCommitted: () => ref.read(searchProvider.notifier).refresh(),
  );
});

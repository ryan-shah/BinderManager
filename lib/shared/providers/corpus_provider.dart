import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/connection/connection.dart' as db;
import '../../core/database/corpus_database.dart';
import '../../core/import/scryfall_downloader.dart';
import '../../core/import/scryfall_parser.dart';

// ---------------------------------------------------------------------------
// Database singleton
// ---------------------------------------------------------------------------

/// Provides the [CorpusDatabase] as a long-lived singleton.
///
/// Closing the database is tied to the provider container's lifecycle; in
/// practice the DB stays open for the lifetime of the app.
final corpusDatabaseProvider = Provider<CorpusDatabase>((ref) {
  final database = CorpusDatabase(db.connect('corpus'));
  ref.onDispose(() => database.close());
  return database;
});

// ---------------------------------------------------------------------------
// Corpus readiness check
// ---------------------------------------------------------------------------

/// Whether the corpus has been downloaded and contains data.
///
/// Returns `true` once the cards table has at least one row.
final corpusReadyProvider = FutureProvider<bool>((ref) async {
  final database = ref.watch(corpusDatabaseProvider);
  final count = await database.cardCount();
  return count > 0;
});

// ---------------------------------------------------------------------------
// Import pipeline
// ---------------------------------------------------------------------------

/// Progress state for the corpus import pipeline.
class CorpusImportState {
  /// Human-readable label for the current phase.
  final String phase;

  /// Progress fraction in [0.0, 1.0], or null if indeterminate.
  final double? progress;

  /// Non-null when the import has failed.
  final String? error;

  /// True once the pipeline has completed successfully.
  final bool complete;

  const CorpusImportState({
    this.phase = 'idle',
    this.progress,
    this.error,
    this.complete = false,
  });

  CorpusImportState copyWith({
    String? phase,
    double? progress,
    String? error,
    bool? complete,
  }) {
    return CorpusImportState(
      phase: phase ?? this.phase,
      progress: progress,
      error: error,
      complete: complete ?? this.complete,
    );
  }

  @override
  String toString() {
    if (error != null) return 'CorpusImportState(error: $error)';
    if (complete) return 'CorpusImportState(complete)';
    final pct =
        progress != null ? ' ${(progress! * 100).toStringAsFixed(1)}%' : '';
    return 'CorpusImportState($phase$pct)';
  }
}

/// Manages the full download-parse-insert pipeline for the card corpus.
///
/// Usage:
/// ```dart
/// final notifier = ref.read(corpusImportProvider.notifier);
/// await notifier.runImport();
/// ```
class CorpusImportNotifier extends StateNotifier<CorpusImportState> {
  final CorpusDatabase _db;

  CorpusImportNotifier(this._db)
      : super(const CorpusImportState());

  /// Runs the full Scryfall download + parse + insert pipeline.
  ///
  /// Updates [state] throughout so the UI can display progress.
  Future<void> runImport() async {
    if (state.phase != 'idle' &&
        state.phase != 'error' &&
        !state.complete) {
      // Already running.
      return;
    }

    final downloader = ScryfallDownloader();

    try {
      // Phase 1: Download
      state = const CorpusImportState(phase: 'downloading', progress: 0.0);

      final bytes = await downloader.download(
        onProgress: (p) {
          state = CorpusImportState(
            phase: 'downloading',
            progress: p.fraction,
          );
        },
      );

      // Phase 2: Clear existing data
      state = const CorpusImportState(phase: 'clearing');
      await _db.clearAllCards();

      // Phase 3: Parse & insert
      state = const CorpusImportState(phase: 'parsing', progress: 0.0);

      final parser = ScryfallParser(_db);

      // We don't know the total card count until we parse, so estimate
      // using the byte-decoded JSON list length (known after full decode
      // inside parseAndInsert). Progress is reported per-batch.
      final totalInserted = await parser.parseAndInsert(
        bytes,
        onProgress: (processed) {
          // We don't have the total yet at callback time, so show raw count.
          // After the first progress call we could estimate, but a simple
          // "cards processed" display is fine for v1.
          state = CorpusImportState(
            phase: 'parsing ($processed cards)',
            progress: null,
          );
        },
      );

      state = CorpusImportState(
        phase: 'complete ($totalInserted cards)',
        complete: true,
      );
    } catch (e) {
      state = CorpusImportState(
        phase: 'error',
        error: e.toString(),
      );
    } finally {
      downloader.close();
    }
  }
}

/// Provides the [CorpusImportNotifier] and its current [CorpusImportState].
final corpusImportProvider =
    StateNotifierProvider<CorpusImportNotifier, CorpusImportState>((ref) {
  final db = ref.watch(corpusDatabaseProvider);
  return CorpusImportNotifier(db);
});

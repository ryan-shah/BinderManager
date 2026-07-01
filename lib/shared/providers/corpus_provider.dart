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

  /// Download progress fraction in [0.0, 1.0], or null if indeterminate.
  final double? progress;

  /// Number of cards inserted into the database so far.
  final int cardsImported;

  /// Non-null when the import has failed.
  final String? error;

  /// True once the pipeline has completed successfully.
  final bool complete;

  const CorpusImportState({
    this.phase = 'idle',
    this.progress,
    this.cardsImported = 0,
    this.error,
    this.complete = false,
  });

  CorpusImportState copyWith({
    String? phase,
    double? progress,
    int? cardsImported,
    String? error,
    bool? complete,
  }) {
    return CorpusImportState(
      phase: phase ?? this.phase,
      progress: progress,
      cardsImported: cardsImported ?? this.cardsImported,
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
    final cards = cardsImported > 0 ? ' $cardsImported cards' : '';
    return 'CorpusImportState($phase$pct$cards)';
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
  /// Uses streaming: the HTTP response is piped directly into the parser
  /// so the full ~150 MB payload never sits in memory at once.
  ///
  /// [cardLimit] stops the import (and aborts the download) after roughly
  /// that many cards — used by the debug quick-import mode.
  Future<void> runImport({int? cardLimit}) async {
    if (state.phase != 'idle' &&
        state.phase != 'error' &&
        !state.complete) {
      return;
    }

    final downloader = ScryfallDownloader();

    try {
      // Phase 1: Resolve the bulk-data URI and open the streaming download.
      state = const CorpusImportState(phase: 'contacting Scryfall');

      final dl = await downloader.downloadStream();

      // Phase 2: Clear existing data before streaming in new data.
      state = const CorpusImportState(phase: 'preparing database');
      await _db.clearAllCards();

      // Phase 3: Stream-parse directly from HTTP → parser → DB.
      // Download and import run concurrently on the same stream, so a
      // single phase carries both the byte fraction and the card count.
      state = const CorpusImportState(phase: 'downloading', progress: 0.0);

      final parser = ScryfallParser(_db);
      final totalInserted = await parser.parseFromStream(
        dl.stream,
        cardLimit: cardLimit,
        onBytesReceived: (bytes) {
          final fraction = dl.totalBytes != null && dl.totalBytes! > 0
              ? bytes / dl.totalBytes!
              : null;
          state = CorpusImportState(
            phase: 'downloading',
            progress: fraction,
            cardsImported: state.cardsImported,
          );
        },
        onProgress: (processed) {
          state = CorpusImportState(
            phase: 'downloading',
            progress: state.progress,
            cardsImported: processed,
          );
        },
      );

      state = CorpusImportState(
        phase: 'complete ($totalInserted cards)',
        cardsImported: totalInserted,
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

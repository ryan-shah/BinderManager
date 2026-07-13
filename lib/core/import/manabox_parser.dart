import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../database/corpus_database.dart';
import '../models/card_identity.dart';

/// Why a ManaBox CSV row could not be resolved to a corpus printing.
enum UnmatchReason {
  /// The Scryfall ID cell was empty.
  missingScryfallId,

  /// The Scryfall ID is not present in the local corpus.
  unknownScryfallId,

  /// The printing exists but is not available in the claimed finish.
  finishUnavailable,

  /// The Foil cell was not one of `normal` / `foil` / `etched`.
  invalidFinish,

  /// The Quantity cell was not a positive integer.
  invalidQuantity,

  /// The row was too short to carry the required cells.
  malformedRow,
}

/// A CSV row resolved against the corpus, merged across duplicate identities.
class MatchedStackRow {
  const MatchedStackRow({
    required this.identity,
    required this.quantity,
    this.condition,
    this.language,
    required this.corpusCard,
  });

  /// Canonical (printing, finish) identity per D2.
  final CardIdentity identity;

  /// Total quantity, summed across duplicate rows of the same identity.
  final int quantity;

  /// ManaBox condition string (e.g. `near_mint`); first non-empty wins.
  final String? condition;

  /// Two-letter language code (e.g. `en`); first non-empty wins.
  final String? language;

  /// The corpus row for this printing — used for names/prices in preview UI.
  final Card corpusCard;
}

/// A CSV row that could not be resolved. Queued for manual review — never
/// silently dropped (D8).
class UnmatchedRow {
  const UnmatchedRow({
    required this.lineNumber,
    required this.raw,
    required this.reason,
    this.resolvedIdentity,
    this.ignored = false,
  });

  /// 1-based row number in the CSV (the header is row 1).
  final int lineNumber;

  /// Original cell values keyed by their (trimmed) header names.
  final Map<String, String> raw;

  final UnmatchReason reason;

  /// The identity parsed from the row, when both ID and finish were readable
  /// (e.g. [UnmatchReason.unknownScryfallId], [UnmatchReason.finishUnavailable]).
  final CardIdentity? resolvedIdentity;

  /// Marked by the user as intentionally skipped (token/proxy/etc.).
  final bool ignored;

  UnmatchedRow copyWith({bool? ignored}) {
    return UnmatchedRow(
      lineNumber: lineNumber,
      raw: raw,
      reason: reason,
      resolvedIdentity: resolvedIdentity,
      ignored: ignored ?? this.ignored,
    );
  }
}

/// The outcome of parsing one ManaBox CSV export.
class ManaBoxParseResult {
  const ManaBoxParseResult({
    required this.matched,
    required this.unmatched,
    required this.totalDataRows,
  });

  /// Rows resolved to corpus printings, merged by identity.
  final List<MatchedStackRow> matched;

  /// Rows needing manual review, in file order.
  final List<UnmatchedRow> unmatched;

  /// Number of non-empty data rows (the header row is excluded).
  final int totalDataRows;
}

/// Intermediate row that parsed cleanly and awaits corpus validation.
class _Candidate {
  const _Candidate({
    required this.lineNumber,
    required this.raw,
    required this.identity,
    required this.quantity,
    this.condition,
    this.language,
  });

  final int lineNumber;
  final Map<String, String> raw;
  final CardIdentity identity;
  final int quantity;
  final String? condition;
  final String? language;
}

/// Parses ManaBox CSV exports into canonical (printing, finish) stacks.
///
/// Column positions are located by header name (case-insensitive, trimmed) —
/// never positional. Rows are validated against the local corpus: the
/// Scryfall ID must exist and the printing must be available in the claimed
/// finish. Duplicate identities (e.g. NM and LP rows of the same printing)
/// merge: quantities sum, first non-empty condition/language wins.
class ManaBoxParser {
  ManaBoxParser(this._corpus);

  final CorpusDatabase _corpus;

  /// Max distinct Scryfall IDs per corpus lookup query.
  static const int lookupChunkSize = 500;

  /// UTF-8 BOM as decoded into a Dart string.
  static const _bom = '\uFEFF';

  static const _colScryfallId = 'scryfall id';
  static const _colFoil = 'foil';
  static const _colQuantity = 'quantity';
  static const _colCondition = 'condition';
  static const _colLanguage = 'language';

  /// UTF-8-decodes [bytes] and delegates to [parseString].
  Future<ManaBoxParseResult> parseBytes(Uint8List bytes) {
    return parseString(utf8.decode(bytes));
  }

  /// Parses [csvText] and validates every row against the corpus.
  ///
  /// Throws a [FormatException] when the header row lacks the required
  /// `Scryfall ID`, `Foil`, or `Quantity` columns (i.e. not a ManaBox CSV).
  Future<ManaBoxParseResult> parseString(String csvText) async {
    var text = csvText;
    // Strip a UTF-8 BOM (decoded to U+FEFF) and normalise CRLF line endings.
    if (text.startsWith(_bom)) text = text.substring(1);
    text = text.replaceAll('\r\n', '\n');

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(text);

    if (rows.isEmpty) {
      return const ManaBoxParseResult(
        matched: [],
        unmatched: [],
        totalDataRows: 0,
      );
    }

    final header = rows.first.map((c) => c.toString().trim()).toList();
    final columnIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      columnIndex.putIfAbsent(header[i].toLowerCase(), () => i);
    }

    final idCol = columnIndex[_colScryfallId];
    final foilCol = columnIndex[_colFoil];
    final qtyCol = columnIndex[_colQuantity];
    if (idCol == null || foilCol == null || qtyCol == null) {
      final missing = [
        if (idCol == null) 'Scryfall ID',
        if (foilCol == null) 'Foil',
        if (qtyCol == null) 'Quantity',
      ];
      throw FormatException(
        'Not a ManaBox CSV — missing column(s): ${missing.join(', ')}',
      );
    }
    final conditionCol = columnIndex[_colCondition];
    final languageCol = columnIndex[_colLanguage];
    final requiredWidth =
        [idCol, foilCol, qtyCol].reduce(math.max) + 1;

    final unmatched = <UnmatchedRow>[];
    final candidates = <_Candidate>[];
    var totalDataRows = 0;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final lineNumber = r + 1;
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      totalDataRows++;

      final raw = <String, String>{};
      for (var i = 0; i < header.length && i < row.length; i++) {
        if (header[i].isEmpty) continue;
        raw[header[i]] = row[i].toString();
      }

      if (row.length < requiredWidth) {
        unmatched.add(UnmatchedRow(
          lineNumber: lineNumber,
          raw: raw,
          reason: UnmatchReason.malformedRow,
        ));
        continue;
      }

      final id = row[idCol].toString().trim();
      final finish = _parseFinish(row[foilCol].toString());
      final quantity = int.tryParse(row[qtyCol].toString().trim());
      final identity =
          id.isNotEmpty && finish != null ? CardIdentity(id, finish) : null;

      if (id.isEmpty) {
        unmatched.add(UnmatchedRow(
          lineNumber: lineNumber,
          raw: raw,
          reason: UnmatchReason.missingScryfallId,
        ));
        continue;
      }
      if (finish == null) {
        unmatched.add(UnmatchedRow(
          lineNumber: lineNumber,
          raw: raw,
          reason: UnmatchReason.invalidFinish,
        ));
        continue;
      }
      if (quantity == null || quantity < 1) {
        unmatched.add(UnmatchedRow(
          lineNumber: lineNumber,
          raw: raw,
          reason: UnmatchReason.invalidQuantity,
          resolvedIdentity: identity,
        ));
        continue;
      }

      candidates.add(_Candidate(
        lineNumber: lineNumber,
        raw: raw,
        identity: identity!,
        quantity: quantity,
        condition: _nullIfEmpty(_cellAt(row, conditionCol)),
        language: _nullIfEmpty(_cellAt(row, languageCol)),
      ));
    }

    final cardById = await _lookupCards(
      candidates.map((c) => c.identity.scryfallId).toSet().toList(),
    );

    // Merge duplicate identities in file order.
    final merged = <CardIdentity, MatchedStackRow>{};
    for (final candidate in candidates) {
      final card = cardById[candidate.identity.scryfallId];
      if (card == null) {
        unmatched.add(UnmatchedRow(
          lineNumber: candidate.lineNumber,
          raw: candidate.raw,
          reason: UnmatchReason.unknownScryfallId,
          resolvedIdentity: candidate.identity,
        ));
        continue;
      }
      final availableList = card.finishes.split(',').map((f) => f.trim().toLowerCase()).toList();
      var identity = candidate.identity;
      if (!availableList.contains(identity.finish.name)) {
        if (availableList.length == 1) {
          // Single-finish printing: coerce to the only available finish rather
          // than rejecting. ManaBox sometimes records the wrong finish for cards
          // that only exist in one finish.
          final coerced = Finish.tryParse(availableList.first);
          if (coerced != null) {
            identity = CardIdentity(identity.scryfallId, coerced);
          } else {
            unmatched.add(UnmatchedRow(
              lineNumber: candidate.lineNumber,
              raw: candidate.raw,
              reason: UnmatchReason.finishUnavailable,
              resolvedIdentity: candidate.identity,
            ));
            continue;
          }
        } else {
          unmatched.add(UnmatchedRow(
            lineNumber: candidate.lineNumber,
            raw: candidate.raw,
            reason: UnmatchReason.finishUnavailable,
            resolvedIdentity: candidate.identity,
          ));
          continue;
        }
      }

      final prior = merged[identity];
      merged[identity] = MatchedStackRow(
        identity: identity,
        quantity: (prior?.quantity ?? 0) + candidate.quantity,
        condition: prior?.condition ?? candidate.condition,
        language: prior?.language ?? candidate.language,
        corpusCard: card,
      );
    }

    unmatched.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));

    return ManaBoxParseResult(
      matched: merged.values.toList(),
      unmatched: unmatched,
      totalDataRows: totalDataRows,
    );
  }

  /// Batch-fetches corpus rows for [scryfallIds] in chunks of
  /// [lookupChunkSize].
  Future<Map<String, Card>> _lookupCards(List<String> scryfallIds) async {
    final cardById = <String, Card>{};
    for (var i = 0; i < scryfallIds.length; i += lookupChunkSize) {
      final chunk = scryfallIds.sublist(
        i,
        math.min(i + lookupChunkSize, scryfallIds.length),
      );
      final found = await (_corpus.select(_corpus.cards)
            ..where((c) => c.scryfallId.isIn(chunk)))
          .get();
      for (final card in found) {
        cardById[card.scryfallId] = card;
      }
    }
    return cardById;
  }

  /// Maps a ManaBox `Foil` cell to a [Finish]:
  /// `normal` → nonfoil, `foil` → foil, `etched` → etched.
  static Finish? _parseFinish(String value) {
    switch (value.trim().toLowerCase()) {
      case 'normal':
        return Finish.nonfoil;
      case 'foil':
        return Finish.foil;
      case 'etched':
        return Finish.etched;
      default:
        return null;
    }
  }

  static String _cellAt(List<dynamic> row, int? index) {
    if (index == null || index >= row.length) return '';
    return row[index].toString().trim();
  }

  static String? _nullIfEmpty(String value) => value.isEmpty ? null : value;
}

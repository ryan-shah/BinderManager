import 'package:drift/drift.dart';

import '../database/corpus_database.dart';
import '../database/tables/deck_tables.dart';

/// One successfully tokenized card line, before corpus resolution.
class RawDeckLine {
  const RawDeckLine({
    required this.lineNumber,
    required this.quantity,
    required this.name,
    this.setCode,
    this.collectorNumber,
    required this.section,
  });

  /// 1-based line number in the source text.
  final int lineNumber;

  final int quantity;

  /// Card name exactly as written in the list.
  final String name;

  /// Set code as written (e.g. `M10`), if the line carried a `(SET)` suffix.
  final String? setCode;

  /// Collector number as written, if given (only valid after a set code).
  final String? collectorNumber;

  final DeckSection section;
}

/// A line that could not be tokenized as a card, header, or blank.
class DecklistLineError {
  const DecklistLineError(this.lineNumber, this.message);

  final int lineNumber;
  final String message;

  @override
  String toString() => 'Line $lineNumber: $message';
}

/// How a [RawDeckLine] resolved against the corpus.
sealed class LineResolution {
  const LineResolution();
}

/// Exactly one printing matched (set+collector hit, or a name with a
/// single printing in the corpus).
class ResolvedExact extends LineResolution {
  const ResolvedExact(this.card);

  final Card card;
}

/// The name matched multiple printings — a fidelity choice is needed (D3).
class ResolvedByName extends LineResolution {
  const ResolvedByName(this.candidates);

  final List<Card> candidates;
}

/// Nothing in the corpus matched.
class Unresolved extends LineResolution {
  const Unresolved();
}

/// A tokenized line paired with its corpus resolution.
class ParsedDeckLine {
  const ParsedDeckLine({required this.raw, required this.resolution});

  final RawDeckLine raw;
  final LineResolution resolution;
}

/// Result of [DecklistParser.parse]: resolved lines plus per-line errors.
class DecklistParseResult {
  const DecklistParseResult({required this.lines, required this.errors});

  final List<ParsedDeckLine> lines;
  final List<DecklistLineError> errors;

  /// True when any line resolved to multiple printings, so the import
  /// flow must show the printing-fidelity prompt (D3).
  bool get needsFidelityChoice =>
      lines.any((l) => l.resolution is ResolvedByName);
}

/// Parses plain-text decklists (`Nx Name (SET) Collector#`, D10) in two
/// layers: a pure static tokenizer and a corpus resolver.
class DecklistParser {
  DecklistParser(this._corpus);

  final CorpusDatabase _corpus;

  // ---------------------------------------------------------------------------
  // Tokenizer (pure, no DB)
  // ---------------------------------------------------------------------------

  /// Card-line grammar: `4 Name`, `4x Name`, optional `(SET)` (2-6 alnum),
  /// optional collector number only after a set.
  static final _cardLine = RegExp(
    r'^(\d+)[xX]?\s+(.+?)(?:\s+\(([A-Za-z0-9]{2,6})\)(?:\s+([A-Za-z0-9★†\-]+))?)?\s*$',
  );

  /// Moxfield finish markers, tolerated but not honored (v1 grammar carries
  /// no finish).
  static final _finishMarker = RegExp(r'\s*\*[FEfe]\*\s*$');

  /// MTGO per-line sideboard prefix.
  static final _sbPrefix = RegExp(r'^[sS][bB]:\s*');

  static const _mainHeaders = {'deck', 'mainboard', 'commander'};
  static const _sideHeaders = {'sideboard', 'side'};
  static const _maybeHeaders = {'maybeboard', 'considering'};

  /// Returns the section a header line selects, or null if the line is not
  /// a section header. Case-insensitive; tolerates one trailing colon.
  static DeckSection? _headerSection(String trimmed) {
    var normalized = trimmed.toLowerCase();
    if (normalized.endsWith(':')) {
      normalized = normalized.substring(0, normalized.length - 1).trimRight();
    }
    if (_mainHeaders.contains(normalized)) return DeckSection.main;
    if (_sideHeaders.contains(normalized)) return DeckSection.sideboard;
    if (_maybeHeaders.contains(normalized)) return DeckSection.maybeboard;
    return null;
  }

  /// Tokenizes [text] into card lines, dropping errors. See [parse] for the
  /// variant that reports per-line errors.
  static List<RawDeckLine> tokenize(String text) => _tokenize(text).$1;

  static (List<RawDeckLine>, List<DecklistLineError>) _tokenize(String text) {
    final sourceLines = text.split('\n');

    // Blank-line rule: a blank line after >=1 parsed main card switches to
    // sideboard ONLY if the text has no explicit section headers anywhere
    // (Arena convention). Type-grouped lists with headers keep blank lines
    // as harmless separators.
    final hasHeaders =
        sourceLines.any((l) => _headerSection(l.trim()) != null);

    final raws = <RawDeckLine>[];
    final errors = <DecklistLineError>[];
    var section = DeckSection.main;
    var mainCards = 0;
    var blankSwitched = false;

    for (var i = 0; i < sourceLines.length; i++) {
      final lineNumber = i + 1;
      var line = sourceLines[i].trim();

      if (line.isEmpty) {
        if (!hasHeaders &&
            !blankSwitched &&
            mainCards > 0 &&
            section == DeckSection.main) {
          section = DeckSection.sideboard;
          blankSwitched = true;
        }
        continue;
      }

      final header = _headerSection(line);
      if (header != null) {
        section = header;
        continue;
      }

      var lineSection = section;
      final sb = _sbPrefix.firstMatch(line);
      if (sb != null) {
        lineSection = DeckSection.sideboard;
        line = line.substring(sb.end);
      }

      line = line.replaceFirst(_finishMarker, '');

      final match = _cardLine.firstMatch(line);
      if (match == null) {
        errors.add(DecklistLineError(lineNumber, 'Unrecognized line: "$line"'));
        continue;
      }

      final quantity = int.parse(match.group(1)!);
      if (quantity < 1) {
        errors.add(
          DecklistLineError(lineNumber, 'Quantity must be at least 1'),
        );
        continue;
      }

      raws.add(RawDeckLine(
        lineNumber: lineNumber,
        quantity: quantity,
        name: match.group(2)!.trim(),
        setCode: match.group(3),
        collectorNumber: match.group(4),
        section: lineSection,
      ));
      if (lineSection == DeckSection.main) mainCards++;
    }

    return (raws, errors);
  }

  // ---------------------------------------------------------------------------
  // Resolver (batched corpus queries)
  // ---------------------------------------------------------------------------

  /// Tokenizes and resolves [text] against the corpus.
  ///
  /// Resolution order per line:
  /// 1. `(SET) #` → exact set+collector match.
  /// 2. Miss (or `(SET)` without collector) → set+name fallback.
  /// 3. Name-only → case-insensitive exact name, then DFC front-face
  ///    fallback (`name LIKE 'Front //%'`).
  /// 4. Still nothing → [Unresolved].
  Future<DecklistParseResult> parse(String text) async {
    final (raws, errors) = _tokenize(text);
    final resolutions = List<LineResolution?>.filled(raws.length, null);

    await _resolveBySetAndCollector(raws, resolutions);
    await _resolveBySetAndName(raws, resolutions);
    await _resolveByName(raws, resolutions);

    final lines = <ParsedDeckLine>[
      for (var i = 0; i < raws.length; i++)
        ParsedDeckLine(
          raw: raws[i],
          resolution: resolutions[i] ?? const Unresolved(),
        ),
    ];
    return DecklistParseResult(lines: lines, errors: errors);
  }

  Future<void> _resolveBySetAndCollector(
    List<RawDeckLine> raws,
    List<LineResolution?> resolutions,
  ) async {
    final indices = <int>[
      for (var i = 0; i < raws.length; i++)
        if (raws[i].setCode != null && raws[i].collectorNumber != null) i,
    ];
    if (indices.isEmpty) return;

    final sets =
        indices.map((i) => raws[i].setCode!.toLowerCase()).toSet().toList();
    final numbers = indices
        .map((i) => raws[i].collectorNumber!.toLowerCase())
        .toSet()
        .toList();

    final rows = await (_corpus.select(_corpus.cards)
          ..where((c) =>
              c.setCode.isIn(sets) &
              c.collectorNumber.lower().isIn(numbers)))
        .get();
    final byKey = <String, Card>{
      for (final c in rows.reversed)
        '${c.setCode}|${c.collectorNumber.toLowerCase()}': c,
    };

    for (final i in indices) {
      final key = '${raws[i].setCode!.toLowerCase()}|'
          '${raws[i].collectorNumber!.toLowerCase()}';
      final card = byKey[key];
      if (card != null) resolutions[i] = ResolvedExact(card);
      // Misses fall through to the set+name pass.
    }
  }

  Future<void> _resolveBySetAndName(
    List<RawDeckLine> raws,
    List<LineResolution?> resolutions,
  ) async {
    final indices = <int>[
      for (var i = 0; i < raws.length; i++)
        if (raws[i].setCode != null && resolutions[i] == null) i,
    ];
    if (indices.isEmpty) return;

    final sets =
        indices.map((i) => raws[i].setCode!.toLowerCase()).toSet().toList();
    final names =
        indices.map((i) => raws[i].name.toUpperCase()).toSet().toList();

    final rows = await (_corpus.select(_corpus.cards)
          ..where((c) => c.setCode.isIn(sets) & c.name.upper().isIn(names)))
        .get();
    final grouped = <String, List<Card>>{};
    for (final c in rows) {
      grouped
          .putIfAbsent('${c.setCode}|${c.name.toUpperCase()}', () => [])
          .add(c);
    }

    for (final i in indices) {
      final set = raws[i].setCode!.toLowerCase();
      var matches = grouped['$set|${raws[i].name.toUpperCase()}'];
      matches ??= await _dfcFallback(raws[i].name, setCode: set);
      if (matches != null && matches.isNotEmpty) {
        resolutions[i] = _fromMatches(matches);
      }
      // Still-missing lines stay null → Unresolved.
    }
  }

  Future<void> _resolveByName(
    List<RawDeckLine> raws,
    List<LineResolution?> resolutions,
  ) async {
    final indices = <int>[
      for (var i = 0; i < raws.length; i++)
        if (raws[i].setCode == null && resolutions[i] == null) i,
    ];
    if (indices.isEmpty) return;

    final names =
        indices.map((i) => raws[i].name.toUpperCase()).toSet().toList();
    final rows = await (_corpus.select(_corpus.cards)
          ..where((c) => c.name.upper().isIn(names)))
        .get();
    final grouped = <String, List<Card>>{};
    for (final c in rows) {
      grouped.putIfAbsent(c.name.toUpperCase(), () => []).add(c);
    }

    for (final i in indices) {
      var matches = grouped[raws[i].name.toUpperCase()];
      matches ??= await _dfcFallback(raws[i].name);
      if (matches != null && matches.isNotEmpty) {
        resolutions[i] = _fromMatches(matches);
      }
    }
  }

  /// DFC front-face fallback: transform/MDFC cards store `Front // Back`,
  /// so an exact-name miss retries as `name LIKE 'TheName //%'` (SQLite
  /// LIKE is ASCII case-insensitive).
  Future<List<Card>?> _dfcFallback(String name, {String? setCode}) async {
    final query = _corpus.select(_corpus.cards)
      ..where((c) => c.name.like('$name //%'));
    if (setCode != null) {
      query.where((c) => c.setCode.equals(setCode));
    }
    final rows = await query.get();
    return rows.isEmpty ? null : rows;
  }

  static LineResolution _fromMatches(List<Card> matches) {
    if (matches.length == 1) return ResolvedExact(matches.first);
    final sorted = [...matches]..sort((a, b) {
        final bySet = a.setCode.compareTo(b.setCode);
        if (bySet != 0) return bySet;
        return a.collectorNumber.compareTo(b.collectorNumber);
      });
    return ResolvedByName(sorted);
  }
}

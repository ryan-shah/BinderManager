/// High-level facade that ties together the query parser and SQL compiler.
///
/// The [QueryEngine] is the primary entry point for executing Scryfall-subset
/// queries against the card corpus database.
library;

import 'package:drift/drift.dart';

import '../allocation/reservation.dart';
import '../database/corpus_database.dart';
import '../database/user_database.dart';
import 'ast.dart';
import 'compiler.dart';
import 'parser.dart';

/// The result of a search query executed by [QueryEngine].
class QueryResult {
  /// The matching cards for this page.
  final List<Card> cards;

  /// The total number of cards matching the query (ignoring limit/offset).
  final int totalCount;

  /// Non-null if the query string could not be parsed.
  final String? parseError;

  /// Zero-based position in the input where the parse error occurred.
  final int? errorPosition;

  const QueryResult({
    this.cards = const [],
    this.totalCount = 0,
    this.parseError,
    this.errorPosition,
  });

  /// Whether the query was parsed and executed successfully.
  bool get isSuccess => parseError == null;
}

/// Facade that parses a query string, compiles it to SQL, and executes it
/// against the [CorpusDatabase].
///
/// Usage:
/// ```dart
/// final engine = QueryEngine(db);
/// final result = await engine.search('c:W t:creature usd>1');
/// for (final card in result.cards) { ... }
/// ```
class QueryEngine {
  final CorpusDatabase _db;

  /// Durable user data (collection stacks, decks). When present, `have:`
  /// and `unused:` compile against real owned/idle quantities; when null
  /// they match nothing (empty collection).
  final UserDatabase? _userDb;

  QueryEngine(this._db, {UserDatabase? userDb}) : _userDb = userDb;

  /// Parse and execute a query string, returning matching cards.
  ///
  /// An empty [query] returns an empty result (no cards). Use [limit] and
  /// [offset] for pagination.
  Future<QueryResult> search(
    String query, {
    int limit = 100,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const QueryResult();
    }

    final parseResult = parse(trimmed);

    if (!parseResult.isSuccess) {
      return QueryResult(
        parseError: parseResult.error,
        errorPosition: parseResult.errorPosition,
      );
    }

    final ast = parseResult.ast;
    if (ast == null) {
      return const QueryResult();
    }

    // Resolve the collection snapshot only when the query actually uses
    // have:/unused: — fetched per search, never cached, so results are
    // always consistent with the latest imports and deck edits.
    ReservationSummary? collection;
    final userDb = _userDb;
    if (userDb != null && _usesCollectionFields(ast)) {
      collection = await _loadReservations(userDb);
    }

    final compiler = QueryCompiler(_db.cards, collection: collection);
    final whereExpr = compiler.compile(ast);

    // Count total matches.
    final countExpr = countAll();
    final countQuery = _db.selectOnly(_db.cards)
      ..addColumns([countExpr])
      ..where(whereExpr);
    final countResult = await countQuery.getSingle();
    final totalCount = countResult.read(countExpr) ?? 0;

    // Fetch the page.
    final selectQuery = _db.select(_db.cards)
      ..where((_) => whereExpr)
      ..limit(limit, offset: offset);
    final cards = await selectQuery.get();

    return QueryResult(
      cards: cards,
      totalCount: totalCount,
    );
  }

  /// Parse a query string without executing it.
  ///
  /// Returns the AST or error information. Useful for syntax validation
  /// and UI feedback.
  ParseResult parse(String query) {
    return parseQuery(query);
  }

  /// Whether the AST contains a `have:` or `unused:` filter anywhere.
  static bool _usesCollectionFields(QueryNode node) => switch (node) {
        FilterNode(:final field) => field == 'have' || field == 'unused',
        AndNode(:final children) => children.any(_usesCollectionFields),
        OrNode(:final left, :final right) =>
          _usesCollectionFields(left) || _usesCollectionFields(right),
        NotNode(:final child) => _usesCollectionFields(child),
        TextNode() => false,
      };

  static Future<ReservationSummary> _loadReservations(UserDatabase db) async {
    final stacks = await db.select(db.stacks).get();
    final decks = await db.select(db.decks).get();
    final entries = await db.select(db.deckEntries).get();
    return computeReservations(stacks: stacks, decks: decks, entries: entries);
  }
}

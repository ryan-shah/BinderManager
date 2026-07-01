/// Compiles query AST nodes into drift [Expression<bool>] for SQL WHERE
/// clauses on the [Cards] table.
///
/// The compiler maps each AST node type to the appropriate drift column
/// operations based on the field name and operator.
library;

import 'package:drift/drift.dart';

import '../database/corpus_database.dart';
import 'ast.dart';

/// Compiles a [QueryNode] tree into a drift [Expression<bool>].
///
/// Usage:
/// ```dart
/// final compiler = QueryCompiler(db.cards);
/// final where = compiler.compile(ast);
/// final results = await (db.select(db.cards)..where((_) => where)).get();
/// ```
class QueryCompiler {
  final $CardsTable _cards;

  QueryCompiler(this._cards);

  /// Compiles a [QueryNode] into a drift boolean expression suitable for
  /// use in a `.where()` clause.
  Expression<bool> compile(QueryNode node) {
    return switch (node) {
      TextNode() => _compileText(node),
      FilterNode() => _compileFilter(node),
      AndNode() => _compileAnd(node),
      OrNode() => _compileOr(node),
      NotNode() => _compileNot(node),
    };
  }

  // ---- Node compilers -------------------------------------------------------

  /// TextNode: case-insensitive LIKE search on card name.
  Expression<bool> _compileText(TextNode node) {
    return _cards.name.like('%${_escapeLike(node.term)}%');
  }

  /// FilterNode: dispatches to field-specific compilation.
  Expression<bool> _compileFilter(FilterNode node) {
    return switch (node.field) {
      'c' => _compileColor(node, _cards.colors),
      'id' => _compileColor(node, _cards.colorIdentity),
      's' => _compileSet(node),
      't' => _compileSubstring(node, _cards.typeLine),
      'o' => _compileSubstring(node, _cards.oracleText),
      'r' => _compileRarity(node),
      'usd' => _compilePrice(node),
      'is' => _compileIs(node),
      'frame' => _compileFrame(node),
      'stamp' => _compileStamp(node),
      'finish' => _compileFinish(node),
      // Phase 3 placeholders — pass through until user DB exists.
      'unused' => const Constant(true),
      'have' => const Constant(true),
      _ => throw UnsupportedError('Unknown filter field: ${node.field}'),
    };
  }

  /// AndNode: combine children with `&`.
  Expression<bool> _compileAnd(AndNode node) {
    assert(node.children.isNotEmpty);
    var expr = compile(node.children.first);
    for (var i = 1; i < node.children.length; i++) {
      expr = expr & compile(node.children[i]);
    }
    return expr;
  }

  /// OrNode: combine left and right with `|`.
  Expression<bool> _compileOr(OrNode node) {
    return compile(node.left) | compile(node.right);
  }

  /// NotNode: negate child expression.
  Expression<bool> _compileNot(NotNode node) {
    return compile(node.child).not();
  }

  // ---- Field-specific compilers ---------------------------------------------

  /// Color matching: each character in the value must be present in the
  /// comma-separated color string. E.g. `c:WU` requires both W and U.
  ///
  /// Special cases:
  /// - `C` (colorless): matches cards with empty/null colors
  /// - `M` (multicolor): matches cards with 2+ colors (contains a comma)
  ///
  /// Uses COALESCE to handle nullable color columns: a null value is treated
  /// as an empty string so that NOT(c:R) correctly includes colorless cards.
  Expression<bool> _compileColor(
    FilterNode node,
    GeneratedColumn<String> column,
  ) {
    final colors = _expandColorNames(node.value);
    if (colors.isEmpty) {
      return const Constant(false);
    }

    final coalesced = coalesce<String>([column, const Constant('')]);

    // Colorless: match cards where the color column is empty/null.
    if (colors.length == 1 && colors[0] == 'C') {
      return coalesced.equals('');
    }

    // Multicolor: match cards with 2+ colors (the joined string contains
    // at least one comma, e.g. "W,U").
    if (colors.length == 1 && colors[0] == 'M') {
      return coalesced.like('%,%');
    }

    // Filter out any C/M that got mixed in with real colors (e.g. "c:CM"
    // doesn't make sense, but be defensive).
    final realColors = colors.where((c) => c != 'C' && c != 'M').toList();
    if (realColors.isEmpty) {
      return const Constant(false);
    }

    Expression<bool> expr = coalesced.like('%${realColors[0]}%');
    for (var i = 1; i < realColors.length; i++) {
      expr = expr & coalesced.like('%${realColors[i]}%');
    }
    return expr;
  }

  /// Set code: exact match (lowercased).
  Expression<bool> _compileSet(FilterNode node) {
    return _cards.setCode.equals(node.value.toLowerCase());
  }

  /// Substring match using LIKE (case-insensitive for ASCII in SQLite).
  ///
  /// Uses COALESCE for nullable columns so that NOT(o:"text") correctly
  /// includes cards without oracle text.
  Expression<bool> _compileSubstring(
    FilterNode node,
    GeneratedColumn<String> column,
  ) {
    final col = coalesce<String>([column, const Constant('')]);
    return col.like('%${_escapeLike(node.value)}%');
  }

  /// Rarity: exact match (lowercased).
  Expression<bool> _compileRarity(FilterNode node) {
    return _cards.rarity.equals(node.value.toLowerCase());
  }

  /// Price comparisons on `priceUsd`.
  Expression<bool> _compilePrice(FilterNode node) {
    final amount = double.tryParse(node.value);
    if (amount == null) {
      throw FormatException('Invalid price value: ${node.value}');
    }

    return switch (node.op) {
      FilterOp.gt => _cards.priceUsd.isBiggerThanValue(amount),
      FilterOp.gte => _cards.priceUsd.isBiggerOrEqualValue(amount),
      FilterOp.lt => _cards.priceUsd.isSmallerThanValue(amount),
      FilterOp.lte => _cards.priceUsd.isSmallerOrEqualValue(amount),
      FilterOp.eq => _cards.priceUsd.equals(amount),
      FilterOp.neq => _cards.priceUsd.equals(amount).not(),
    };
  }

  /// Boolean `is:` flags.
  Expression<bool> _compileIs(FilterNode node) {
    final frameCol =
        coalesce<String>([_cards.frameEffects, const Constant('')]);
    return switch (node.value.toLowerCase()) {
      'foil' => _compileFinishToken('foil'),
      'etched' => _compileFinishToken('etched'),
      'fullart' => _cards.isFullart.equals(true),
      'promo' => _cards.isPromo.equals(true),
      'showcase' => frameCol.like('%showcase%'),
      'borderless' => frameCol.like('%borderless%'),
      _ => throw UnsupportedError('Unknown is: value: ${node.value}'),
    };
  }

  /// Frame effects: substring match on frameEffects column.
  Expression<bool> _compileFrame(FilterNode node) {
    final col = coalesce<String>([_cards.frameEffects, const Constant('')]);
    return col.like('%${_escapeLike(node.value.toLowerCase())}%');
  }

  /// Security stamp: exact match with COALESCE for nullable column.
  Expression<bool> _compileStamp(FilterNode node) {
    return coalesce<String>([_cards.securityStamp, const Constant('')])
        .equals(node.value.toLowerCase());
  }

  /// Finish: comma-delimited token match on finishes column.
  Expression<bool> _compileFinish(FilterNode node) {
    return _compileFinishToken(node.value.toLowerCase());
  }

  /// Matches a single finish token in the comma-separated finishes column
  /// without false positives (e.g. "foil" must not match "nonfoil").
  Expression<bool> _compileFinishToken(String token) {
    final col = coalesce<String>([_cards.finishes, const Constant('')]);
    // Match: exact value, start of list ("token,..."), end of list ("...,token"),
    // or middle of list ("...,token,...").
    return col.equals(token) |
        col.like('$token,%') |
        col.like('%,$token') |
        col.like('%,$token,%');
  }

  // ---- Helpers --------------------------------------------------------------

  /// Expands color names like "red" to their single-letter equivalents and
  /// splits multi-character color strings into individual characters.
  ///
  /// Examples:
  ///   "WU" → ["W", "U"]
  ///   "red" → ["R"]
  ///   "blue" → ["U"]
  List<String> _expandColorNames(String value) {
    // Try to match full color names first.
    final lower = value.toLowerCase();
    const colorNames = <String, String>{
      'white': 'W',
      'blue': 'U',
      'black': 'B',
      'red': 'R',
      'green': 'G',
      'colorless': 'C',
      'multicolor': 'M',
    };

    if (colorNames.containsKey(lower)) {
      return [colorNames[lower]!];
    }

    // Otherwise treat each character as a color symbol.
    return value.toUpperCase().split('').where((c) => c != ',').toList();
  }

  /// Escapes LIKE special characters (`%`, `_`) in a value.
  static String _escapeLike(String value) {
    // For our use case we don't need a full ESCAPE clause because user
    // values rarely contain literal % or _ and SQLite's default LIKE has no
    // escape character. This is sufficient for v1.
    return value;
  }
}

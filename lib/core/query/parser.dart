/// Recursive descent parser for the Scryfall-subset query language.
///
/// Supports:
/// - Bare text terms (match card name): `lightning bolt`
/// - Filter prefixes: `c:WU`, `t:creature`, `usd>5`, `o:"draw a card"`
/// - Implicit AND between terms
/// - Explicit `OR` (case-insensitive)
/// - Negation with `-` prefix: `-c:B`
/// - Quoted values: `t:"legendary creature"`
///
/// Grammar (informal):
/// ```
/// query      = orExpr*
/// orExpr     = andExpr ('OR' andExpr)*
/// andExpr    = atom+
/// atom       = '-' atom | filter | quotedText | bareText
/// filter     = field op value
/// ```
library;

import 'ast.dart';

/// The result of parsing a query string.
class ParseResult {
  /// The parsed AST, or null if the input was empty or had an error.
  final QueryNode? ast;

  /// Human-readable error message, or null on success.
  final String? error;

  /// Zero-based position in the input where the error occurred.
  final int? errorPosition;

  const ParseResult({this.ast, this.error, this.errorPosition});

  /// Whether parsing succeeded (possibly with an empty/null AST for blank input).
  bool get isSuccess => error == null;
}

/// Known filter field prefixes and their canonical names.
///
/// Multiple aliases map to the same canonical field so that e.g. `color:` and
/// `c:` both produce `FilterNode("c", ...)`.
const _fieldAliases = <String, String>{
  'c': 'c',
  'color': 'c',
  'id': 'id',
  'identity': 'id',
  'usd': 'usd',
  's': 's',
  'set': 's',
  'e': 's',
  't': 't',
  'type': 't',
  'o': 'o',
  'oracle': 'o',
  'r': 'r',
  'rarity': 'r',
  'is': 'is',
  'frame': 'frame',
  'stamp': 'stamp',
  'finish': 'finish',
};

/// Parses a Scryfall-subset query string into an AST.
///
/// Returns a [ParseResult] containing either the AST or error information.
ParseResult parseQuery(String input) {
  final parser = _Parser(input);
  return parser.parse();
}

// ---------------------------------------------------------------------------
// Internal parser implementation
// ---------------------------------------------------------------------------

class _Parser {
  final String _input;
  int _pos = 0;

  _Parser(this._input);

  ParseResult parse() {
    _skipWhitespace();
    if (_isAtEnd) {
      return const ParseResult(ast: null);
    }

    try {
      final node = _parseOrExpr();
      _skipWhitespace();
      if (!_isAtEnd) {
        return ParseResult(
          error: 'Unexpected input',
          errorPosition: _pos,
        );
      }
      return ParseResult(ast: node);
    } on _ParseError catch (e) {
      return ParseResult(error: e.message, errorPosition: e.position);
    }
  }

  // ---- Grammar rules -------------------------------------------------------

  /// orExpr = andExpr ('OR' andExpr)*
  QueryNode _parseOrExpr() {
    var left = _parseAndExpr();

    while (_matchOrKeyword()) {
      final right = _parseAndExpr();
      left = OrNode(left, right);
    }

    return left;
  }

  /// andExpr = atom+
  ///
  /// Collects one or more atoms; if there are multiple, wraps them in AndNode.
  QueryNode _parseAndExpr() {
    final children = <QueryNode>[];

    while (!_isAtEnd && !_isOrKeywordAhead()) {
      children.add(_parseAtom());
      _skipWhitespace();
    }

    if (children.isEmpty) {
      throw _ParseError('Expected a search term', _pos);
    }

    return children.length == 1 ? children.first : AndNode(children);
  }

  /// atom = '-' atom | filter | quotedText | bareText
  QueryNode _parseAtom() {
    _skipWhitespace();

    // Negation
    if (_peek() == '-') {
      // Make sure this isn't just a bare hyphen or hyphenated word like
      // "well-known". We treat `-` as negation only when followed by a letter,
      // quote, or another `-`.
      final nextIdx = _pos + 1;
      if (nextIdx < _input.length) {
        final next = _input[nextIdx];
        if (_isLetterOrQuote(next)) {
          _pos++; // consume the '-'
          final child = _parseAtom();
          return NotNode(child);
        }
      }
    }

    // Try to parse a filter (field:value or field>value etc.)
    final filter = _tryParseFilter();
    if (filter != null) return filter;

    // Quoted text (bare, not after a field prefix)
    if (_peek() == '"') {
      final term = _parseQuotedString();
      return TextNode(term);
    }

    // Bare word
    final word = _parseWord();
    if (word.isEmpty) {
      throw _ParseError('Unexpected character', _pos);
    }
    return TextNode(word);
  }

  /// Attempts to parse a filter expression. Returns null if the current
  /// position doesn't look like a filter.
  FilterNode? _tryParseFilter() {
    final saved = _pos;

    // Read a potential field name (letters only).
    final field = _readFieldName();
    if (field.isEmpty) {
      _pos = saved;
      return null;
    }

    // Check if this is a known filter field.
    final canonical = _fieldAliases[field.toLowerCase()];
    if (canonical == null) {
      _pos = saved;
      return null;
    }

    // Read operator
    final op = _tryReadOperator();
    if (op == null) {
      _pos = saved;
      return null;
    }

    // Read value
    final value = _parseValue();
    if (value.isEmpty) {
      throw _ParseError('Expected a value after "$field$op"', _pos);
    }

    return FilterNode(canonical, op, value);
  }

  // ---- Lexing helpers -------------------------------------------------------

  bool get _isAtEnd => _pos >= _input.length;

  String _peek() => _isAtEnd ? '' : _input[_pos];

  void _skipWhitespace() {
    while (!_isAtEnd && _input[_pos] == ' ') {
      _pos++;
    }
  }

  /// Reads a word consisting of letters and digits (no spaces, no operators).
  String _parseWord() {
    final start = _pos;
    while (!_isAtEnd && _isWordChar(_input[_pos])) {
      _pos++;
    }
    return _input.substring(start, _pos);
  }

  /// Reads a field name: letters only (no digits, no underscores).
  String _readFieldName() {
    final start = _pos;
    while (!_isAtEnd && _isLetter(_input[_pos])) {
      _pos++;
    }
    return _input.substring(start, _pos);
  }

  /// Tries to read an operator at the current position.
  FilterOp? _tryReadOperator() {
    if (_isAtEnd) return null;
    final c = _input[_pos];

    if (c == ':') {
      _pos++;
      return FilterOp.eq;
    }
    if (c == '!' && _pos + 1 < _input.length && _input[_pos + 1] == '=') {
      _pos += 2;
      return FilterOp.neq;
    }
    if (c == '<') {
      if (_pos + 1 < _input.length && _input[_pos + 1] == '=') {
        _pos += 2;
        return FilterOp.lte;
      }
      _pos++;
      return FilterOp.lt;
    }
    if (c == '>') {
      if (_pos + 1 < _input.length && _input[_pos + 1] == '=') {
        _pos += 2;
        return FilterOp.gte;
      }
      _pos++;
      return FilterOp.gt;
    }

    return null;
  }

  /// Parses a value: either a quoted string or a bare word.
  String _parseValue() {
    if (_peek() == '"') {
      return _parseQuotedString();
    }
    return _parseWord();
  }

  /// Parses a double-quoted string, consuming the quotes.
  String _parseQuotedString() {
    assert(_peek() == '"');
    _pos++; // consume opening quote
    final start = _pos;

    while (!_isAtEnd && _input[_pos] != '"') {
      _pos++;
    }

    final value = _input.substring(start, _pos);

    if (_isAtEnd) {
      throw _ParseError('Unterminated quoted string', start - 1);
    }
    _pos++; // consume closing quote

    return value;
  }

  /// Returns true if the next token is the `OR` keyword (case-insensitive).
  bool _isOrKeywordAhead() {
    final saved = _pos;
    _skipWhitespace();

    if (_pos + 2 <= _input.length) {
      final word = _input.substring(_pos, _pos + 2).toUpperCase();
      if (word == 'OR') {
        // Make sure OR is a whole word (followed by space or end).
        final afterOr = _pos + 2;
        if (afterOr >= _input.length || _input[afterOr] == ' ') {
          _pos = saved;
          return true;
        }
      }
    }

    _pos = saved;
    return false;
  }

  /// Consumes the `OR` keyword and any surrounding whitespace.
  bool _matchOrKeyword() {
    _skipWhitespace();

    if (_pos + 2 <= _input.length) {
      final word = _input.substring(_pos, _pos + 2).toUpperCase();
      if (word == 'OR') {
        final afterOr = _pos + 2;
        if (afterOr >= _input.length || _input[afterOr] == ' ') {
          _pos = afterOr;
          _skipWhitespace();
          return true;
        }
      }
    }

    return false;
  }

  bool _isLetter(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isWordChar(String c) {
    final code = c.codeUnitAt(0);
    // Letters, digits, underscore, hyphen, period, apostrophe, comma
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57) ||
        c == '_' ||
        c == '-' ||
        c == '.' ||
        c == '\'' ||
        c == ',';
  }

  bool _isLetterOrQuote(String c) => _isLetter(c) || c == '"';
}

class _ParseError {
  final String message;
  final int position;
  _ParseError(this.message, this.position);
}

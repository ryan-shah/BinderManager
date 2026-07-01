/// AST nodes for the Scryfall-subset query language.
///
/// The AST is schema-agnostic: it captures the structure of a user's query
/// without any knowledge of the database. The [QueryCompiler] is responsible
/// for mapping these nodes to drift SQL expressions.
library;

/// The operator used in a [FilterNode] comparison.
enum FilterOp {
  eq,
  neq,
  lt,
  gt,
  lte,
  gte;

  @override
  String toString() {
    return switch (this) {
      FilterOp.eq => ':',
      FilterOp.neq => '!=',
      FilterOp.lt => '<',
      FilterOp.gt => '>',
      FilterOp.lte => '<=',
      FilterOp.gte => '>=',
    };
  }
}

/// Base class for all query AST nodes.
sealed class QueryNode {
  const QueryNode();
}

/// A bare text search term that matches against card name.
///
/// Example: the query `lightning` produces `TextNode("lightning")`.
class TextNode extends QueryNode {
  final String term;

  const TextNode(this.term);

  @override
  String toString() {
    // If the term contains spaces, quote it so it round-trips correctly.
    if (term.contains(' ')) return '"$term"';
    return term;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TextNode && other.term == term);

  @override
  int get hashCode => term.hashCode;
}

/// A filter expression like `c:WU`, `usd>5`, or `t:"legendary creature"`.
class FilterNode extends QueryNode {
  final String field;
  final FilterOp op;
  final String value;

  const FilterNode(this.field, this.op, this.value);

  @override
  String toString() {
    final v = value.contains(' ') ? '"$value"' : value;
    return '$field$op$v';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilterNode &&
          other.field == field &&
          other.op == op &&
          other.value == value);

  @override
  int get hashCode => Object.hash(field, op, value);
}

/// Logical AND of multiple child nodes (implicit between terms).
///
/// Example: `c:W t:creature` produces
/// `AndNode([FilterNode("c", eq, "W"), FilterNode("t", eq, "creature")])`.
class AndNode extends QueryNode {
  final List<QueryNode> children;

  const AndNode(this.children);

  @override
  String toString() => children.join(' ');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AndNode) return false;
    if (other.children.length != children.length) return false;
    for (var i = 0; i < children.length; i++) {
      if (children[i] != other.children[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(children);
}

/// Logical OR of two nodes.
///
/// Example: `c:W OR c:U` produces
/// `OrNode(FilterNode("c", eq, "W"), FilterNode("c", eq, "U"))`.
class OrNode extends QueryNode {
  final QueryNode left;
  final QueryNode right;

  const OrNode(this.left, this.right);

  @override
  String toString() => '$left OR $right';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrNode && other.left == left && other.right == right);

  @override
  int get hashCode => Object.hash(left, right);
}

/// Logical NOT (negation) of a child node.
///
/// Example: `-c:B` produces `NotNode(FilterNode("c", eq, "B"))`.
class NotNode extends QueryNode {
  final QueryNode child;

  const NotNode(this.child);

  @override
  String toString() => '-$child';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NotNode && other.child == child);

  @override
  int get hashCode => child.hashCode ^ 0x4e4f54; // "NOT"
}

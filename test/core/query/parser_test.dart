import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/query/ast.dart';
import 'package:binder_manager/core/query/parser.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Bare text
  // ---------------------------------------------------------------------------

  group('bare text', () {
    test('single word produces TextNode', () {
      final result = parseQuery('lightning');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const TextNode('lightning')));
    });

    test('two words produce AndNode with two TextNodes', () {
      final result = parseQuery('lightning bolt');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([TextNode('lightning'), TextNode('bolt')])),
      );
    });

    test('quoted text produces single TextNode with spaces', () {
      final result = parseQuery('"lightning bolt"');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const TextNode('lightning bolt')));
    });
  });

  // ---------------------------------------------------------------------------
  // Single filter
  // ---------------------------------------------------------------------------

  group('single filter', () {
    test('c:WU parses as color filter', () {
      final result = parseQuery('c:WU');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('c', FilterOp.eq, 'WU')));
    });

    test('t:creature parses as type filter', () {
      final result = parseQuery('t:creature');
      expect(result.isSuccess, isTrue);
      expect(
          result.ast, equals(const FilterNode('t', FilterOp.eq, 'creature')));
    });

    test('s:mh2 parses as set filter', () {
      final result = parseQuery('s:mh2');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('s', FilterOp.eq, 'mh2')));
    });

    test('r:rare parses as rarity filter', () {
      final result = parseQuery('r:rare');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('r', FilterOp.eq, 'rare')));
    });

    test('o:"draw a card" parses as oracle text filter with quoted value', () {
      final result = parseQuery('o:"draw a card"');
      expect(result.isSuccess, isTrue);
      expect(result.ast,
          equals(const FilterNode('o', FilterOp.eq, 'draw a card')));
    });

    test('is:foil parses as is filter', () {
      final result = parseQuery('is:foil');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('is', FilterOp.eq, 'foil')));
    });

    test('is:fullart parses correctly', () {
      final result = parseQuery('is:fullart');
      expect(result.isSuccess, isTrue);
      expect(
          result.ast, equals(const FilterNode('is', FilterOp.eq, 'fullart')));
    });

    test('is:promo parses correctly', () {
      final result = parseQuery('is:promo');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('is', FilterOp.eq, 'promo')));
    });

    test('frame:showcase parses correctly', () {
      final result = parseQuery('frame:showcase');
      expect(result.isSuccess, isTrue);
      expect(result.ast,
          equals(const FilterNode('frame', FilterOp.eq, 'showcase')));
    });

    test('stamp:oval parses correctly', () {
      final result = parseQuery('stamp:oval');
      expect(result.isSuccess, isTrue);
      expect(
          result.ast, equals(const FilterNode('stamp', FilterOp.eq, 'oval')));
    });

    test('finish:foil parses correctly', () {
      final result = parseQuery('finish:foil');
      expect(result.isSuccess, isTrue);
      expect(
          result.ast, equals(const FilterNode('finish', FilterOp.eq, 'foil')));
    });
  });

  // ---------------------------------------------------------------------------
  // Comparison operators
  // ---------------------------------------------------------------------------

  group('comparison operators', () {
    test('usd>5 parses as greater than', () {
      final result = parseQuery('usd>5');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('usd', FilterOp.gt, '5')));
    });

    test('usd>=10 parses as greater than or equal', () {
      final result = parseQuery('usd>=10');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('usd', FilterOp.gte, '10')));
    });

    test('usd<1 parses as less than', () {
      final result = parseQuery('usd<1');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('usd', FilterOp.lt, '1')));
    });

    test('usd<=20 parses as less than or equal', () {
      final result = parseQuery('usd<=20');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('usd', FilterOp.lte, '20')));
    });

    test('usd:5 parses as equality', () {
      final result = parseQuery('usd:5');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('usd', FilterOp.eq, '5')));
    });
  });

  // ---------------------------------------------------------------------------
  // Negation
  // ---------------------------------------------------------------------------

  group('negation', () {
    test('-c:B parses as negated color filter', () {
      final result = parseQuery('-c:B');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const NotNode(FilterNode('c', FilterOp.eq, 'B'))),
      );
    });

    test('-t:creature parses as negated type filter', () {
      final result = parseQuery('-t:creature');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const NotNode(FilterNode('t', FilterOp.eq, 'creature'))),
      );
    });

    test('negation of bare text works', () {
      final result = parseQuery('-goblin');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const NotNode(TextNode('goblin'))));
    });
  });

  // ---------------------------------------------------------------------------
  // Implicit AND
  // ---------------------------------------------------------------------------

  group('implicit AND', () {
    test('two filters produce AndNode', () {
      final result = parseQuery('c:W t:creature');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          FilterNode('c', FilterOp.eq, 'W'),
          FilterNode('t', FilterOp.eq, 'creature'),
        ])),
      );
    });

    test('three filters produce AndNode with three children', () {
      final result = parseQuery('c:W t:creature s:mh2');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          FilterNode('c', FilterOp.eq, 'W'),
          FilterNode('t', FilterOp.eq, 'creature'),
          FilterNode('s', FilterOp.eq, 'mh2'),
        ])),
      );
    });

    test('mixing text and filters in AND', () {
      final result = parseQuery('dragon t:creature');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          TextNode('dragon'),
          FilterNode('t', FilterOp.eq, 'creature'),
        ])),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Explicit OR
  // ---------------------------------------------------------------------------

  group('explicit OR', () {
    test('c:W OR c:U produces OrNode', () {
      final result = parseQuery('c:W OR c:U');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const OrNode(
          FilterNode('c', FilterOp.eq, 'W'),
          FilterNode('c', FilterOp.eq, 'U'),
        )),
      );
    });

    test('OR is case-insensitive', () {
      final result = parseQuery('c:W or c:U');
      expect(result.isSuccess, isTrue);
      expect(result.ast, isA<OrNode>());
    });

    test('Or (mixed case) works', () {
      final result = parseQuery('c:W Or c:U');
      expect(result.isSuccess, isTrue);
      expect(result.ast, isA<OrNode>());
    });
  });

  // ---------------------------------------------------------------------------
  // Precedence: AND binds tighter than OR
  // ---------------------------------------------------------------------------

  group('precedence', () {
    test('c:W t:creature OR t:instant — AND binds tighter', () {
      final result = parseQuery('c:W t:creature OR t:instant');
      expect(result.isSuccess, isTrue);
      // Should parse as: OR(AND(c:W, t:creature), t:instant)
      expect(
        result.ast,
        equals(const OrNode(
          AndNode([
            FilterNode('c', FilterOp.eq, 'W'),
            FilterNode('t', FilterOp.eq, 'creature'),
          ]),
          FilterNode('t', FilterOp.eq, 'instant'),
        )),
      );
    });

    test('t:instant OR c:W t:creature — right side groups as AND', () {
      final result = parseQuery('t:instant OR c:W t:creature');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const OrNode(
          FilterNode('t', FilterOp.eq, 'instant'),
          AndNode([
            FilterNode('c', FilterOp.eq, 'W'),
            FilterNode('t', FilterOp.eq, 'creature'),
          ]),
        )),
      );
    });

    test('chained OR: a OR b OR c is left-associative', () {
      final result = parseQuery('c:W OR c:U OR c:B');
      expect(result.isSuccess, isTrue);
      // Should be: OR(OR(c:W, c:U), c:B)
      expect(
        result.ast,
        equals(const OrNode(
          OrNode(
            FilterNode('c', FilterOp.eq, 'W'),
            FilterNode('c', FilterOp.eq, 'U'),
          ),
          FilterNode('c', FilterOp.eq, 'B'),
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Field aliases
  // ---------------------------------------------------------------------------

  group('field aliases', () {
    test('color: maps to c', () {
      final result = parseQuery('color:WU');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('c', FilterOp.eq, 'WU')));
    });

    test('identity: maps to id', () {
      final result = parseQuery('identity:WU');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('id', FilterOp.eq, 'WU')));
    });

    test('id: maps to id', () {
      final result = parseQuery('id:WU');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('id', FilterOp.eq, 'WU')));
    });

    test('set: maps to s', () {
      final result = parseQuery('set:mh2');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('s', FilterOp.eq, 'mh2')));
    });

    test('e: maps to s', () {
      final result = parseQuery('e:mh2');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('s', FilterOp.eq, 'mh2')));
    });

    test('type: maps to t', () {
      final result = parseQuery('type:creature');
      expect(result.isSuccess, isTrue);
      expect(
          result.ast, equals(const FilterNode('t', FilterOp.eq, 'creature')));
    });

    test('oracle: maps to o', () {
      final result = parseQuery('oracle:"draw a card"');
      expect(result.isSuccess, isTrue);
      expect(result.ast,
          equals(const FilterNode('o', FilterOp.eq, 'draw a card')));
    });

    test('rarity: maps to r', () {
      final result = parseQuery('rarity:rare');
      expect(result.isSuccess, isTrue);
      expect(result.ast, equals(const FilterNode('r', FilterOp.eq, 'rare')));
    });
  });

  // ---------------------------------------------------------------------------
  // Empty and error cases
  // ---------------------------------------------------------------------------

  group('empty and error cases', () {
    test('empty input returns null AST, no error', () {
      final result = parseQuery('');
      expect(result.isSuccess, isTrue);
      expect(result.ast, isNull);
    });

    test('whitespace-only input returns null AST, no error', () {
      final result = parseQuery('   ');
      expect(result.isSuccess, isTrue);
      expect(result.ast, isNull);
    });

    test('unknown filter prefix produces TextNode (not filter)', () {
      // "x" is not a known field, so "x:foo" doesn't parse as a filter.
      // Instead "x" is a bare word. Then ":foo" is unexpected.
      final result = parseQuery('x:foo');
      // "x" is not recognized as a filter field, so it's treated as text.
      // The parser sees "x" as a word, then ":foo" starts with ":" which is
      // not a word char, so it stops. Then ":foo" is unexpected.
      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
      expect(result.errorPosition, isNotNull);
    });

    test('unterminated quote produces error', () {
      final result = parseQuery('"hello');
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Unterminated'));
    });
  });

  // ---------------------------------------------------------------------------
  // Quoted filter values
  // ---------------------------------------------------------------------------

  group('quoted filter values', () {
    test('t:"legendary creature" parses correctly', () {
      final result = parseQuery('t:"legendary creature"');
      expect(result.isSuccess, isTrue);
      expect(result.ast,
          equals(const FilterNode('t', FilterOp.eq, 'legendary creature')));
    });

    test('o:"draw a card" in a larger query', () {
      final result = parseQuery('c:U o:"draw a card"');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          FilterNode('c', FilterOp.eq, 'U'),
          FilterNode('o', FilterOp.eq, 'draw a card'),
        ])),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: toString() -> parse -> equivalent AST
  // ---------------------------------------------------------------------------

  group('round-trip', () {
    test('TextNode round-trips', () {
      const node = TextNode('lightning');
      final reparsed = parseQuery(node.toString());
      expect(reparsed.ast, equals(node));
    });

    test('FilterNode round-trips', () {
      const node = FilterNode('c', FilterOp.eq, 'WU');
      final reparsed = parseQuery(node.toString());
      expect(reparsed.ast, equals(node));
    });

    test('FilterNode with quoted value round-trips', () {
      const node = FilterNode('t', FilterOp.eq, 'legendary creature');
      final reparsed = parseQuery(node.toString());
      expect(reparsed.ast, equals(node));
    });

    test('AndNode round-trips', () {
      const node = AndNode([
        FilterNode('c', FilterOp.eq, 'W'),
        FilterNode('t', FilterOp.eq, 'creature'),
      ]);
      final reparsed = parseQuery(node.toString());
      expect(reparsed.ast, equals(node));
    });

    test('OrNode round-trips', () {
      const node = OrNode(
        FilterNode('c', FilterOp.eq, 'W'),
        FilterNode('c', FilterOp.eq, 'U'),
      );
      final reparsed = parseQuery(node.toString());
      expect(reparsed.ast, equals(node));
    });

    test('NotNode round-trips', () {
      const node = NotNode(FilterNode('c', FilterOp.eq, 'B'));
      final reparsed = parseQuery(node.toString());
      expect(reparsed.ast, equals(node));
    });

    test('comparison operators round-trip', () {
      const node = FilterNode('usd', FilterOp.gt, '5');
      final str = node.toString();
      expect(str, equals('usd>5'));
      final reparsed = parseQuery(str);
      expect(reparsed.ast, equals(node));
    });

    test('gte round-trip', () {
      const node = FilterNode('usd', FilterOp.gte, '10');
      final str = node.toString();
      expect(str, equals('usd>=10'));
      final reparsed = parseQuery(str);
      expect(reparsed.ast, equals(node));
    });

    test('lt round-trip', () {
      const node = FilterNode('usd', FilterOp.lt, '1');
      final str = node.toString();
      expect(str, equals('usd<1'));
      final reparsed = parseQuery(str);
      expect(reparsed.ast, equals(node));
    });

    test('lte round-trip', () {
      const node = FilterNode('usd', FilterOp.lte, '20');
      final str = node.toString();
      expect(str, equals('usd<=20'));
      final reparsed = parseQuery(str);
      expect(reparsed.ast, equals(node));
    });
  });

  // ---------------------------------------------------------------------------
  // Complex queries
  // ---------------------------------------------------------------------------

  group('complex queries', () {
    test('c:W t:creature usd>1 parses correctly', () {
      final result = parseQuery('c:W t:creature usd>1');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          FilterNode('c', FilterOp.eq, 'W'),
          FilterNode('t', FilterOp.eq, 'creature'),
          FilterNode('usd', FilterOp.gt, '1'),
        ])),
      );
    });

    test('negation with AND', () {
      final result = parseQuery('c:W -c:B t:creature');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          FilterNode('c', FilterOp.eq, 'W'),
          NotNode(FilterNode('c', FilterOp.eq, 'B')),
          FilterNode('t', FilterOp.eq, 'creature'),
        ])),
      );
    });

    test('text and filters mixed with OR', () {
      final result = parseQuery('dragon OR c:R t:creature');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const OrNode(
          TextNode('dragon'),
          AndNode([
            FilterNode('c', FilterOp.eq, 'R'),
            FilterNode('t', FilterOp.eq, 'creature'),
          ]),
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Parenthesized groups
  // ---------------------------------------------------------------------------

  group('parenthesized groups', () {
    test('(t:instant OR t:sorcery) parses as OrNode', () {
      final result = parseQuery('(t:instant OR t:sorcery)');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const OrNode(
          FilterNode('t', FilterOp.eq, 'instant'),
          FilterNode('t', FilterOp.eq, 'sorcery'),
        )),
      );
    });

    test('c:R (t:instant OR t:sorcery) parses grouped OR with AND', () {
      final result = parseQuery('c:R (t:instant OR t:sorcery)');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          FilterNode('c', FilterOp.eq, 'R'),
          OrNode(
            FilterNode('t', FilterOp.eq, 'instant'),
            FilterNode('t', FilterOp.eq, 'sorcery'),
          ),
        ])),
      );
    });

    test('negated group -(t:land) parses as NotNode', () {
      final result = parseQuery('-(t:land)');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const NotNode(FilterNode('t', FilterOp.eq, 'land'))),
      );
    });

    test('nested groups ((c:R OR c:U)) parse correctly', () {
      final result = parseQuery('((c:R OR c:U))');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const OrNode(
          FilterNode('c', FilterOp.eq, 'R'),
          FilterNode('c', FilterOp.eq, 'U'),
        )),
      );
    });

    test('unclosed parenthesis produces error', () {
      final result = parseQuery('(t:instant OR t:sorcery');
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('parenthesis'));
    });
  });

  // ---------------------------------------------------------------------------
  // Phase 3 placeholder fields
  // ---------------------------------------------------------------------------

  group('placeholder fields', () {
    test('unused:true parses as filter', () {
      final result = parseQuery('unused:true');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const FilterNode('unused', FilterOp.eq, 'true')),
      );
    });

    test('idle:true aliases to unused', () {
      final result = parseQuery('idle:true');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const FilterNode('unused', FilterOp.eq, 'true')),
      );
    });

    test('have:4 parses as filter', () {
      final result = parseQuery('have:4');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const FilterNode('have', FilterOp.eq, '4')),
      );
    });

    test('unused:true combined with other filters', () {
      final result = parseQuery('c:R unused:true usd>5');
      expect(result.isSuccess, isTrue);
      expect(
        result.ast,
        equals(const AndNode([
          FilterNode('c', FilterOp.eq, 'R'),
          FilterNode('unused', FilterOp.eq, 'true'),
          FilterNode('usd', FilterOp.gt, '5'),
        ])),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/models/card_identity.dart';

void main() {
  group('Finish', () {
    group('tryParse', () {
      test('parses "nonfoil" to Finish.nonfoil', () {
        expect(Finish.tryParse('nonfoil'), Finish.nonfoil);
      });

      test('parses "foil" to Finish.foil', () {
        expect(Finish.tryParse('foil'), Finish.foil);
      });

      test('parses "etched" to Finish.etched', () {
        expect(Finish.tryParse('etched'), Finish.etched);
      });

      test('returns null for unrecognised value', () {
        expect(Finish.tryParse('unknown'), isNull);
      });

      test('returns null for empty string', () {
        expect(Finish.tryParse(''), isNull);
      });

      test('returns null for uppercase variant (case-sensitive)', () {
        expect(Finish.tryParse('Foil'), isNull);
      });
    });
  });

  group('CardIdentity', () {
    const id1 = 'abc-123';
    const id2 = 'def-456';

    group('equality', () {
      test('two objects with same scryfallId and finish are equal', () {
        const a = CardIdentity(id1, Finish.foil);
        const b = CardIdentity(id1, Finish.foil);
        expect(a, equals(b));
      });

      test('different scryfallId produces inequality', () {
        const a = CardIdentity(id1, Finish.foil);
        const b = CardIdentity(id2, Finish.foil);
        expect(a, isNot(equals(b)));
      });

      test('same scryfallId but different finish produces inequality (D2 rule)',
          () {
        const a = CardIdentity(id1, Finish.nonfoil);
        const b = CardIdentity(id1, Finish.foil);
        expect(a, isNot(equals(b)));
      });

      test('different scryfallId and different finish produces inequality', () {
        const a = CardIdentity(id1, Finish.nonfoil);
        const b = CardIdentity(id2, Finish.etched);
        expect(a, isNot(equals(b)));
      });

      test('not equal to a non-CardIdentity object', () {
        const a = CardIdentity(id1, Finish.foil);
        expect(a, isNot(equals('not a CardIdentity')));
      });
    });

    group('hashCode', () {
      test('equal objects produce the same hashCode', () {
        const a = CardIdentity(id1, Finish.foil);
        const b = CardIdentity(id1, Finish.foil);
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different objects are likely to produce different hashCodes', () {
        const a = CardIdentity(id1, Finish.foil);
        const b = CardIdentity(id1, Finish.nonfoil);
        // Not strictly required by contract but extremely likely for distinct
        // inputs, and validates the hash function distinguishes finishes.
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('toString', () {
      test('includes scryfallId and finish name', () {
        const card = CardIdentity(id1, Finish.etched);
        final str = card.toString();
        expect(str, contains(id1));
        expect(str, contains('etched'));
      });

      test('format matches CardIdentity(<id>, <finish>)', () {
        const card = CardIdentity(id1, Finish.foil);
        expect(card.toString(), 'CardIdentity($id1, foil)');
      });
    });

    group('can be used as Map key / Set element', () {
      test('works correctly as a Set element', () {
        const a = CardIdentity(id1, Finish.foil);
        const b = CardIdentity(id1, Finish.foil);
        const c = CardIdentity(id1, Finish.nonfoil);
        final set = {a, b, c};
        // a and b collapse; c is distinct.
        expect(set.length, 2);
      });
    });
  });
}

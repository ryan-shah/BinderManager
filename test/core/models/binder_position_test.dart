import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/models/binder_position.dart';

void main() {
  group('BinderPosition', () {
    test('orders by D9 fill order: page, then front-before-back, then pocket',
        () {
      const positions = [
        BinderPosition(page: 2, side: PageSide.front, pocket: 1),
        BinderPosition(page: 1, side: PageSide.back, pocket: 9),
        BinderPosition(page: 1, side: PageSide.front, pocket: 2),
        BinderPosition(page: 1, side: PageSide.back, pocket: 1),
        BinderPosition(page: 1, side: PageSide.front, pocket: 1),
      ];

      final sorted = [...positions]..sort();

      expect(sorted, const [
        BinderPosition(page: 1, side: PageSide.front, pocket: 1),
        BinderPosition(page: 1, side: PageSide.front, pocket: 2),
        BinderPosition(page: 1, side: PageSide.back, pocket: 1),
        BinderPosition(page: 1, side: PageSide.back, pocket: 9),
        BinderPosition(page: 2, side: PageSide.front, pocket: 1),
      ]);
    });

    test('describe emits the D7 instruction fragment', () {
      const position = BinderPosition(page: 3, side: PageSide.back, pocket: 5);
      expect(position.describe(), 'page 3, back, pocket 5');
    });

    test('value equality', () {
      const a = BinderPosition(page: 1, side: PageSide.front, pocket: 1);
      const b = BinderPosition(page: 1, side: PageSide.front, pocket: 1);
      const c = BinderPosition(page: 1, side: PageSide.back, pocket: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('BinderGeometry', () {
    const doubleSided3x3 = BinderGeometry(
      rows: 3,
      cols: 3,
      pageCount: 2,
      doubleSided: true,
    );
    const singleSided2x2 = BinderGeometry(
      rows: 2,
      cols: 2,
      pageCount: 3,
      doubleSided: false,
    );

    test('capacity = pockets/side × sides × pages', () {
      expect(doubleSided3x3.capacity, 3 * 3 * 2 * 2); // 36
      expect(singleSided2x2.capacity, 2 * 2 * 1 * 3); // 12
    });

    test('positionAt walks fill order: front side fills before back', () {
      expect(
        doubleSided3x3.positionAt(0),
        const BinderPosition(page: 1, side: PageSide.front, pocket: 1),
      );
      expect(
        doubleSided3x3.positionAt(8),
        const BinderPosition(page: 1, side: PageSide.front, pocket: 9),
      );
      expect(
        doubleSided3x3.positionAt(9),
        const BinderPosition(page: 1, side: PageSide.back, pocket: 1),
      );
      expect(
        doubleSided3x3.positionAt(18),
        const BinderPosition(page: 2, side: PageSide.front, pocket: 1),
      );
      expect(
        doubleSided3x3.positionAt(35),
        const BinderPosition(page: 2, side: PageSide.back, pocket: 9),
      );
    });

    test('positionAt on single-sided binders never yields a back side', () {
      for (var i = 0; i < singleSided2x2.capacity; i++) {
        expect(singleSided2x2.positionAt(i).side, PageSide.front);
      }
      expect(
        singleSided2x2.positionAt(4),
        const BinderPosition(page: 2, side: PageSide.front, pocket: 1),
      );
    });

    test('positionAt throws outside 0..capacity-1', () {
      expect(() => doubleSided3x3.positionAt(-1), throwsRangeError);
      expect(() => doubleSided3x3.positionAt(36), throwsRangeError);
    });

    test('ordinalOf inverts positionAt across the whole binder', () {
      for (var i = 0; i < doubleSided3x3.capacity; i++) {
        expect(doubleSided3x3.ordinalOf(doubleSided3x3.positionAt(i)), i);
      }
      for (var i = 0; i < singleSided2x2.capacity; i++) {
        expect(singleSided2x2.ordinalOf(singleSided2x2.positionAt(i)), i);
      }
    });

    test('ordinalOf rejects positions outside the geometry', () {
      expect(
        () => doubleSided3x3.ordinalOf(
          const BinderPosition(page: 3, side: PageSide.front, pocket: 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => doubleSided3x3.ordinalOf(
          const BinderPosition(page: 1, side: PageSide.front, pocket: 10),
        ),
        throwsArgumentError,
      );
      expect(
        () => singleSided2x2.ordinalOf(
          const BinderPosition(page: 1, side: PageSide.back, pocket: 1),
        ),
        throwsArgumentError,
      );
    });

    test('contains matches the geometry bounds', () {
      expect(
        doubleSided3x3.contains(
          const BinderPosition(page: 2, side: PageSide.back, pocket: 9),
        ),
        isTrue,
      );
      expect(
        singleSided2x2.contains(
          const BinderPosition(page: 1, side: PageSide.back, pocket: 1),
        ),
        isFalse,
      );
    });

    test('positions compare consistently with ordinals', () {
      // The BinderPosition comparator and the geometry ordinal must agree,
      // or append-within-group and "next open pocket" would diverge.
      final all = [
        for (var i = 0; i < doubleSided3x3.capacity; i++)
          doubleSided3x3.positionAt(i),
      ];
      final shuffled = [...all]..shuffle();
      shuffled.sort();
      expect(shuffled, all);
    });
  });
}

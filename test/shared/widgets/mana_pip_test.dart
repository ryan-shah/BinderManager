import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/shared/widgets/mana_pip.dart';
import 'package:binder_manager/app/theme.dart';

void main() {
  Widget buildPip({
    required String color,
    ManaPipSize size = ManaPipSize.filter,
    ManaPipState state = ManaPipState.unselected,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ManaPip(
            color: color,
            size: size,
            state: state,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('ManaPip - correct letter rendering', () {
    for (final letter in ['W', 'U', 'B', 'R', 'G', 'C', 'M']) {
      testWidgets('renders letter "$letter"', (tester) async {
        await tester.pumpWidget(buildPip(color: letter));
        expect(find.text(letter), findsOneWidget);
      });
    }
  });

  group('ManaPip - selected state', () {
    testWidgets('selected state has neutral900 border', (tester) async {
      await tester.pumpWidget(buildPip(
        color: 'W',
        state: ManaPipState.selected,
      ));

      final container = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final deco = w.decoration as BoxDecoration;
          if (deco.shape == BoxShape.circle && deco.border is Border) {
            final border = deco.border as Border;
            return border.top.color == AppColors.neutral900 &&
                border.top.width == 2;
          }
        }
        return false;
      });
      expect(container, findsOneWidget);
    });
  });

  group('ManaPip - unselected state', () {
    testWidgets('unselected state has per-color border', (tester) async {
      await tester.pumpWidget(buildPip(
        color: 'U',
        state: ManaPipState.unselected,
      ));

      final container = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final deco = w.decoration as BoxDecoration;
          if (deco.shape == BoxShape.circle && deco.border is Border) {
            final border = deco.border as Border;
            // Blue pip border color
            return border.top.color == ManaPips.u.border &&
                border.top.width == 1;
          }
        }
        return false;
      });
      expect(container, findsOneWidget);
    });
  });

  group('ManaPip - deselected state', () {
    testWidgets('deselected state uses dashed border (CustomPaint)',
        (tester) async {
      await tester.pumpWidget(buildPip(
        color: 'R',
        state: ManaPipState.deselected,
      ));

      // Deselected uses CustomPaint for the dashed border.
      expect(find.byType(CustomPaint), findsWidgets);

      // The container should NOT have a BoxDecoration border
      // (it's handled by the painter).
      final containerWithBorder = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final deco = w.decoration as BoxDecoration;
          return deco.shape == BoxShape.circle && deco.border != null;
        }
        return false;
      });
      expect(containerWithBorder, findsNothing);
    });
  });

  group('ManaPip - tap callback', () {
    testWidgets('tapping fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildPip(
        color: 'G',
        onTap: () => tapped = true,
      ));

      await tester.tap(find.text('G'));
      expect(tapped, isTrue);
    });
  });

  group('ManaPip - sizes render without overflow', () {
    for (final size in ManaPipSize.values) {
      testWidgets('${size.name} size renders', (tester) async {
        await tester.pumpWidget(buildPip(
          color: 'W',
          size: size,
        ));
        expect(tester.takeException(), isNull);
        expect(find.text('W'), findsOneWidget);
      });
    }
  });
}

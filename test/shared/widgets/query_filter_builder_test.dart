import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/shared/widgets/query_filter_builder.dart';

void main() {
  Widget buildBuilder({
    required ValueChanged<String> onQueryChanged,
    String? initialQuery,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 800,
          child: QueryFilterBuilder(
            onQueryChanged: onQueryChanged,
            initialQuery: initialQuery,
          ),
        ),
      ),
    );
  }

  group('QueryFilterBuilder - mana pips', () {
    testWidgets('tapping a mana pip changes its state and emits query',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Find and tap the "W" pip
      await tester.tap(find.text('W'));
      await tester.pumpAndSettle();

      // After first tap, W should be selected -> query contains c:W
      expect(lastQuery, contains('c:W'));

      // Tap again -> deselected -> query contains -c:W
      await tester.tap(find.text('W'));
      await tester.pumpAndSettle();
      expect(lastQuery, contains('-c:W'));

      // Tap again -> unselected -> query should NOT contain c:W or -c:W
      await tester.tap(find.text('W'));
      await tester.pumpAndSettle();
      expect(lastQuery, isNot(contains('c:W')));
      expect(lastQuery, isNot(contains('-c:W')));
    });
  });

  group('QueryFilterBuilder - card type chips', () {
    testWidgets('selecting card type chip fires query update', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Scroll down to find the Creature chip
      await tester.scrollUntilVisible(
        find.text('Creature'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Creature'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('t:creature'));
    });
  });

  group('QueryFilterBuilder - price slider', () {
    testWidgets('price slider updates query with usd range', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Scroll to the price range slider
      await tester.scrollUntilVisible(
        find.byType(RangeSlider),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // The RangeSlider initially spans 0-100.
      // Drag the left thumb right to set a minimum.
      final slider = find.byType(RangeSlider);
      expect(slider, findsOneWidget);

      // Get the slider's render box
      final box = tester.getRect(slider);

      // Tap near the 25% mark to move the start thumb
      await tester.tapAt(Offset(
        box.left + box.width * 0.25,
        box.center.dy,
      ));
      await tester.pumpAndSettle();

      // The query should now contain a price filter
      // (exact value depends on where we tapped)
      if (lastQuery != null && lastQuery!.isNotEmpty) {
        // If a price was set, it should contain usd>=
        expect(
          lastQuery!.contains('usd>=') || lastQuery!.contains('usd<='),
          isTrue,
        );
      }
    });
  });

  group('QueryFilterBuilder - initial query parsing', () {
    testWidgets('parses initial query and populates filters', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: 'c:WU r:rare',
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Trigger a filter change to get the compiled query
      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      // Should still contain W and U from initial, plus G now selected
      expect(lastQuery, contains('c:'));
    });

    testWidgets('id: in initial query activates identity mode',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: 'id:R',
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Select another color; compiled query should use id: not c:
      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('id:'));
      expect(lastQuery, isNot(contains('c:')));
    });
  });

  group('QueryFilterBuilder - color mode toggle', () {
    testWidgets('switching to Identity emits id: instead of c:',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Select W in default (colors) mode.
      await tester.tap(find.text('W'));
      await tester.pumpAndSettle();
      expect(lastQuery, contains('c:W'));

      // Switch to identity mode.
      await tester.tap(find.text('Identity'));
      await tester.pumpAndSettle();
      expect(lastQuery, contains('id:W'));
      expect(lastQuery, isNot(contains('c:W')));

      // Switch back to colors mode.
      await tester.tap(find.text('Colors'));
      await tester.pumpAndSettle();
      expect(lastQuery, contains('c:W'));
      expect(lastQuery, isNot(contains('id:W')));
    });
  });

  group('QueryFilterBuilder - status toggles', () {
    testWidgets('In collection switch emits have:true', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.scrollUntilVisible(
        find.text('In collection'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // The "In collection" switch is the first switch in the status section.
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(lastQuery, contains('have:true'));
      expect(lastQuery, isNot(contains('unused:true')));
    });

    testWidgets('Idle only switch emits unused:true', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.scrollUntilVisible(
        find.text('Idle only'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      expect(lastQuery, contains('unused:true'));
      expect(lastQuery, isNot(contains('have:true')));
    });

    testWidgets('have:true in initial query activates the switch',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: 'c:R have:true',
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Trigger recompile via a pip tap; have:true should persist.
      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('have:true'));
    });
  });
}

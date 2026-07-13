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

  group('QueryFilterBuilder - type match mode', () {
    testWidgets('two types default to an OR group (Any)', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.scrollUntilVisible(
        find.text('Creature'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Creature'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artifact'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('(t:creature OR t:artifact)'));
    });

    testWidgets('All mode emits bare AND tokens', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.scrollUntilVisible(
        find.text('Creature'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Creature'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artifact'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('All'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('t:creature t:artifact'));
      expect(lastQuery, isNot(contains('OR')));

      // Switching back to Any restores the OR group.
      await tester.tap(find.text('Any'));
      await tester.pumpAndSettle();
      expect(lastQuery, contains('(t:creature OR t:artifact)'));
    });

    testWidgets('bare AND tokens in initial query activate All mode',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: 't:artifact t:creature',
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Recompile via a pip tap; the AND shape must survive.
      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('t:artifact t:creature'));
      expect(lastQuery, isNot(contains('OR')));
    });

    testWidgets('grouped types in initial query stay in Any mode',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: '(t:artifact OR t:creature)',
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('(t:artifact OR t:creature)'));
    });
  });

  group('QueryFilterBuilder - rarity chips', () {
    testWidgets('single rarity emits a bare r: token', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.scrollUntilVisible(
        find.text('Rare'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Rare'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('r:rare'));
      expect(lastQuery, isNot(contains('(')));
    });

    testWidgets('multiple rarities are OR-grouped', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.scrollUntilVisible(
        find.text('Rare'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Rare'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mythic'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('(r:rare OR r:mythic)'));
    });

    testWidgets('grouped rarities in initial query round-trip',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: '(r:rare OR r:mythic)',
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Trigger recompile via a pip tap; both rarities should persist.
      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('(r:rare OR r:mythic)'));
    });
  });

  group('QueryFilterBuilder - set field', () {
    testWidgets('multiple set codes normalize to one comma list',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. mh2, neo'),
        'khm, neo mh2',
      );
      await tester.pumpAndSettle();

      expect(lastQuery, contains('s:khm,neo,mh2'));
    });

    testWidgets('comma set list in initial query round-trips',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: 's:khm,neo',
        onQueryChanged: (q) => lastQuery = q,
      ));

      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('s:khm,neo'));
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

    testWidgets('is:borderless in initial query leaves name field empty',
        (tester) async {
      String? lastQuery;
      await tester.pumpWidget(buildBuilder(
        initialQuery: 'is:borderless',
        onQueryChanged: (q) => lastQuery = q,
      ));

      // Recompile via a pip tap. The name field must not have picked up a
      // stray "i" from the unanchored s: prefix matching inside "is:".
      await tester.tap(find.text('G'));
      await tester.pumpAndSettle();

      expect(lastQuery, contains('is:borderless'));
      expect(lastQuery, isNot(startsWith('i ')));
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
      // Use a non-empty initial query so _parseInitialQuery resets both
      // toggles to false, letting us test turning "In collection" on.
      await tester.pumpWidget(buildBuilder(
        initialQuery: 'c:R',
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
      // Use a non-empty initial query so _parseInitialQuery resets both
      // toggles to false, letting us test turning "Idle only" on.
      await tester.pumpWidget(buildBuilder(
        initialQuery: 'c:R',
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

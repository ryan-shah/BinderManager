import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/shared/widgets/applied_filter_chips.dart';

void main() {
  Widget buildChips({
    required String query,
    required ValueChanged<String> onChipRemoved,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        body: AppliedFilterChips(
          query: query,
          onChipRemoved: onChipRemoved,
        ),
      ),
    );
  }

  group('AppliedFilterChips - tokenize', () {
    test('grouped rarities stay one token', () {
      final tokens =
          AppliedFilterChips.tokenize('(r:rare OR r:mythic) s:khm,neo');
      expect(tokens, ['(r:rare OR r:mythic)', 's:khm,neo']);
    });
  });

  group('AppliedFilterChips - labels', () {
    testWidgets('grouped types label as Type list', (tester) async {
      await tester.pumpWidget(buildChips(
        query: '(t:instant OR t:sorcery)',
        onChipRemoved: (_) {},
      ));

      expect(find.text('Type: Instant, Sorcery'), findsOneWidget);
    });

    testWidgets('grouped rarities label as Rarity list', (tester) async {
      await tester.pumpWidget(buildChips(
        query: '(r:rare OR r:mythic)',
        onChipRemoved: (_) {},
      ));

      expect(find.text('Rarity: Rare, Mythic'), findsOneWidget);
    });

    testWidgets('empty-value tokens render without crashing', (tester) async {
      // Chips render the raw query before parse validation, so a submitted
      // bare prefix must not throw (was a RangeError on value[0]).
      await tester.pumpWidget(buildChips(
        query: 't: r: is:',
        onChipRemoved: (_) {},
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Type: '), findsOneWidget);
      expect(find.text('Rarity: '), findsOneWidget);
      expect(find.text('is:'), findsOneWidget);
    });

    testWidgets('comma set list labels with spaced codes', (tester) async {
      await tester.pumpWidget(buildChips(
        query: 's:khm,neo',
        onChipRemoved: (_) {},
      ));

      expect(find.text('Set: KHM, NEO'), findsOneWidget);
    });
  });

  group('AppliedFilterChips - removal', () {
    testWidgets('removing a grouped rarity chip drops the whole group',
        (tester) async {
      String? updated;
      await tester.pumpWidget(buildChips(
        query: '(r:rare OR r:mythic) s:khm,neo',
        onChipRemoved: (q) => updated = q,
      ));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(updated, 's:khm,neo');
    });
  });
}

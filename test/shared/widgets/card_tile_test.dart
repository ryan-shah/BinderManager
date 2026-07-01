import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/shared/widgets/card_tile.dart';
import 'package:binder_manager/app/theme.dart';

void main() {
  Widget buildTile({
    String name = 'Lightning Bolt',
    String? imageUri,
    String? typeLine,
    String? setCode,
    String? rarity,
    double? priceUsd,
    String? finishes,
    int? quantity,
    VoidCallback? onTap,
    bool compact = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: compact ? 180 : 600,
          height: compact ? 280 : 80,
          child: CardTile(
            name: name,
            imageUri: imageUri,
            typeLine: typeLine,
            setCode: setCode,
            rarity: rarity,
            priceUsd: priceUsd,
            finishes: finishes,
            quantity: quantity,
            onTap: onTap,
            compact: compact,
          ),
        ),
      ),
    );
  }

  group('CardTile - compact variant', () {
    testWidgets('renders name', (tester) async {
      await tester.pumpWidget(buildTile(name: 'Counterspell'));
      expect(find.text('Counterspell'), findsOneWidget);
    });

    testWidgets('renders price', (tester) async {
      await tester.pumpWidget(buildTile(priceUsd: 12.50));
      expect(find.text('\$12.50'), findsOneWidget);
    });

    testWidgets('renders name and price together', (tester) async {
      await tester.pumpWidget(buildTile(
        name: 'Sol Ring',
        priceUsd: 1.99,
      ));
      expect(find.text('Sol Ring'), findsOneWidget);
      expect(find.text('\$1.99'), findsOneWidget);
    });
  });

  group('CardTile - row variant', () {
    testWidgets('renders name and type', (tester) async {
      await tester.pumpWidget(buildTile(
        name: 'Birds of Paradise',
        typeLine: 'Creature - Bird',
        compact: false,
      ));
      expect(find.text('Birds of Paradise'), findsOneWidget);
      expect(find.text('Creature - Bird'), findsOneWidget);
    });

    testWidgets('renders set code', (tester) async {
      await tester.pumpWidget(buildTile(
        name: 'Bolt',
        setCode: 'sta',
        compact: false,
      ));
      expect(find.text('STA'), findsOneWidget);
    });

    testWidgets('renders price', (tester) async {
      await tester.pumpWidget(buildTile(
        name: 'Bolt',
        priceUsd: 5.00,
        compact: false,
      ));
      expect(find.text('\$5.00'), findsOneWidget);
    });
  });

  group('CardTile - foil badge', () {
    testWidgets('shows FOIL badge when finishes is "foil"', (tester) async {
      await tester.pumpWidget(buildTile(
        finishes: 'foil',
        compact: true,
      ));
      expect(find.text('FOIL'), findsOneWidget);
    });

    testWidgets('shows ETCHED badge when finishes contains "etched"',
        (tester) async {
      await tester.pumpWidget(buildTile(
        finishes: 'etched',
        compact: true,
      ));
      expect(find.text('ETCHED'), findsOneWidget);
    });

    testWidgets('no badge when finishes is "nonfoil"', (tester) async {
      await tester.pumpWidget(buildTile(
        finishes: 'nonfoil',
        compact: true,
      ));
      expect(find.text('FOIL'), findsNothing);
      expect(find.text('ETCHED'), findsNothing);
    });

    testWidgets('no badge when finishes includes both nonfoil and foil',
        (tester) async {
      // When both are present, the card exists in both finishes,
      // so no badge (it's the default nonfoil+foil printing).
      await tester.pumpWidget(buildTile(
        finishes: 'nonfoil,foil',
        compact: true,
      ));
      expect(find.text('FOIL'), findsNothing);
    });

    testWidgets('shows FOIL in row variant', (tester) async {
      await tester.pumpWidget(buildTile(
        finishes: 'foil',
        compact: false,
      ));
      expect(find.text('FOIL'), findsOneWidget);
    });
  });

  group('CardTile - quantity badge', () {
    testWidgets('shows qty badge when quantity > 1', (tester) async {
      await tester.pumpWidget(buildTile(quantity: 4));
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('no qty badge when quantity is null', (tester) async {
      await tester.pumpWidget(buildTile(quantity: null));
      // Should not find any small circle with a number
      final badge = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final deco = w.decoration as BoxDecoration;
          return deco.shape == BoxShape.circle &&
              deco.color == AppColors.neutral900;
        }
        return false;
      });
      expect(badge, findsNothing);
    });

    testWidgets('no qty badge when quantity is 1', (tester) async {
      await tester.pumpWidget(buildTile(quantity: 1));
      final badge = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final deco = w.decoration as BoxDecoration;
          return deco.shape == BoxShape.circle &&
              deco.color == AppColors.neutral900;
        }
        return false;
      });
      expect(badge, findsNothing);
    });
  });

  group('CardTile - tap', () {
    testWidgets('onTap fires when compact card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTile(
        onTap: () => tapped = true,
        compact: true,
      ));

      await tester.tap(find.text('Lightning Bolt'));
      expect(tapped, isTrue);
    });

    testWidgets('onTap fires when row is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTile(
        onTap: () => tapped = true,
        compact: false,
      ));

      await tester.tap(find.text('Lightning Bolt'));
      expect(tapped, isTrue);
    });
  });
}

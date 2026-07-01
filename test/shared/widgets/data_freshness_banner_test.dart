import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/shared/widgets/data_freshness_banner.dart';

void main() {
  Widget buildBanner({DateTime? lastUpdated}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: DataFreshnessBanner(lastUpdated: lastUpdated),
        ),
      ),
    );
  }

  group('DataFreshnessBanner', () {
    testWidgets('renders nothing when lastUpdated is null', (tester) async {
      await tester.pumpWidget(buildBanner(lastUpdated: null));

      // The widget returns SizedBox.shrink, so no meaningful text is shown.
      expect(find.text('Data updated:'), findsNothing);
      expect(find.text('Data is stale (>7 days)'), findsNothing);
      expect(find.text('Refresh'), findsNothing);
    });

    testWidgets('shows date when data is recent (< 7 days old)',
        (tester) async {
      final recent = DateTime.now().subtract(const Duration(days: 2));
      await tester.pumpWidget(buildBanner(lastUpdated: recent));

      final expectedLabel =
          '${recent.year}-${recent.month.toString().padLeft(2, '0')}-${recent.day.toString().padLeft(2, '0')}';

      expect(
        find.text('Data updated: $expectedLabel'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      // No stale warning
      expect(find.text('Data is stale (>7 days)'), findsNothing);
      expect(find.text('Refresh'), findsNothing);
    });

    testWidgets('shows stale warning with amber styling when data > 7 days old',
        (tester) async {
      final stale = DateTime.now().subtract(const Duration(days: 10));
      await tester.pumpWidget(buildBanner(lastUpdated: stale));

      expect(find.text('Data is stale (>7 days)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // The stale banner should NOT show the "Data updated:" text
      expect(find.textContaining('Data updated:'), findsNothing);
    });

    testWidgets('refresh button is present when stale', (tester) async {
      final stale = DateTime.now().subtract(const Duration(days: 14));
      await tester.pumpWidget(buildBanner(lastUpdated: stale));

      final refreshFinder = find.text('Refresh');
      expect(refreshFinder, findsOneWidget);

      // Verify it is wrapped in a GestureDetector (tappable)
      final gestureDetector = find.ancestor(
        of: refreshFinder,
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetector, findsWidgets);
    });

    testWidgets('exactly 7 days old is not stale', (tester) async {
      // 7 days difference rounds to 7, and the check is > 7, so exactly
      // 7 days should NOT be stale.
      final boundary = DateTime.now().subtract(const Duration(days: 7));
      await tester.pumpWidget(buildBanner(lastUpdated: boundary));

      final expectedLabel =
          '${boundary.year}-${boundary.month.toString().padLeft(2, '0')}-${boundary.day.toString().padLeft(2, '0')}';

      expect(find.text('Data updated: $expectedLabel'), findsOneWidget);
      expect(find.text('Data is stale (>7 days)'), findsNothing);
    });

    testWidgets('8 days old is stale', (tester) async {
      final eightDays = DateTime.now().subtract(const Duration(days: 8));
      await tester.pumpWidget(buildBanner(lastUpdated: eightDays));

      expect(find.text('Data is stale (>7 days)'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });
  });
}

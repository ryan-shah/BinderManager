import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/features/collection_search/collection_search_screen.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';

void main() {
  late CorpusDatabase db;

  setUp(() {
    db = CorpusDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          corpusDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CollectionSearchScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CollectionSearchScreen - desktop layout', () {
    testWidgets('shows filter rail at wide viewport', (tester) async {
      await pumpScreen(tester, width: 1200);

      // The filter rail shows the "FILTERS" section label.
      expect(find.text('FILTERS'), findsOneWidget);
    });

    testWidgets('query bar is visible', (tester) async {
      await pumpScreen(tester, width: 1200);

      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Search cards...'), findsOneWidget);
    });
  });

  group('CollectionSearchScreen - mobile layout', () {
    testWidgets('shows filter FAB at narrow viewport', (tester) async {
      await pumpScreen(tester, width: 400);

      // Mobile layout should have a FloatingActionButton for filters.
      expect(find.byType(FloatingActionButton), findsOneWidget);
      // No inline filter rail
      expect(find.text('FILTERS'), findsNothing);
    });

    testWidgets('query bar is visible on mobile', (tester) async {
      await pumpScreen(tester, width: 400);

      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Search cards...'), findsOneWidget);
    });
  });

  group('CollectionSearchScreen - empty state', () {
    testWidgets('shows instructional text when query is empty', (tester) async {
      await pumpScreen(tester, width: 1200);

      expect(find.text('Search your collection'), findsOneWidget);
    });
  });

  group('CollectionSearchScreen - query bar interaction', () {
    testWidgets('typing in query bar updates text', (tester) async {
      await pumpScreen(tester, width: 1200);

      // Find the search TextField (in the main content area, not the filter)
      // The first TextField should be the search bar.
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Enter text in the search bar (the one with 'Search cards...' hint)
      final searchField = find.widgetWithText(TextField, 'Search cards...');
      await tester.enterText(searchField, 'Lightning');
      await tester.pumpAndSettle();

      expect(find.text('Lightning'), findsWidgets);
    });
  });
}

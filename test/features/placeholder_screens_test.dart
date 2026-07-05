import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/features/binder_editor/binder_editor_screen.dart';
import 'package:binder_manager/features/binders_list/binders_list_screen.dart';
import 'package:binder_manager/features/change_review/change_review_screen.dart';
import 'package:binder_manager/features/collection_search/collection_search_screen.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';

void main() {
  group('Placeholder screens', () {
    testWidgets('BindersListScreen shows "Binders"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BindersListScreen()),
      );
      expect(find.text('Binders'), findsOneWidget);
    });

    testWidgets('CollectionSearchScreen shows search UI', (tester) async {
      final db = CorpusDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

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

      // The collection search screen shows the search prompt.
      expect(find.text('Search your collection'), findsOneWidget);
    });

    // DecksListScreen is a real screen now — covered by
    // test/features/decks/decks_list_screen_test.dart.

    // SettingsScreen is a real screen now — covered by
    // test/features/settings/settings_screen_test.dart.

    testWidgets('BinderEditorScreen skeleton distinguishes new vs edit',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BinderEditorScreen()),
      );
      expect(find.text('New binder'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: BinderEditorScreen(binderId: 'binder-1')),
      );
      expect(find.text('Edit binder'), findsOneWidget);
    });

    testWidgets('ChangeReviewScreen shows "Review changes"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ChangeReviewScreen()),
      );
      expect(find.text('Review changes'), findsOneWidget);
    });
  });
}

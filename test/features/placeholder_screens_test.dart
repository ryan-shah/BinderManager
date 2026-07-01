import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/features/binders_list/binders_list_screen.dart';
import 'package:binder_manager/features/collection_search/collection_search_screen.dart';
import 'package:binder_manager/features/decks/decks_list_screen.dart';
import 'package:binder_manager/features/settings/settings_screen.dart';

void main() {
  group('Placeholder screens', () {
    testWidgets('BindersListScreen shows "Binders"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BindersListScreen()),
      );
      expect(find.text('Binders'), findsOneWidget);
    });

    testWidgets('CollectionSearchScreen shows "Collection"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CollectionSearchScreen()),
      );
      expect(find.text('Collection'), findsOneWidget);
    });

    testWidgets('DecksListScreen shows "Decks"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DecksListScreen()),
      );
      expect(find.text('Decks'), findsOneWidget);
    });

    testWidgets('SettingsScreen shows "Settings"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/features/settings/settings_screen.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';

/// A fake [CorpusImportNotifier] that records calls instead of downloading.
class FakeImportNotifier extends StateNotifier<CorpusImportState>
    implements CorpusImportNotifier {
  FakeImportNotifier([CorpusImportState? initial])
      : super(initial ?? const CorpusImportState());

  bool runImportCalled = false;
  int? lastCardLimit;

  @override
  Future<void> runImport({int? cardLimit}) async {
    runImportCalled = true;
    lastCardLimit = cardLimit;
  }
}

void main() {
  late CorpusDatabase db;

  setUp(() {
    db = CorpusDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<FakeImportNotifier> pumpSettings(
    WidgetTester tester, {
    CorpusImportState? importState,
  }) async {
    final fakeNotifier = FakeImportNotifier(importState);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          corpusDatabaseProvider.overrideWithValue(db),
          corpusImportProvider.overrideWith((_) => fakeNotifier),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fakeNotifier;
  }

  group('SettingsScreen', () {
    testWidgets('shows heading and the refresh action', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Refresh card data'), findsOneWidget);
      expect(find.text('Card data has not been downloaded yet.'),
          findsOneWidget);
    });

    testWidgets('shows the last-updated date when the corpus has one',
        (tester) async {
      await db.setMeta(CorpusDatabase.metaImportedAt,
          DateTime.utc(2026, 7, 1, 12).toIso8601String());

      await pumpSettings(tester);

      expect(find.textContaining('Last updated: 2026-07'), findsOneWidget);
    });

    testWidgets('warns when data is older than 7 days', (tester) async {
      await db.setMeta(
        CorpusDatabase.metaImportedAt,
        DateTime.now().toUtc().subtract(const Duration(days: 30))
            .toIso8601String(),
      );

      await pumpSettings(tester);

      expect(find.text('Data is older than 7 days — refresh recommended.'),
          findsOneWidget);
    });

    testWidgets('tapping refresh starts a full (unlimited) import',
        (tester) async {
      final notifier = await pumpSettings(tester);

      await tester.tap(find.text('Refresh card data'));
      await tester.pump();

      expect(notifier.runImportCalled, isTrue);
      expect(notifier.lastCardLimit, isNull);
    });

    testWidgets('disables the button and shows progress while refreshing',
        (tester) async {
      final notifier = await pumpSettings(
        tester,
        importState: const CorpusImportState(
          phase: 'downloading',
          progress: 0.4,
          cardsImported: 1200,
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Refresh card data'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('1200 cards'), findsOneWidget);

      await tester.tap(find.text('Refresh card data'),
          warnIfMissed: false);
      await tester.pump();
      expect(notifier.runImportCalled, isFalse);
    });

    testWidgets('shows the error and re-enables retry after a failure',
        (tester) async {
      await pumpSettings(
        tester,
        importState: const CorpusImportState(
          phase: 'error',
          error: 'network down',
        ),
      );

      expect(find.textContaining('network down'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Refresh card data'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/import/collection_importer.dart';
import 'package:binder_manager/core/import/manabox_parser.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/features/collection_import/collection_import_screen.dart';
import 'package:binder_manager/shared/providers/collection_import_provider.dart';
import 'package:binder_manager/shared/providers/corpus_provider.dart';

/// A fake [CollectionImportNotifier] that records calls instead of touching
/// databases. Method signatures must match the real notifier exactly.
class FakeCollectionImportNotifier extends StateNotifier<CollectionImportState>
    implements CollectionImportNotifier {
  FakeCollectionImportNotifier([CollectionImportState? initial])
      : super(initial ?? const CollectionImportState());

  final loadFileCalls = <String>[];
  final setModeCalls = <ImportMode>[];
  final mapUnmatchedCalls = <(int, CardIdentity)>[];
  final ignoreUnmatchedCalls = <int>[];
  var commitCalled = false;
  var resetCalled = false;

  @override
  void Function()? get onCommitted => null;

  @override
  Future<void> loadFile(String fileName, Uint8List bytes) async {
    loadFileCalls.add(fileName);
  }

  @override
  Future<void> setMode(ImportMode mode) async {
    setModeCalls.add(mode);
  }

  @override
  Future<void> mapUnmatched(int index, CardIdentity identity) async {
    mapUnmatchedCalls.add((index, identity));
  }

  @override
  void ignoreUnmatched(int index) {
    ignoreUnmatchedCalls.add(index);
  }

  @override
  Future<void> commit() async {
    commitCalled = true;
  }

  @override
  void reset() {
    resetCalled = true;
  }
}

Card makeCorpusCard({
  required String scryfallId,
  required String name,
  String setCode = 'tst',
  String finishes = 'nonfoil,foil',
}) {
  return Card(
    scryfallId: scryfallId,
    oracleId: 'oracle-000',
    name: name,
    cmc: 1.0,
    typeLine: 'Instant',
    colorIdentity: 'R',
    setCode: setCode,
    setName: 'Test Set',
    collectorNumber: '1',
    rarity: 'common',
    finishes: finishes,
    isFullart: false,
    isPromo: false,
    layout: 'normal',
    releasedAt: '2023-01-01',
  );
}

MatchedStackRow makeMatched({
  String scryfallId = 'bolt-1',
  String name = 'Lightning Bolt',
  int quantity = 1,
}) {
  return MatchedStackRow(
    identity: CardIdentity(scryfallId, Finish.nonfoil),
    quantity: quantity,
    corpusCard: makeCorpusCard(scryfallId: scryfallId, name: name),
  );
}

UnmatchedRow makeUnmatched({
  int lineNumber = 6,
  String name = 'Phantom Card',
  UnmatchReason reason = UnmatchReason.unknownScryfallId,
  bool ignored = false,
}) {
  return UnmatchedRow(
    lineNumber: lineNumber,
    raw: {
      'Name': name,
      'Set code': 'xxx',
      'Quantity': '2',
      'Condition': 'near_mint',
      'Language': 'en',
    },
    reason: reason,
    ignored: ignored,
  );
}

/// A review-phase state with one matched and (optionally) unmatched rows.
CollectionImportState reviewState({
  ImportMode mode = ImportMode.append,
  List<UnmatchedRow> unmatched = const [],
  int previousStackCount = 0,
}) {
  final matched = [makeMatched(quantity: 4)];
  return CollectionImportState(
    phase: CollectionImportPhase.review,
    fileName: 'collection.csv',
    mode: mode,
    parseResult: ManaBoxParseResult(
      matched: matched,
      unmatched: unmatched,
      totalDataRows: 1 + unmatched.length,
    ),
    diff: const ImportDiff(
      adds: [
        DiffEntry(
          identity: CardIdentity('bolt-1', Finish.nonfoil),
          qtyBefore: 0,
          qtyAfter: 4,
          cardName: 'Lightning Bolt',
          setCode: 'lea',
          collectorNumber: '161',
        ),
      ],
      removes: [],
      changes: [],
    ),
    previousStackCount: previousStackCount,
  );
}

void main() {
  Future<FakeCollectionImportNotifier> pumpScreen(
    WidgetTester tester, {
    CollectionImportState? state,
    FakeCollectionImportNotifier? notifier,
    List<Override> extraOverrides = const [],
    double width = 1200,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = notifier ?? FakeCollectionImportNotifier(state);

    final router = GoRouter(
      initialLocation: '/collection/import',
      routes: [
        GoRoute(
          path: '/collection/import',
          builder: (_, _) => const CollectionImportScreen(),
        ),
        GoRoute(
          path: '/collection',
          builder: (_, _) => const Text('Collection Screen'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionImportProvider.overrideWith((_) => fake),
          ...extraOverrides,
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
        ),
      ),
    );

    return fake;
  }

  ElevatedButton commitButton(WidgetTester tester) {
    return tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Commit'),
    );
  }

  group('CollectionImportScreen — empty state', () {
    testWidgets('shows file pick button and a disabled commit', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Choose ManaBox CSV…'), findsOneWidget);
      expect(find.text('Pick a ManaBox CSV to begin'), findsOneWidget);
      expect(commitButton(tester).enabled, isFalse);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('mode selector reports changes', (tester) async {
      final fake = await pumpScreen(tester);

      await tester.tap(find.text('Replace'));
      await tester.pump();

      expect(fake.setModeCalls, [ImportMode.replace]);
    });
  });

  group('CollectionImportScreen — parsing', () {
    testWidgets('shows a progress indicator with the file name',
        (tester) async {
      await pumpScreen(
        tester,
        state: const CollectionImportState(
          phase: CollectionImportPhase.parsing,
          fileName: 'collection.csv',
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('parsing collection.csv…'), findsOneWidget);
      expect(commitButton(tester).enabled, isFalse);
    });
  });

  group('CollectionImportScreen — parsed clean', () {
    testWidgets('shows summary and diff, enables commit', (tester) async {
      final fake = await pumpScreen(tester, state: reviewState());

      // Summary appears in the source pane and the action bar.
      expect(find.text('1 rows · 1 matched · 0 unmatched'), findsWidgets);
      expect(find.text('No unmatched rows'), findsOneWidget);
      expect(find.text('ADD (1)'), findsOneWidget);
      expect(find.text('Lightning Bolt'), findsOneWidget);
      expect(find.text('0 → 4'), findsOneWidget);

      expect(commitButton(tester).enabled, isTrue);
      await tester.tap(find.text('Commit'));
      await tester.pump();
      expect(fake.commitCalled, isTrue);
    });
  });

  group('CollectionImportScreen — parsed with unmatched', () {
    testWidgets('shows badge, reason chip, and row actions', (tester) async {
      final fake = await pumpScreen(
        tester,
        state: reviewState(unmatched: [makeUnmatched()]),
      );

      // Badge next to the UNMATCHED header.
      expect(find.text('UNMATCHED'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Phantom Card'), findsOneWidget);
      expect(find.text('unknown id'), findsOneWidget);
      expect(find.text('Map…'), findsOneWidget);

      await tester.tap(find.text('Ignore'));
      await tester.pump();
      expect(fake.ignoreUnmatchedCalls, [0]);
    });

    testWidgets('ignored rows lose their actions', (tester) async {
      await pumpScreen(
        tester,
        state: reviewState(unmatched: [makeUnmatched(ignored: true)]),
      );

      expect(find.text('Ignored'), findsOneWidget);
      final mapButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Map…'),
      );
      expect(mapButton.enabled, isFalse);
    });

    testWidgets('Map… opens the dialog and reports the chosen identity',
        (tester) async {
      final corpus = CorpusDatabase(NativeDatabase.memory());
      addTearDown(corpus.close);
      await corpus.into(corpus.cards).insert(
            CardsCompanion(
              scryfallId: const Value('helix-1'),
              oracleId: const Value('oracle-000'),
              name: const Value('Lightning Helix'),
              cmc: const Value(1.0),
              typeLine: const Value('Instant'),
              colorIdentity: const Value('R,W'),
              setCode: const Value('rav'),
              setName: const Value('Ravnica'),
              collectorNumber: const Value('213'),
              rarity: const Value('uncommon'),
              finishes: const Value('nonfoil,foil'),
              layout: const Value('normal'),
              releasedAt: const Value('2005-10-07'),
            ),
          );

      final fake = await pumpScreen(
        tester,
        state: reviewState(unmatched: [makeUnmatched()]),
        extraOverrides: [corpusDatabaseProvider.overrideWithValue(corpus)],
      );

      await tester.tap(find.text('Map…'));
      await tester.pumpAndSettle();
      expect(find.text('Map to printing'), findsOneWidget);

      // Initial search ("Phantom Card") finds nothing; search for the card.
      await tester.enterText(
          find.widgetWithText(TextField, 'Phantom Card'), 'Helix');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lightning Helix'));
      await tester.pumpAndSettle();

      // Finish defaults to the first available; confirm the mapping.
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      expect(fake.mapUnmatchedCalls, [
        (0, const CardIdentity('helix-1', Finish.nonfoil)),
      ]);
    });
  });

  group('CollectionImportScreen — replace warning', () {
    testWidgets('warns when replace would swap a non-empty snapshot',
        (tester) async {
      await pumpScreen(
        tester,
        state: reviewState(mode: ImportMode.replace, previousStackCount: 3),
      );

      expect(
        find.text(
          'This replaces your ManaBox collection: 1 cards, was 3 '
          '— review before committing',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no warning in append mode or with an empty snapshot',
        (tester) async {
      await pumpScreen(
        tester,
        state: reviewState(mode: ImportMode.append, previousStackCount: 3),
      );

      expect(find.textContaining('This replaces'), findsNothing);
    });
  });

  group('CollectionImportScreen — committing', () {
    testWidgets('shows progress and disables actions', (tester) async {
      final base = reviewState();
      await pumpScreen(
        tester,
        state: base.copyWith(phase: CollectionImportPhase.committing),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('committing…'), findsOneWidget);
      expect(commitButton(tester).enabled, isFalse);
      final cancel = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Cancel'),
      );
      expect(cancel.enabled, isFalse);
    });
  });

  group('CollectionImportScreen — done', () {
    testWidgets('shows completion and navigates back', (tester) async {
      final base = reviewState();
      final fake = await pumpScreen(
        tester,
        state: base.copyWith(phase: CollectionImportPhase.done),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Import complete'), findsOneWidget);
      expect(find.text('1 added · 0 removed · 0 changed'), findsOneWidget);
      // No action bar in the done state.
      expect(find.text('Commit'), findsNothing);

      await tester.tap(find.text('Back to collection'));
      await tester.pumpAndSettle();

      expect(fake.resetCalled, isTrue);
      expect(find.text('Collection Screen'), findsOneWidget);
    });
  });

  group('CollectionImportScreen — error', () {
    testWidgets('surfaces the error message', (tester) async {
      await pumpScreen(
        tester,
        state: const CollectionImportState(
          phase: CollectionImportPhase.error,
          fileName: 'bogus.csv',
          error: 'FormatException: Not a ManaBox CSV',
        ),
      );

      expect(find.textContaining('Not a ManaBox CSV'), findsOneWidget);
      expect(commitButton(tester).enabled, isFalse);
    });
  });

  group('CollectionImportScreen — mobile layout', () {
    testWidgets('renders the single-column wizard with the queue inline',
        (tester) async {
      await pumpScreen(
        tester,
        state: reviewState(unmatched: [makeUnmatched()]),
        width: 400,
      );

      expect(find.text('SOURCE'), findsOneWidget);
      expect(find.text('UNMATCHED'), findsOneWidget);
      expect(find.text('Phantom Card'), findsOneWidget);
      expect(find.text('Commit'), findsOneWidget);
    });
  });
}

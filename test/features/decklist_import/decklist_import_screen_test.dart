import 'dart:typed_data';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material
    show NoSplash, ThemeData, Dialog;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/import/decklist_parser.dart';
import 'package:binder_manager/features/decklist_import/decklist_import_screen.dart';
import 'package:binder_manager/shared/providers/deck_providers.dart';

/// A fake [DeckImportNotifier] that records calls; method signatures match
/// the real notifier exactly.
class FakeDeckImportNotifier extends StateNotifier<DeckImportState>
    implements DeckImportNotifier {
  FakeDeckImportNotifier([DeckImportState? initial])
      : super(initial ?? const DeckImportState());

  final parsedTexts = <String>[];
  final loadedFiles = <String>[];
  final metadataCalls = <Map<String, Object?>>[];
  final toggledLines = <int>[];
  final fidelityChoices = <FidelityMode>[];
  final pickedPrintings = <(int, Card)>[];
  final unownedChoices = <UnownedChoice>[];
  var commitCalls = 0;
  var resetCalls = 0;

  void emit(DeckImportState next) => state = next;

  @override
  Future<void> parseText(String text) async => parsedTexts.add(text);

  @override
  Future<void> loadFile(String name, Uint8List bytes) async =>
      loadedFiles.add(name);

  @override
  void setMetadata({
    String? name,
    String? format,
    bool? assembled,
    bool? shared,
  }) {
    metadataCalls.add({
      'name': name,
      'format': format,
      'assembled': assembled,
      'shared': shared,
    });
  }

  @override
  void toggleEntryShared(int lineIndex) => toggledLines.add(lineIndex);

  @override
  Future<void> chooseFidelity(FidelityMode mode) async {
    fidelityChoices.add(mode);
    state = state.copyWith(needsFidelity: false, fidelityMode: mode);
  }

  @override
  void pickPrinting(int lineIndex, Card printing) =>
      pickedPrintings.add((lineIndex, printing));

  @override
  Future<void> resolveUnowned(UnownedChoice choice) async {
    unownedChoices.add(choice);
    state = state.copyWith(unowned: const []);
  }

  @override
  Future<void> commit() async => commitCalls++;

  @override
  void reset() {
    resetCalls++;
    state = const DeckImportState();
  }
}

Card makeCard({
  String id = 'bolt-m10',
  String name = 'Lightning Bolt',
  String setCode = 'm10',
  String collectorNumber = '146',
  double? priceUsd = 3.0,
}) {
  return Card(
    scryfallId: id,
    oracleId: 'oracle-$id',
    name: name,
    cmc: 1,
    typeLine: 'Instant',
    colorIdentity: 'R',
    setCode: setCode,
    setName: 'Set $setCode',
    collectorNumber: collectorNumber,
    rarity: 'common',
    finishes: 'nonfoil,foil',
    isFullart: false,
    isPromo: false,
    layout: 'normal',
    releasedAt: '2020-01-01',
    priceUsd: priceUsd,
  );
}

RawDeckLine rawLine({
  int lineNumber = 1,
  int quantity = 4,
  String name = 'Lightning Bolt',
  String? setCode,
  String? collectorNumber,
  DeckSection section = DeckSection.main,
}) {
  return RawDeckLine(
    lineNumber: lineNumber,
    quantity: quantity,
    name: name,
    setCode: setCode,
    collectorNumber: collectorNumber,
    section: section,
  );
}

DeckImportState previewState({
  List<DeckImportLine> lines = const [],
  List<DecklistLineError> errors = const [],
  bool needsFidelity = false,
  FidelityMode? fidelityMode,
  List<UnownedShortfall> unowned = const [],
}) {
  return DeckImportState(
    phase: DeckImportPhase.preview,
    sourceText: 'irrelevant',
    lines: lines,
    errors: errors,
    needsFidelity: needsFidelity,
    fidelityMode: fidelityMode,
    unowned: unowned,
  );
}

DeckImportLine resolvedLine({
  RawDeckLine? raw,
  Card? card,
  bool shared = false,
  bool unowned = false,
}) {
  final effectiveRaw = raw ?? rawLine();
  final effectiveCard = card ?? makeCard();
  return DeckImportLine(
    raw: effectiveRaw,
    resolution: ResolvedExact(effectiveCard),
    shared: shared,
    planned: [
      PlannedEntry(
        card: effectiveCard,
        quantity: effectiveRaw.quantity,
        isUnowned: unowned,
      ),
    ],
  );
}

void main() {
  Future<FakeDeckImportNotifier> pumpImport(
    WidgetTester tester, {
    DeckImportState? initialState,
    FakeDeckImportNotifier? notifier,
    Size viewSize = const Size(1400, 900),
  }) async {
    // Desktop-sized by default so the two-pane layout keeps the preview
    // on-screen; mobile-specific tests pass a small size explicitly.
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = notifier ?? FakeDeckImportNotifier(initialState);

    final router = GoRouter(
      initialLocation: '/decks/import',
      routes: [
        GoRoute(
          path: '/decks',
          builder: (_, _) => const Text('Decks List'),
          routes: [
            GoRoute(
              path: 'import',
              builder: (_, _) => const DecklistImportScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  Text('Detail ${state.pathParameters['id']}'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckImportProvider.overrideWith((_) => fake),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: material.ThemeData(
            splashFactory: material.NoSplash.splashFactory,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  group('DecklistImportScreen — input', () {
    testWidgets('renders paste field, metadata fields, and toggles',
        (tester) async {
      await pumpImport(tester);

      expect(find.text('Import deck'), findsOneWidget);
      expect(find.text('4 Lightning Bolt (M10) 146'), findsOneWidget);
      expect(find.text('or import file'), findsOneWidget);
      expect(find.text('Deck name'), findsOneWidget);
      expect(find.text('Format (e.g. modern)'), findsOneWidget);
      expect(find.text('Assembled'), findsOneWidget);
      expect(find.text('Shared'), findsOneWidget);
      expect(find.text('Paste a decklist to see a live preview.'),
          findsOneWidget);

      // Commit disabled while idle.
      final commit = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Commit'),
      );
      expect(commit.onPressed, isNull);
    });

    testWidgets('typing parses after the debounce', (tester) async {
      final notifier = await pumpImport(tester);

      await tester.enterText(
        find.byType(TextField).first,
        '4 Lightning Bolt',
      );
      expect(notifier.parsedTexts, isEmpty);

      await tester.pump(const Duration(milliseconds: 500));
      expect(notifier.parsedTexts, ['4 Lightning Bolt']);
    });

    testWidgets('metadata edits reach the notifier', (tester) async {
      final notifier = await pumpImport(tester);

      await tester.enterText(find.byType(TextField).at(1), 'Burn');
      expect(notifier.metadataCalls.last['name'], 'Burn');

      await tester.enterText(find.byType(TextField).at(2), 'modern');
      expect(notifier.metadataCalls.last['format'], 'modern');

      // Assembled defaults true → tapping sends false.
      await tester.tap(find.byType(Switch).at(0));
      await tester.pump();
      expect(notifier.metadataCalls.last['assembled'], isFalse);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();
      expect(notifier.metadataCalls.last['shared'], isTrue);
    });

    testWidgets('reset clears the flow', (tester) async {
      final notifier = await pumpImport(
        tester,
        initialState: previewState(lines: [resolvedLine()]),
      );

      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(notifier.resetCalls, 1);
    });
  });

  group('DecklistImportScreen — preview', () {
    testWidgets('shows sectioned lines with status and printing',
        (tester) async {
      await pumpImport(
        tester,
        initialState: previewState(
          lines: [
            resolvedLine(),
            DeckImportLine(
              raw: rawLine(
                lineNumber: 2,
                quantity: 2,
                name: 'Duress',
                section: DeckSection.sideboard,
              ),
              resolution: const Unresolved(),
            ),
          ],
          errors: const [DecklistLineError(3, 'Unrecognized line: "???"')],
        ),
      );

      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('SIDEBOARD'), findsOneWidget);
      expect(find.text('Lightning Bolt'), findsOneWidget);
      expect(find.text('4×'), findsOneWidget);
      expect(find.text('(M10) 146'), findsOneWidget);
      expect(find.text('Duress'), findsOneWidget);
      expect(find.text('not found'), findsOneWidget);
      expect(find.text('ERRORS'), findsOneWidget);
      expect(
        find.text('Line 3: Unrecognized line: "???"'),
        findsOneWidget,
      );
      expect(find.text('6 cards · 1 errors'), findsOneWidget);
    });

    testWidgets('unowned lines carry the UNOWNED chip', (tester) async {
      await pumpImport(
        tester,
        initialState: previewState(lines: [resolvedLine(unowned: true)]),
      );

      expect(find.text('UNOWNED'), findsOneWidget);
    });

    testWidgets('per-line shared switch calls toggleEntryShared',
        (tester) async {
      final notifier = await pumpImport(
        tester,
        initialState: previewState(
          lines: [resolvedLine(), resolvedLine(raw: rawLine(lineNumber: 2))],
        ),
      );

      // Line switches come after the two metadata switches.
      await tester.tap(find.byType(Switch).at(3));
      await tester.pump();

      expect(notifier.toggledLines, [1]);
    });

    testWidgets('commit button commits when the state allows it',
        (tester) async {
      final notifier = await pumpImport(
        tester,
        initialState: previewState(lines: [resolvedLine()]),
      );

      await tester.tap(find.text('Commit'));
      await tester.pump();

      expect(notifier.commitCalls, 1);
    });

    testWidgets('done state resets and navigates to the new deck',
        (tester) async {
      final notifier = await pumpImport(
        tester,
        initialState: previewState(lines: [resolvedLine()]),
      );

      notifier.emit(notifier.state.copyWith(
        phase: DeckImportPhase.done,
        createdDeckId: 'new-deck',
      ));
      await tester.pumpAndSettle();

      expect(notifier.resetCalls, 1);
      expect(find.text('Detail new-deck'), findsOneWidget);
    });
  });

  group('DecklistImportScreen — prompts', () {
    testWidgets(
        'fidelity prompt appears as a bottom sheet on mobile and forwards '
        'the choice', (tester) async {
      final notifier = await pumpImport(
        tester,
        viewSize: const Size(500, 800),
        initialState: previewState(
          needsFidelity: true,
          lines: [
            DeckImportLine(
              raw: rawLine(),
              resolution: ResolvedByName([
                makeCard(),
                makeCard(id: 'bolt-2x2', setCode: '2x2', priceUsd: 1.0),
              ]),
            ),
          ],
        ),
      );

      // Shown from the post-frame check (mobile → bottom sheet, no dialog).
      expect(find.text('Choose printings'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(material.Dialog), findsNothing);

      await tester.tap(find.text('Cheapest first'));
      await tester.pumpAndSettle();

      expect(notifier.fidelityChoices, [FidelityMode.cheapestFirst]);
      expect(find.text('Choose printings'), findsNothing);
    });

    testWidgets('manual mode shows Pick buttons that open the picker',
        (tester) async {
      final candidates = [
        makeCard(),
        makeCard(id: 'bolt-2x2', setCode: '2x2', collectorNumber: '117',
            priceUsd: 1.0),
      ];
      final notifier = await pumpImport(
        tester,
        initialState: previewState(
          fidelityMode: FidelityMode.pickManually,
          lines: [
            DeckImportLine(
              raw: rawLine(),
              resolution: ResolvedByName(candidates),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pick a printing — Lightning Bolt'),
        findsOneWidget,
      );

      await tester.tap(find.text('(2X2) 117 — \$1.00'));
      await tester.pumpAndSettle();

      expect(notifier.pickedPrintings, hasLength(1));
      expect(notifier.pickedPrintings.single.$1, 0);
      expect(notifier.pickedPrintings.single.$2.scryfallId, 'bolt-2x2');
    });

    testWidgets('unowned prompt lists shortfalls and forwards the choice',
        (tester) async {
      final notifier = await pumpImport(
        tester,
        initialState: previewState(
          lines: [resolvedLine(unowned: true)],
          unowned: [UnownedShortfall(card: makeCard(), missing: 4)],
        ),
      );

      expect(find.text("Cards you don't own"), findsOneWidget);
      expect(find.text('4× Lightning Bolt'), findsOneWidget);

      await tester.tap(find.text('Import & mark unowned'));
      await tester.pumpAndSettle();

      expect(notifier.unownedChoices, [UnownedChoice.importUnowned]);
    });

    testWidgets('unowned prompt back-out option is forwarded',
        (tester) async {
      final notifier = await pumpImport(
        tester,
        initialState: previewState(
          lines: [resolvedLine(unowned: true)],
          unowned: [UnownedShortfall(card: makeCard(), missing: 4)],
        ),
      );

      await tester.tap(find.text('Back out & edit'));
      await tester.pumpAndSettle();

      expect(notifier.unownedChoices, [UnownedChoice.backOut]);
    });

    testWidgets('prompts render as a dialog on desktop', (tester) async {
      await pumpImport(
        tester,
        initialState: previewState(
          needsFidelity: true,
          lines: [
            DeckImportLine(
              raw: rawLine(),
              resolution: ResolvedByName([makeCard()]),
            ),
          ],
        ),
      );

      expect(find.byType(material.Dialog), findsOneWidget);
      expect(find.text('Choose printings'), findsOneWidget);
    });
  });
}

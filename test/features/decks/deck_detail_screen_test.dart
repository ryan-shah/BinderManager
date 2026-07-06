import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show NoSplash, ThemeData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binder_manager/core/allocation/reservation.dart';
import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/tables/deck_tables.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/decks/deck_repository.dart';
import 'package:binder_manager/features/decks/deck_detail_screen.dart';
import 'package:binder_manager/shared/providers/binder_providers.dart';
import 'package:binder_manager/shared/providers/deck_providers.dart';

import '../../helpers/fake_binder_change_stager.dart';

final _t = DateTime.utc(2026, 7, 1);

/// Records repository calls made by the screen; no database involved.
class FakeDeckRepository implements DeckRepository {
  final deletedDecks = <String>[];
  final sharedCalls = <(String, bool)>[];
  final assembledCalls = <(String, bool)>[];
  final entrySharedCalls = <(String, bool)>[];
  final entryPrintingCalls = <(String, String)>[];

  @override
  Future<String> createDeck({
    required String name,
    String? format,
    required bool isAssembled,
    required bool isShared,
    required List<DeckEntryDraft> entries,
  }) async =>
      'fake-deck-id';

  @override
  Future<void> deleteDeck(String deckId) async => deletedDecks.add(deckId);

  @override
  Future<void> setDeckShared(String deckId, bool shared) async =>
      sharedCalls.add((deckId, shared));

  @override
  Future<void> setDeckAssembled(String deckId, bool assembled) async =>
      assembledCalls.add((deckId, assembled));

  @override
  Future<void> setEntryShared(String entryId, bool shared) async =>
      entrySharedCalls.add((entryId, shared));

  @override
  Future<void> setEntryPrinting(String entryId, String scryfallId) async =>
      entryPrintingCalls.add((entryId, scryfallId));

  @override
  Stream<List<DeckListItem>> watchDecks() => Stream.value(const []);

  @override
  Stream<DeckDetail?> watchDeck(String deckId) => Stream.value(null);
}

Deck makeDeck({
  String id = 'deck-1',
  String name = 'Burn',
  String? format = 'modern',
  bool isAssembled = true,
  bool isShared = false,
}) {
  return Deck(
    id: id,
    name: name,
    format: format,
    isAssembled: isAssembled,
    isShared: isShared,
    createdAt: _t,
    updatedAt: _t,
  );
}

DeckEntryRow makeEntry({
  required String id,
  String deckId = 'deck-1',
  required String scryfallId,
  required String cardName,
  int quantity = 4,
  DeckSection section = DeckSection.main,
  bool isShared = false,
  bool isUnowned = false,
  bool printingSpecified = false,
}) {
  return DeckEntryRow(
    id: id,
    deckId: deckId,
    scryfallId: scryfallId,
    cardName: cardName,
    quantity: quantity,
    section: section,
    isShared: isShared,
    isUnowned: isUnowned,
    printingSpecified: printingSpecified,
    createdAt: _t,
    updatedAt: _t,
  );
}

Card makeCard({
  required String id,
  required String name,
  String setCode = 'm10',
  String collectorNumber = '146',
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
  );
}

void main() {
  late FakeDeckRepository repository;
  late FakeBinderChangeStager stager;

  setUp(() {
    repository = FakeDeckRepository();
    stager = FakeBinderChangeStager();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required DeckDetail? detail,
    ReservationSummary? reservations,
    Map<String, Card> cards = const {},
    List<Card> printings = const [],
  }) async {
    final summary = reservations ??
        ReservationSummary(ownedByPrinting: {}, reservedByPrinting: {});

    final router = GoRouter(
      initialLocation: '/decks/deck-1',
      routes: [
        GoRoute(
          path: '/decks',
          builder: (_, _) => const Text('Decks List'),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  DeckDetailScreen(deckId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckRepositoryProvider.overrideWithValue(repository),
          deckDetailProvider.overrideWith((_, _) => Stream.value(detail)),
          reservationProvider.overrideWith((_) => Stream.value(summary)),
          deckCardsProvider.overrideWith((_, _) async => cards),
          printingsOfOracleProvider.overrideWith((_, _) async => printings),
          binderChangeStagerProvider.overrideWithValue(stager),
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
  }

  group('DeckDetailScreen', () {
    testWidgets('shows "Deck not found" for a missing deck', (tester) async {
      await pumpDetail(tester, detail: null);

      expect(find.text('Deck not found'), findsOneWidget);
    });

    testWidgets('renders header, sections, and entries', (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(
          deck: makeDeck(),
          entries: [
            makeEntry(
              id: 'e1',
              scryfallId: 'bolt-m10',
              cardName: 'Lightning Bolt',
              printingSpecified: true,
            ),
            makeEntry(
              id: 'e2',
              scryfallId: 'duress-xln',
              cardName: 'Duress',
              quantity: 2,
              section: DeckSection.sideboard,
            ),
          ],
        ),
        cards: {
          'bolt-m10': makeCard(id: 'bolt-m10', name: 'Lightning Bolt'),
        },
      );

      expect(find.text('Burn'), findsOneWidget);
      expect(find.text('modern · 6 cards'), findsOneWidget);
      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('SIDEBOARD'), findsOneWidget);
      expect(find.text('Lightning Bolt'), findsOneWidget);
      expect(find.text('Duress'), findsOneWidget);
      expect(find.text('4×'), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      // Printing shown for entries resolvable against the corpus (Duress
      // has no card in the map, so no chip).
      expect(find.text('(M10) 146'), findsOneWidget);
      expect(
        find.text('Cards this deck reserves from your collection: 6'),
        findsOneWidget,
      );
    });

    testWidgets('shows RESERVED tag from the reservation summary',
        (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(
          deck: makeDeck(),
          entries: [
            makeEntry(
              id: 'e1',
              scryfallId: 'bolt-m10',
              cardName: 'Lightning Bolt',
            ),
            makeEntry(
              id: 'e2',
              scryfallId: 'opt-xln',
              cardName: 'Opt',
              section: DeckSection.maybeboard,
            ),
          ],
        ),
        reservations: ReservationSummary(
          ownedByPrinting: {'bolt-m10': 4, 'opt-xln': 4},
          reservedByPrinting: {'bolt-m10': 4, 'opt-xln': 4},
        ),
      );

      // Main entry is reserved; the maybeboard entry never shows the tag.
      expect(find.text('RESERVED'), findsOneWidget);
      expect(find.text('MAYBEBOARD'), findsOneWidget);
    });

    testWidgets('unassembled decks show the no-reservation note',
        (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(
          deck: makeDeck(isAssembled: false),
          entries: [
            makeEntry(
              id: 'e1',
              scryfallId: 'bolt-m10',
              cardName: 'Lightning Bolt',
            ),
          ],
        ),
      );

      expect(
        find.text('Not assembled — this deck reserves nothing.'),
        findsOneWidget,
      );
      expect(find.text('RESERVED'), findsNothing);
    });

    testWidgets('unowned entries collapse into their own section',
        (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(
          deck: makeDeck(),
          entries: [
            makeEntry(
              id: 'e1',
              scryfallId: 'bolt-m10',
              cardName: 'Lightning Bolt',
            ),
            makeEntry(
              id: 'e2',
              scryfallId: 'opt-xln',
              cardName: 'Opt',
              quantity: 3,
              isUnowned: true,
            ),
          ],
        ),
      );

      expect(find.text('UNOWNED (3)'), findsOneWidget);
      // Collapsed by default.
      expect(find.text('Opt'), findsNothing);

      await tester.tap(find.text('UNOWNED (3)'));
      await tester.pumpAndSettle();
      expect(find.text('Opt'), findsOneWidget);
    });

    testWidgets('toggles call the repository', (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(
          deck: makeDeck(),
          entries: [
            makeEntry(
              id: 'e1',
              scryfallId: 'bolt-m10',
              cardName: 'Lightning Bolt',
            ),
          ],
        ),
      );

      // Deck-level toggles: Assembled (on → off), Shared (off → on).
      final switches = find.byType(Switch);
      await tester.tap(switches.at(0));
      await tester.pump();
      expect(repository.assembledCalls, [('deck-1', false)]);

      await tester.tap(switches.at(1));
      await tester.pump();
      expect(repository.sharedCalls, [('deck-1', true)]);

      // Entry-level shared switch.
      await tester.tap(switches.at(2));
      await tester.pump();
      expect(repository.entrySharedCalls, [('e1', true)]);
    });

    testWidgets('delete confirms, deletes, and navigates back',
        (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(deck: makeDeck(), entries: const []),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete deck?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repository.deletedDecks, ['deck-1']);
      expect(find.text('Decks List'), findsOneWidget);
    });

    testWidgets('delete can be cancelled', (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(deck: makeDeck(), entries: const []),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.deletedDecks, isEmpty);
      expect(find.text('Burn'), findsOneWidget);
    });

    testWidgets('back button returns to the decks list', (tester) async {
      await pumpDetail(
        tester,
        detail: DeckDetail(deck: makeDeck(), entries: const []),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Decks List'), findsOneWidget);
    });
  });

  group('printing editor (D13 correction path)', () {
    final detail = DeckDetail(
      deck: makeDeck(),
      entries: [
        makeEntry(
          id: 'e1',
          scryfallId: 'bolt-m10',
          cardName: 'Lightning Bolt',
        ),
      ],
    );
    final printings = [
      makeCard(id: 'bolt-lea', name: 'Lightning Bolt', setCode: 'lea',
          collectorNumber: '161'),
      makeCard(id: 'bolt-m10', name: 'Lightning Bolt'),
    ];

    testWidgets('picker lists printings and re-points the entry',
        (tester) async {
      await pumpDetail(
        tester,
        detail: detail,
        cards: {'bolt-m10': makeCard(id: 'bolt-m10', name: 'Lightning Bolt')},
        printings: printings,
        reservations: ReservationSummary(
          ownedByPrinting: {'bolt-lea': 2},
          reservedByPrinting: {},
        ),
      );

      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      expect(find.text('Printing — Lightning Bolt'), findsOneWidget);
      expect(find.text('(LEA) 161 — Set lea'), findsOneWidget);
      expect(find.text('(M10) 146 — Set m10'), findsOneWidget);
      // Current printing is marked; owned count shows on the LEA option.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.textContaining('2 owned'), findsOneWidget);

      await tester.tap(find.text('(LEA) 161 — Set lea'));
      await tester.pumpAndSettle();

      expect(repository.entryPrintingCalls, [('e1', 'bolt-lea')]);
      expect(find.text('Printing — Lightning Bolt'), findsNothing);
    });

    testWidgets('choosing the current printing is a no-op', (tester) async {
      await pumpDetail(
        tester,
        detail: detail,
        cards: {'bolt-m10': makeCard(id: 'bolt-m10', name: 'Lightning Bolt')},
        printings: printings,
      );

      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('(M10) 146 — Set m10'));
      await tester.pumpAndSettle();

      expect(repository.entryPrintingCalls, isEmpty);
    });

    testWidgets('cancel leaves the entry unchanged', (tester) async {
      await pumpDetail(
        tester,
        detail: detail,
        cards: {'bolt-m10': makeCard(id: 'bolt-m10', name: 'Lightning Bolt')},
        printings: printings,
      );

      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.entryPrintingCalls, isEmpty);
    });

    testWidgets('no edit affordance when the printing is not in the corpus',
        (tester) async {
      await pumpDetail(tester, detail: detail);

      // Unresolvable entry: no chip, and the picker cannot open.
      expect(find.byIcon(Icons.swap_horiz), findsNothing);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/allocation/allocator.dart';
import 'package:binder_manager/core/allocation/reservation.dart';
import 'package:binder_manager/core/database/corpus_database.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/core/models/binder_position.dart';
import 'package:binder_manager/core/models/card_identity.dart';
import 'package:binder_manager/core/models/ordering.dart';

final _t = DateTime.utc(2026, 7, 1);
var _idCounter = 0;

Card card(
  String id, {
  String? name,
  String typeLine = 'Creature — Test',
  String colorIdentity = '',
  String setCode = 'tst',
  String collectorNumber = '1',
  String rarity = 'common',
  double? priceUsd,
  double? priceUsdFoil,
  double? priceUsdEtched,
}) {
  return Card(
    scryfallId: id,
    oracleId: 'oracle-$id',
    name: name ?? id,
    cmc: 1,
    typeLine: typeLine,
    colorIdentity: colorIdentity,
    setCode: setCode,
    setName: setCode.toUpperCase(),
    collectorNumber: collectorNumber,
    rarity: rarity,
    finishes: 'nonfoil,foil,etched',
    priceUsd: priceUsd,
    priceUsdFoil: priceUsdFoil,
    priceUsdEtched: priceUsdEtched,
    isFullart: false,
    isPromo: false,
    layout: 'normal',
    releasedAt: '2020-01-01',
  );
}

BinderSlotRow slot(
  String binderId,
  String scryfallId, {
  Finish finish = Finish.nonfoil,
  int quantity = 1,
  int page = 1,
  PageSide side = PageSide.front,
  int pocket = 1,
  bool isPinned = false,
}) {
  return BinderSlotRow(
    id: 'slot-${_idCounter++}',
    binderId: binderId,
    scryfallId: scryfallId,
    finish: finish,
    quantity: quantity,
    page: page,
    side: side,
    pocket: pocket,
    isPinned: isPinned,
    createdAt: _t,
    updatedAt: _t,
  );
}

/// A pool where everything owned is idle.
StackIdleSummary pool(Map<CardIdentity, int> idle) =>
    StackIdleSummary(ownedByStack: idle, idleByStack: idle);

/// 1-row × [pockets]-column, single page, single-sided: ordinal k =
/// page 1, front, pocket k+1.
BinderGeometry rowGeometry(int pockets) => BinderGeometry(
      rows: 1,
      cols: pockets,
      pageCount: 1,
      doubleSided: false,
    );

BinderPosition frontPocket(int pocket, {int page = 1}) =>
    BinderPosition(page: page, side: PageSide.front, pocket: pocket);

const nf = Finish.nonfoil;
const foil = Finish.foil;

CardIdentity idNf(String id) => CardIdentity(id, nf);

PlannedPlacement placementOf(BinderAllocation allocation, CardIdentity id) =>
    allocation.placements.singleWhere((p) => p.identity == id);

void main() {
  group('cardTypeBucketOf', () {
    test('buckets plain types', () {
      expect(cardTypeBucketOf('Instant'), CardTypeBucket.instant);
      expect(cardTypeBucketOf('Sorcery'), CardTypeBucket.sorcery);
      expect(cardTypeBucketOf('Battle — Siege'), CardTypeBucket.battle);
      expect(cardTypeBucketOf('Land — Island'), CardTypeBucket.land);
      expect(
        cardTypeBucketOf('Legendary Planeswalker — Jace'),
        CardTypeBucket.planeswalker,
      );
    });

    test('first match wins: Artifact Creature is a creature', () {
      expect(
        cardTypeBucketOf('Artifact Creature — Golem'),
        CardTypeBucket.creature,
      );
    });

    test('first match wins: Artifact Land is an artifact', () {
      expect(cardTypeBucketOf('Artifact Land'), CardTypeBucket.artifact);
    });

    test('subtypes never match', () {
      // "Dryad of the Ilysian Grove" style: Land appears only as subtype.
      expect(
        cardTypeBucketOf('Enchantment Creature — Nymph'),
        CardTypeBucket.creature,
      );
      // Sub-portion "Equipment" does not contain a card type.
      expect(cardTypeBucketOf('Artifact — Equipment'), CardTypeBucket.artifact);
    });

    test('DFC faces both count', () {
      expect(
        cardTypeBucketOf('Sorcery // Land — Mountain'),
        CardTypeBucket.sorcery,
      );
    });

    test('unknown type lines fall into other', () {
      expect(cardTypeBucketOf('Conspiracy'), CardTypeBucket.other);
      expect(cardTypeBucketOf(''), CardTypeBucket.other);
    });
  });

  group('colorGroupIndexOf', () {
    test('single colors in WUBRG order', () {
      expect(colorGroupIndexOf('W'), 0);
      expect(colorGroupIndexOf('U'), 1);
      expect(colorGroupIndexOf('B'), 2);
      expect(colorGroupIndexOf('R'), 3);
      expect(colorGroupIndexOf('G'), 4);
    });

    test('multicolor then colorless', () {
      expect(colorGroupIndexOf('W,U'), 5);
      expect(colorGroupIndexOf('B,R,G'), 5);
      expect(colorGroupIndexOf(''), 6);
    });
  });

  group('priority walk (D6)', () {
    test('higher-priority binder claims the stack; lower sees nothing', () {
      final bolt = card('bolt', priceUsd: 2);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [bolt],
          ),
          BinderAllocationRequest(
            binderId: 'b',
            geometry: rowGeometry(9),
            matches: [bolt],
          ),
        ],
        idle: pool({idNf('bolt'): 4}),
      );

      final a = result.forBinder('a')!;
      final b = result.forBinder('b')!;
      expect(a.placements, hasLength(1));
      expect(a.placements.single.identity, idNf('bolt'));
      expect(b.placements, isEmpty);
      expect(b.overflow, isEmpty);
      expect(b.matchCount, 0);
    });

    test('stacks are atomic: all copies in one pocket, quantity preserved',
        () {
      final bolt = card('bolt');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [bolt],
          ),
        ],
        idle: pool({idNf('bolt'): 4}),
      );

      final placement = result.forBinder('a')!.placements.single;
      expect(placement.quantity, 4);
      expect(placement.position, frontPocket(1));
    });

    test('different finishes of one printing may split across binders', () {
      final bolt = card('bolt', priceUsd: 1, priceUsdFoil: 20);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(1),
            matches: [bolt],
          ),
          BinderAllocationRequest(
            binderId: 'b',
            geometry: rowGeometry(9),
            matches: [bolt],
          ),
        ],
        idle: pool({idNf('bolt'): 2, const CardIdentity('bolt', foil): 1}),
      );

      // A (price desc, capacity 1) takes the foil; the nonfoil overflows A
      // but is NOT consumed — it lands in B.
      final a = result.forBinder('a')!;
      expect(a.placements.single.identity, const CardIdentity('bolt', foil));
      expect(a.overflow.single.identity, idNf('bolt'));

      final b = result.forBinder('b')!;
      expect(b.placements.single.identity, idNf('bolt'));
      expect(b.placements.single.quantity, 2);
    });

    test('virtual binders do not consume', () {
      final bolt = card('bolt');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'virtual',
            geometry: rowGeometry(9),
            matches: [bolt],
            isVirtual: true,
          ),
          BinderAllocationRequest(
            binderId: 'real',
            geometry: rowGeometry(9),
            matches: [bolt],
          ),
        ],
        idle: pool({idNf('bolt'): 2}),
      );

      expect(result.forBinder('virtual')!.placements, hasLength(1));
      expect(result.forBinder('real')!.placements, hasLength(1));
    });

    test('virtual binders see the full pool past earlier consumption', () {
      final bolt = card('bolt');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'real',
            geometry: rowGeometry(9),
            matches: [bolt],
          ),
          BinderAllocationRequest(
            binderId: 'virtual',
            geometry: rowGeometry(9),
            matches: [bolt],
            isVirtual: true,
          ),
        ],
        idle: pool({idNf('bolt'): 2}),
      );

      expect(result.forBinder('real')!.placements, hasLength(1));
      expect(result.forBinder('virtual')!.placements, hasLength(1));
    });
  });

  group('capacity and overflow (D6)', () {
    test('keeps top-ranked by sort; overflow ranked by the same sort', () {
      final cards = [
        card('cheap', priceUsd: 1),
        card('mid', priceUsd: 3),
        card('dear', priceUsd: 5),
        card('dirt', priceUsd: 0.5),
      ];
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(2),
            matches: cards,
          ),
        ],
        idle: pool({for (final c in cards) idNf(c.scryfallId): 1}),
      );

      final a = result.forBinder('a')!;
      expect(
        a.placements.map((p) => p.identity.scryfallId),
        ['dear', 'mid'],
      );
      expect(
        a.overflow.map((o) => o.identity.scryfallId),
        ['cheap', 'dirt'],
      );
      expect(a.matchCount, 4);
    });

    test('sort direction asc flips ranking', () {
      final cards = [
        card('cheap', priceUsd: 1),
        card('dear', priceUsd: 5),
      ];
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(1),
            sortDir: SortDirection.asc,
            matches: cards,
          ),
        ],
        idle: pool({idNf('cheap'): 1, idNf('dear'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(a.placements.single.identity.scryfallId, 'cheap');
      expect(a.overflow.single.identity.scryfallId, 'dear');
    });

    test('equal sort keys tie-break on (scryfallId, finish)', () {
      final cards = [
        card('b-card', priceUsd: 2, priceUsdFoil: 2),
        card('a-card', priceUsd: 2),
      ];
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: cards,
          ),
        ],
        idle: pool({
          idNf('a-card'): 1,
          idNf('b-card'): 1,
          const CardIdentity('b-card', foil): 1,
        }),
      );

      expect(
        result.forBinder('a')!.placements.map(
              (p) => '${p.identity.scryfallId}/${p.identity.finish.name}',
            ),
        ['a-card/nonfoil', 'b-card/nonfoil', 'b-card/foil'],
      );
    });

    test('capacity 0 overflows everything', () {
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: const BinderGeometry(
              rows: 3,
              cols: 3,
              pageCount: 0,
              doubleSided: true,
            ),
            matches: [card('bolt')],
          ),
        ],
        idle: pool({idNf('bolt'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(a.placements, isEmpty);
      expect(a.overflow, hasLength(1));
    });

    test('duplicate match rows are deduped', () {
      final bolt = card('bolt');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [bolt, bolt],
          ),
        ],
        idle: pool({idNf('bolt'): 1}),
      );

      expect(result.forBinder('a')!.placements, hasLength(1));
    });

    test('cards without idle stacks are invisible', () {
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [card('bolt'), card('opt')],
          ),
        ],
        idle: pool({idNf('opt'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(a.placements.single.identity, idNf('opt'));
      expect(a.matchCount, 1);
    });

    test('empty inputs produce empty results', () {
      expect(allocate(binders: const [], idle: pool({})).allocations, isEmpty);

      final result = allocate(
        binders: [
          BinderAllocationRequest(binderId: 'a', geometry: rowGeometry(9)),
        ],
        idle: pool({}),
      );
      expect(result.forBinder('a')!.placements, isEmpty);
      expect(result.forBinder('a')!.overflow, isEmpty);
    });
  });

  group('group + sort (D6)', () {
    test('card-type groups appear in canonical order', () {
      final cards = [
        card('swamp', typeLine: 'Basic Land — Swamp'),
        card('opt', typeLine: 'Instant'),
        card('bear', typeLine: 'Creature — Bear'),
      ];
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            groupBy: BinderAxis.cardType,
            sortBy: BinderAxis.name,
            sortDir: SortDirection.asc,
            matches: cards,
          ),
        ],
        idle: pool({for (final c in cards) idNf(c.scryfallId): 1}),
      );

      expect(
        result.forBinder('a')!.placements.map((p) => p.identity.scryfallId),
        ['bear', 'opt', 'swamp'],
      );
    });

    test('sort orders within the group; groups stay canonical', () {
      final cards = [
        card('w-cheap', colorIdentity: 'W', priceUsd: 1),
        card('w-dear', colorIdentity: 'W', priceUsd: 9),
        card('gold', colorIdentity: 'U,R', priceUsd: 99),
        card('wastes', colorIdentity: '', priceUsd: 50),
      ];
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            groupBy: BinderAxis.color,
            matches: cards,
          ),
        ],
        idle: pool({for (final c in cards) idNf(c.scryfallId): 1}),
      );

      // W group first (price desc within), then multicolor, then colorless —
      // canonical group order is independent of sortDir.
      expect(
        result.forBinder('a')!.placements.map((p) => p.identity.scryfallId),
        ['w-dear', 'w-cheap', 'gold', 'wastes'],
      );
    });

    test('finish groups follow enum order with finish-specific prices', () {
      final bolt = card('bolt', priceUsd: 1, priceUsdFoil: 20);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            groupBy: BinderAxis.finish,
            matches: [bolt],
          ),
        ],
        idle: pool({idNf('bolt'): 2, const CardIdentity('bolt', foil): 1}),
      );

      expect(
        result.forBinder('a')!.placements.map((p) => p.identity.finish),
        [nf, foil],
      );
    });

    test('rarity groups rank mythic first', () {
      final cards = [
        card('pauper', rarity: 'common', name: 'AAA'),
        card('chase', rarity: 'mythic', name: 'ZZZ'),
      ];
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            groupBy: BinderAxis.rarity,
            sortBy: BinderAxis.name,
            sortDir: SortDirection.asc,
            matches: cards,
          ),
        ],
        idle: pool({for (final c in cards) idNf(c.scryfallId): 1}),
      );

      expect(
        result.forBinder('a')!.placements.map((p) => p.identity.scryfallId),
        ['chase', 'pauper'],
      );
    });
  });

  group('position assignment: fill order (D9)', () {
    test('fills page by page, front then back', () {
      final cards = [
        for (var i = 0; i < 5; i++)
          card('c$i', name: 'C$i', priceUsd: 10.0 - i),
      ];
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: const BinderGeometry(
              rows: 1,
              cols: 2,
              pageCount: 2,
              doubleSided: true,
            ),
            matches: cards,
          ),
        ],
        idle: pool({for (final c in cards) idNf(c.scryfallId): 1}),
      );

      expect(result.forBinder('a')!.placements.map((p) => p.position), [
        frontPocket(1),
        frontPocket(2),
        const BinderPosition(page: 1, side: PageSide.back, pocket: 1),
        const BinderPosition(page: 1, side: PageSide.back, pocket: 2),
        frontPocket(1, page: 2),
      ]);
    });
  });

  group('append-within-group (D7 default)', () {
    test('retained committed stacks keep their exact positions', () {
      final bolt = card('bolt', priceUsd: 1);
      final opt = card('opt', priceUsd: 50);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [bolt, opt],
            committedSlots: [slot('a', 'bolt', pocket: 3)],
          ),
        ],
        idle: pool({idNf('bolt'): 1, idNf('opt'): 1}),
      );

      final a = result.forBinder('a')!;
      // Bolt keeps pocket 3 even though opt outranks it; opt appends after
      // the group's last occupied pocket.
      expect(placementOf(a, idNf('bolt')).position, frontPocket(3));
      expect(placementOf(a, idNf('opt')).position, frontPocket(4));
    });

    test('removed stacks leave holes; append does not backfill them', () {
      final keepA = card('keep-a');
      final keepB = card('keep-b');
      final newcomer = card('newcomer');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [keepA, keepB, newcomer],
            committedSlots: [
              slot('a', 'keep-a', pocket: 1),
              slot('a', 'gone', pocket: 2),
              slot('a', 'keep-b', pocket: 3),
            ],
          ),
        ],
        idle: pool({idNf('keep-a'): 1, idNf('keep-b'): 1, idNf('newcomer'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(placementOf(a, idNf('keep-a')).position, frontPocket(1));
      expect(placementOf(a, idNf('keep-b')).position, frontPocket(3));
      // Newcomer appends after pocket 3 — the hole at pocket 2 stays.
      expect(placementOf(a, idNf('newcomer')).position, frontPocket(4));
      expect(a.placements.map((p) => p.identity.scryfallId),
          isNot(contains('gone')));
    });

    test('newcomers append after their own group; groups without committed '
        'members start after earlier groups', () {
      final committedCreature = card('bear', typeLine: 'Creature — Bear');
      final newCreature = card('wolf', typeLine: 'Creature — Wolf');
      final newSorcery = card('bolt', typeLine: 'Sorcery');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            groupBy: BinderAxis.cardType,
            sortBy: BinderAxis.name,
            sortDir: SortDirection.asc,
            matches: [committedCreature, newCreature, newSorcery],
            committedSlots: [slot('a', 'bear', pocket: 2)],
          ),
        ],
        idle: pool({idNf('bear'): 1, idNf('wolf'): 1, idNf('bolt'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(placementOf(a, idNf('bear')).position, frontPocket(2));
      // Creature newcomer: after the creature group's last pocket (2) → 3.
      expect(placementOf(a, idNf('wolf')).position, frontPocket(3));
      // Sorcery group has no committed members: starts after the last
      // pocket placed by earlier groups (3) → 4. Pocket 1 stays free.
      expect(placementOf(a, idNf('bolt')).position, frontPocket(4));
    });

    test('wraps to the earliest free pocket when the tail is full', () {
      final committed = card('anchor');
      final newcomer = card('late');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(4),
            matches: [committed, newcomer],
            committedSlots: [slot('a', 'anchor', pocket: 4)],
          ),
        ],
        idle: pool({idNf('anchor'): 1, idNf('late'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(placementOf(a, idNf('anchor')).position, frontPocket(4));
      expect(placementOf(a, idNf('late')).position, frontPocket(1));
    });

    test('a committed position outside the shrunken geometry is re-placed',
        () {
      final bolt = card('bolt');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(4),
            matches: [bolt],
            // Committed on page 9 — the binder now has one page.
            committedSlots: [slot('a', 'bolt', page: 9, pocket: 1)],
          ),
        ],
        idle: pool({idNf('bolt'): 1}),
      );

      expect(
        result.forBinder('a')!.placements.single.position,
        frontPocket(1),
      );
    });

    test('non-pinned committed stacks can be evicted by rank', () {
      final committed = card('old', priceUsd: 1);
      final better = card('new', priceUsd: 10);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(1),
            matches: [committed, better],
            committedSlots: [slot('a', 'old', pocket: 1)],
          ),
        ],
        idle: pool({idNf('old'): 1, idNf('new'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(a.placements.single.identity, idNf('new'));
      expect(a.overflow.single.identity, idNf('old'));
    });

    test('retained quantity reflects the current pool, not the committed row',
        () {
      final bolt = card('bolt');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [bolt],
            committedSlots: [slot('a', 'bolt', quantity: 4, pocket: 1)],
          ),
        ],
        // Two copies were reserved by a deck since the commit.
        idle: pool({idNf('bolt'): 2}),
      );

      final placement = result.forBinder('a')!.placements.single;
      expect(placement.quantity, 2);
      expect(placement.position, frontPocket(1));
    });

    test('duplicate committed rows for one identity: first in fill order wins',
        () {
      final bolt = card('bolt');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [bolt],
            committedSlots: [
              slot('a', 'bolt', pocket: 5),
              slot('a', 'bolt', pocket: 2),
            ],
          ),
        ],
        idle: pool({idNf('bolt'): 1}),
      );

      expect(
        result.forBinder('a')!.placements.single.position,
        frontPocket(2),
      );
    });
  });

  group('pinning (D7)', () {
    test('a pinned stack has a guaranteed seat even when outranked', () {
      final pinned = card('pet', priceUsd: 1);
      final better = card('chase', priceUsd: 100);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(1),
            matches: [pinned, better],
            committedSlots: [slot('a', 'pet', pocket: 1, isPinned: true)],
          ),
        ],
        idle: pool({idNf('pet'): 1, idNf('chase'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(a.placements.single.identity, idNf('pet'));
      expect(a.placements.single.position, frontPocket(1));
      expect(a.overflow.single.identity, idNf('chase'));
    });

    test('a pinned stack that no longer matches is dropped', () {
      final other = card('other');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [other],
            committedSlots: [slot('a', 'pet', pocket: 1, isPinned: true)],
          ),
        ],
        idle: pool({idNf('other'): 1, idNf('pet'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(a.placements.map((p) => p.identity.scryfallId), ['other']);
      // The freed pocket is reusable.
      expect(a.placements.single.position, frontPocket(1));
    });

    test('a pinned stack with no idle copies is dropped', () {
      final pet = card('pet');
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [pet],
            committedSlots: [slot('a', 'pet', pocket: 1, isPinned: true)],
          ),
        ],
        idle: pool({}),
      );

      expect(result.forBinder('a')!.placements, isEmpty);
    });
  });

  group('reflow (D7 opt-in)', () {
    test('recomputes perfect group+sort order from pocket 1', () {
      final cheap = card('cheap', priceUsd: 1);
      final dear = card('dear', priceUsd: 10);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [cheap, dear],
            committedSlots: [
              slot('a', 'cheap', pocket: 2),
              slot('a', 'dear', pocket: 7),
            ],
            reflow: true,
          ),
        ],
        idle: pool({idNf('cheap'): 1, idNf('dear'): 1}),
      );

      final a = result.forBinder('a')!;
      expect(placementOf(a, idNf('dear')).position, frontPocket(1));
      expect(placementOf(a, idNf('cheap')).position, frontPocket(2));
    });

    test('a pinned card survives a reflow at its exact position', () {
      final pinned = card('pet', priceUsd: 1);
      final dear = card('dear', priceUsd: 10);
      final mid = card('mid', priceUsd: 5);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            matches: [pinned, dear, mid],
            committedSlots: [
              slot('a', 'pet', pocket: 2, isPinned: true),
              slot('a', 'dear', pocket: 8),
            ],
            reflow: true,
          ),
        ],
        idle: pool({idNf('pet'): 1, idNf('dear'): 1, idNf('mid'): 1}),
      );

      final a = result.forBinder('a')!;
      // Pinned keeps pocket 2 exactly; the rest flow around it in perfect
      // sort order: dear → 1, mid → 3 (skipping the pinned pocket).
      expect(placementOf(a, idNf('pet')).position, frontPocket(2));
      expect(placementOf(a, idNf('dear')).position, frontPocket(1));
      expect(placementOf(a, idNf('mid')).position, frontPocket(3));
    });

    test('reflow respects grouping sections around pins', () {
      final pinnedLand = card('mesa', typeLine: 'Land — Plains', priceUsd: 20);
      final bear = card('bear', typeLine: 'Creature — Bear', priceUsd: 3);
      final bolt = card('bolt', typeLine: 'Instant', priceUsd: 2);
      final result = allocate(
        binders: [
          BinderAllocationRequest(
            binderId: 'a',
            geometry: rowGeometry(9),
            groupBy: BinderAxis.cardType,
            matches: [pinnedLand, bear, bolt],
            committedSlots: [slot('a', 'mesa', pocket: 1, isPinned: true)],
            reflow: true,
          ),
        ],
        idle: pool({idNf('mesa'): 1, idNf('bear'): 1, idNf('bolt'): 1}),
      );

      final a = result.forBinder('a')!;
      // Pinned land holds pocket 1; creature then instant flow into the
      // next free pockets in canonical group order.
      expect(placementOf(a, idNf('mesa')).position, frontPocket(1));
      expect(placementOf(a, idNf('bear')).position, frontPocket(2));
      expect(placementOf(a, idNf('bolt')).position, frontPocket(3));
    });
  });
}

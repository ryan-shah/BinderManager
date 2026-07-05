import 'package:flutter_test/flutter_test.dart';

import 'package:binder_manager/core/allocation/reservation.dart';
import 'package:binder_manager/core/database/user_database.dart';
import 'package:binder_manager/core/models/card_identity.dart';

final _t = DateTime.utc(2026, 7, 1);
var _idCounter = 0;

StackRow stack(
  String scryfallId,
  int quantity, {
  Finish finish = Finish.nonfoil,
  String provenance = 'manabox',
}) {
  return StackRow(
    id: 's${_idCounter++}',
    scryfallId: scryfallId,
    finish: finish,
    quantity: quantity,
    provenance: provenance,
    createdAt: _t,
    updatedAt: _t,
  );
}

ReservationSummary reservations(
  Map<String, int> owned,
  Map<String, int> reserved,
) {
  return ReservationSummary(
    ownedByPrinting: owned,
    reservedByPrinting: reserved,
  );
}

/// Price lookup over a (scryfallId, finish) → price map; missing = null.
double? Function(CardIdentity) prices(Map<CardIdentity, double> table) =>
    (identity) => table[identity];

const bolt = 'bolt';
const boltNonfoil = CardIdentity(bolt, Finish.nonfoil);
const boltFoil = CardIdentity(bolt, Finish.foil);
const boltEtched = CardIdentity(bolt, Finish.etched);

void main() {
  group('computeStackIdle', () {
    test(
        'D13 acceptance: 2x nonfoil (cheap) + 1x foil (valuable), reserve 2 '
        '→ nonfoils consumed, foil idle', () {
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 2, finish: Finish.nonfoil),
          stack(bolt, 1, finish: Finish.foil),
        ],
        reservations: reservations({bolt: 3}, {bolt: 2}),
        priceOf: prices({boltNonfoil: 1, boltFoil: 20}),
      );

      expect(summary.idleOf(boltNonfoil), 0);
      expect(summary.idleOf(boltFoil), 1);
      expect(summary.idleStacks, {boltFoil});
    });

    test('merges stacks of the same (printing, finish) across provenances',
        () {
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 1, provenance: 'manabox'),
          stack(bolt, 2, provenance: 'deck-import'),
        ],
        reservations: reservations({bolt: 3}, {}),
        priceOf: prices({boltNonfoil: 1}),
      );

      expect(summary.ownedOf(boltNonfoil), 3);
      expect(summary.idleOf(boltNonfoil), 3);
    });

    test('reservation spills into the next-cheapest finish', () {
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 2, finish: Finish.nonfoil),
          stack(bolt, 2, finish: Finish.foil),
          stack(bolt, 2, finish: Finish.etched),
        ],
        reservations: reservations({bolt: 6}, {bolt: 3}),
        priceOf: prices({boltNonfoil: 1, boltFoil: 5, boltEtched: 40}),
      );

      expect(summary.idleOf(boltNonfoil), 0);
      expect(summary.idleOf(boltFoil), 1);
      expect(summary.idleOf(boltEtched), 2);
    });

    test('null price counts as 0 — consumed before priced finishes', () {
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 1, finish: Finish.foil),
          stack(bolt, 1, finish: Finish.nonfoil),
        ],
        reservations: reservations({bolt: 2}, {bolt: 1}),
        // Nonfoil has no price → treated as 0 → cheapest.
        priceOf: prices({boltFoil: 5}),
      );

      expect(summary.idleOf(boltNonfoil), 0);
      expect(summary.idleOf(boltFoil), 1);
    });

    test('equal prices tie-break in Finish enum order', () {
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 1, finish: Finish.etched),
          stack(bolt, 1, finish: Finish.foil),
          stack(bolt, 1, finish: Finish.nonfoil),
        ],
        reservations: reservations({bolt: 3}, {bolt: 2}),
        priceOf: prices({boltNonfoil: 2, boltFoil: 2, boltEtched: 2}),
      );

      // nonfoil then foil consumed; etched (last in enum order) stays idle.
      expect(summary.idleOf(boltNonfoil), 0);
      expect(summary.idleOf(boltFoil), 0);
      expect(summary.idleOf(boltEtched), 1);
    });

    test('over-reservation clamps per printing — idle never negative', () {
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 1, finish: Finish.nonfoil),
          stack(bolt, 1, finish: Finish.foil),
        ],
        reservations: reservations({bolt: 2}, {bolt: 9}),
        priceOf: prices({boltNonfoil: 1, boltFoil: 20}),
      );

      expect(summary.idleOf(boltNonfoil), 0);
      expect(summary.idleOf(boltFoil), 0);
      expect(summary.idleStacks, isEmpty);
    });

    test('unreserved printings are fully idle', () {
      final summary = computeStackIdle(
        stacks: [stack(bolt, 4)],
        reservations: reservations({bolt: 4}, {}),
        priceOf: prices({}),
      );

      expect(summary.idleOf(boltNonfoil), 4);
    });

    test('reserved but unowned printings are ignored', () {
      final summary = computeStackIdle(
        stacks: [],
        reservations: reservations({}, {'ghost': 4}),
        priceOf: prices({}),
      );

      expect(summary.ownedByStack, isEmpty);
      expect(summary.idleByStack, isEmpty);
      expect(summary.idleOf(const CardIdentity('ghost', Finish.nonfoil)), 0);
    });

    test('printings distribute independently', () {
      const optNonfoil = CardIdentity('opt', Finish.nonfoil);
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 2, finish: Finish.nonfoil),
          stack(bolt, 1, finish: Finish.foil),
          stack('opt', 3, finish: Finish.nonfoil),
        ],
        reservations: reservations({bolt: 3, 'opt': 3}, {bolt: 2, 'opt': 1}),
        priceOf: prices({boltNonfoil: 1, boltFoil: 20, optNonfoil: 0.1}),
      );

      expect(summary.idleOf(boltNonfoil), 0);
      expect(summary.idleOf(boltFoil), 1);
      expect(summary.idleOf(optNonfoil), 2);
    });

    test('per-stack idle sums to the printing-level idle', () {
      final printingLevel = reservations({bolt: 6}, {bolt: 4});
      final summary = computeStackIdle(
        stacks: [
          stack(bolt, 2, finish: Finish.nonfoil),
          stack(bolt, 2, finish: Finish.foil),
          stack(bolt, 2, finish: Finish.etched),
        ],
        reservations: printingLevel,
        priceOf: prices({boltNonfoil: 1, boltFoil: 5, boltEtched: 40}),
      );

      final perStackSum = summary.idleOf(boltNonfoil) +
          summary.idleOf(boltFoil) +
          summary.idleOf(boltEtched);
      expect(perStackSum, printingLevel.idleOf(bolt));
    });
  });
}
